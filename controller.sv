`default_nettype none

module controller
  (input  logic reset, clock,
   input  logic take_photo, send_image, done_init, done_take, done_send, 
   output logic init, take, send);

  enum logic [2:0] {START = 3'd0, INIT = 3'd1, WAIT = 3'd2, 
                    SEND = 3'd3, PHOTO = 3'd4} state, nextState;

  always_ff @(posedge clock, posedge reset) begin 
    if (reset)
      state <= START;
    else
      state <= nextState;
  end
  
  always_comb begin  //output logic
    unique case (state)
      START: begin
        init = 1'b1;
        take = 1'b0;
        send = 1'b0;
      end
      INIT: begin 
        init = 1'b0;
        take = 1'b0;
        send = 1'b0;
      end
      WAIT: begin
        init = 1'b0;
        take = take_photo;
        send = send_image;
      end
      SEND: begin
        init = 1'b0;
        take = 1'b0;
        send = 1'b0;
      end
      PHOTO: begin
        init = 1'b0;
        take = 1'b0;
        send = 1'b0;
      end
      default: begin
        init = 1'b1;
        take = 1'b0;
        send = 1'b0;
      end
    endcase
  end

  always_comb begin  // nextState logic
    unique case (state)
      START: nextState = INIT;
      INIT: nextState = done_init ? WAIT : INIT;
      WAIT: nextState = take_photo ? PHOTO : (send_image ? SEND : WAIT);
      SEND: nextState = done_send ? WAIT : SEND;
      PHOTO: nextState = done_take ? WAIT : PHOTO;
      default: nextState = INIT;
    endcase
  end 
endmodule : controller
