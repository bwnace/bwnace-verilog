/*
 * Read image to VGA / Eth ?
 */

`include "image.sv"

module ImageReader
    (
        input  logic clock, reset,
        input  logic start,
        output logic done,
        output logic [`ImageBitDepth-1:0] data,

        output logic readEnable,
        output logic [`ImageAddrWidth-1:0] readAddr,
        input  logic [`ImageBitDepth-1:0] readData
    );

    logic [`ImageAddrWidth-1:0] pixelAddr;
    logic pixelAddrClr, pixelAddrInc;

    always_ff @(posedge clock) begin
        if (pixelAddrClr)
            pixelAddr <= 0;
        else if (pixelAddrInc)
            pixelAddr <= pixelAddr + 1;
    end

    enum logic [2:0] {
        IDLE, READ
    } state, stateNext;

    always_ff @(posedge clock) begin
        if (reset)
            state <= IDLE;
        else
            state <= stateNext;
    end

    always_comb begin
        stateNext = state;

        pixelAddrClr = 0;
        pixelAddrInc = 0;

        readEnable = state == READ;
        readAddr = pixelAddr;
        data = readData;

        case (state)
        IDLE: begin
            if (start) begin
                stateNext = READ;
                pixelAddrClr = 1;
            end
        end
        READ: begin
            pixelAddrInc = 1;
            if (pixelAddr == `ImageMemSize) begin
                stateNext = IDLE;
                done = 1;
            end
        end
        endcase
    end

endmodule: ImageReader
