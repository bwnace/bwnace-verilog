/*
 * CMOS sensor power-up
 */

module SensorInitializer
    (
        input  logic clock, reset,
        input  logic start,
        output logic done,

        output logic vdd_pll, vaa, vdd_io, vdd, vdd_slvs, extclk, reset_bar
    );

    logic [31:0] vddCounter, rstCounter, initCounter;
    logic vddCounterClr, rstCounterClr, initCounterClr;


    always_ff @(posedge clock) begin
        if (vddCounterClr) vddCounter <= 0; else vddCounter <= vddCounter + 1;
        if (rstCounterClr) rstCounter <= 0; else rstCounter <= rstCounter + 1;
        if (initCounterClr) initCounter <= 0; else initCounter <= initCounter + 1;
    end

    logic [3:0] state, stateNext;

    always_ff @(posedge clock) begin
        if (reset)
            state <= 0;
        else
            state <= stateNext;
    end

    always_comb begin
        stateNext = state;

        vddCounterClr = 0;
        rstCounterClr = 0;
        initCounterClr = 0;

        case (state)
        0: begin
            if (start) begin
                stateNext = 1;
                vddCounterClr = 1;
            end
        end
        1: begin
            if (vddCounter == 500) begin
                stateNext = 2;
                vddCounterClr = 1;
            end
        end
        2: begin
            if (vddCounter == 500) begin
                stateNext = 3;
                vddCounterClr = 1;
            end
        end
        3: begin
            if (vddCounter == 500) begin
                stateNext = 4;
                vddCounterClr = 1;
            end
        end
        4: begin
            if (vddCounter == 500) begin
                stateNext = 5;
                rstCounterClr = 1;
            end
        end
        5: begin
            if (rstCounter == 50000) begin
                stateNext = 6;
                initCounterClr = 1;
            end
        end
        6: begin
            if (initCounterClr == 160000) begin
                stateNext = 7;
                done = 1;
            end
        end
        7: begin
            // do nothing
        end
        endcase
    end

    always_comb begin
        vdd_pll =  state >= 1;
        vaa =      state >= 2;
        vdd_io =   state >= 3;
        vdd =      state >= 4;
        vdd_slvs = state >= 5;
        extclk =   state >= 5 ? clock : 0;
        reset_bar =state >= 6;
    end

endmodule: SensorInitializer
