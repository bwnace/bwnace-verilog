module top
  (input  logic CLOCK_50,
   input  logic [3:0] KEY,
   output logic [35:0] GPIO);
    
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

  always_ff @(posedge clock, posedge reset) begin 
    if (keyB[0])
      state <= START;
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
      PRESS1: begin 
        take_photo = 1'b0;
        move1 = ~keyB[2];
        move2 = 1'b0;
      end
      PRESS1: begin 
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
  logic done_init, done_take, done_send;
  logic init, take, send;
  logic readEnable;
  logic [`ImageAddrWidth-1:0] readAdd;
  logic [`ImageBitDepth-1:0] readData;

  controller ctrl (.reset, .clock, .take_photo, .send_image(1'b0), .done_init, 
        .done_take, .done_send, .init, .take, .send);

  SensorInitializer initial (.clock, .reset, .start(init), .done(done_init),
        .vdd_pll(), .vaa(), .vdd_io(), .vdd(), .vdd_slvs(), .extclk(), .reset_bar()); //outputs to GPIO

  ImageSensorDataProcessor data_process (.clock, .reset, .error(), 
        .start(take), .done(done_take),
        .sensorDout(), 
        .sensorPixclk(),
        .sensorLineValid(), sensorFrameValid(), //input from GPIO
        .readEnable, .readAddr, .readData);
        
  ImageReader send_image(.clock, .reset, .start(send), .done(done_send),
        .data(), //output to GPIO
        .readEnable, .readAddr, .readData);  
endmodule: top