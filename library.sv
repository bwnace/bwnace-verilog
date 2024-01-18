`default_nettype none

module dFlipFlop
    (output logic q,
     input  logic d, clock, load);
    always_ff @(posedge clock)
        if (load)
            q <= 1'b1;
        else
            q <= d;
endmodule : dFlipFlop