`include "image.sv"

module top
  (input logic        CLOCK_50,
   input logic [3:0]  KEY,
   inout tri   [35:0] GPIO);
    
  //meta stable
  logic [3:0] keyA, keyB; //use keyB for later key inputs
  genvar i;
  generate
    for (i = 0; i < 4; i++) begin : metaStable
      dFlipFlop A (.q(keyA[i]), .d(KEY[i]), .clock(CLOCK_50));
      dFlipFlop B (.q(keyB[i]), .d(keyA[i]), .clock(CLOCK_50));
    end
  endgenerate
  
  //anti-twice while long pressing keys
  logic take_photo, move1, move2;
  enum logic [1:0] {WAIT = 2'd0, PRESS1 = 2'd1, 
                    PRESS2 = 2'd2, PRESS3 = 2'd3} state, nextState;

  always_ff @(posedge CLOCK_50, posedge keyB[0]) begin 
    if (keyB[0])
      state <= WAIT;
    else
      state <= nextState;
  end
  
  always_comb begin  //output logic
    unique case (state)
      WAIT: begin
        take_photo = 1'b0;
        move1 = 1'b0;
        move2 = 1'b0;
      end
      PRESS1: begin 
        take_photo = ~keyB[1];
        move1 = 1'b0;
        move2 = 1'b0;
      end
      PRESS2: begin 
        take_photo = 1'b0;
        move1 = ~keyB[2];
        move2 = 1'b0;
      end
      PRESS3: begin 
        take_photo = 1'b0;
        move1 = 1'b0;
        move2 = ~keyB[3];
      end
      default: begin 
        take_photo = 1'b0;
        move1 = 1'b0;
        move2 = 1'b0;
      end
    endcase
  end

  always_comb begin  // nextState logic
    unique case (state)
      WAIT: nextState = keyB[1] ? PRESS1 : (keyB[2] ? PRESS2 : 
                        (keyB[3] ? PRESS3 : WAIT));
      PRESS1: nextState = keyB[1] ? PRESS1 : WAIT;
      PRESS2: nextState = keyB[2] ? PRESS2 : WAIT;
      PRESS3: nextState = keyB[3] ? PRESS3 : WAIT;
      default: nextState = keyB[1] ? PRESS1 : (keyB[2] ? PRESS2 : 
                        (keyB[3] ? PRESS3 : WAIT));
    endcase
  end 

  //INSTANTIATE EVERYTYING
  logic                       done_init, done_take, done_send;
  logic                       init, take, send;
  logic                       readEnable;
  logic [`ImageAddrWidth-1:0] readAddr;
  logic [`ImageBitDepth-1:0]  readData;
  logic [11:0]                Dout;

  assign Dout = {GPIO[18], GPIO[16], GPIO[14], GPIO[12], GPIO[10], GPIO[4], 
                GPIO[2], GPIO[0], GPIO[1], GPIO[3], GPIO[5], GPIO[7]};

  controller ctrl (.reset(keyB[0]), .clock(CLOCK_50), .take_photo, 
        .send_image(1'b0), .done_init, .done_take, .done_send, 
        .init, .take, .send);

  SensorInitializer initializer(.clock(CLOCK_50), .reset(keyB[0]), .start(init), 
        .done(done_init), .vdd_pll(GPIO[6]), .vaa(GPIO[17]), .vdd_io(GPIO[20]), 
        .vdd(GPIO[24]), .vdd_slvs(), //output to GPIO
        .extclk(GPIO[8]), .reset_bar(GPIO[26])); //output to GPIO

  ImageSensorDataProcessor data_process(.clock(CLOCK_50), .reset(keyB[0]), 
        .error(), //error can be ignored
        .start(take), .done(done_take), .sensorTrigger(GPIO[31]),
        .sensorDout(Dout), .sensorPixclk(GPIO[22]),
        .sensorLineValid(GPIO[27]), .sensorFrameValid(GPIO[29]), //input from GPIO
        .readEnable, .readAddr, .readData);

  ImageReader send_image(.clock(CLOCK_50), .reset(keyB[0]), .start(send), 
        .done(done_send),
        .data(), //output to ethernet or vga
        .readEnable, .readAddr, .readData);  
endmodule: top
