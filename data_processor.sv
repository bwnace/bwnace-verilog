/*
 * CMOS sensor output data processor
 */

`define ImageDimX 1280
`define ImageDimY 960
`define ImageBitDepth 12
`define ImageMemSize ( `ImageDimX * `ImageDimY )
`define ImageAddrWidth ( $clog2(`ImageMemSize) )

`define TriggerCycles 3840
`define TriggerCntWidth ( $clog2(`TriggerCycles) )

module ImageMem
    (
        input  logic clock,

        input  logic writeEnable,
        input  logic [`ImageAddrWidth-1:0] writeAddr,
        input  logic [`ImageBitDepth-1:0] writeData,

        input  logic readEnable,
        input  logic [`ImageAddrWidth-1:0] readAddr,
        output logic [`ImageBitDepth-1:0] readData
    );

    logic [`ImageBitDepth-1:0] mem[0:`ImageMemSize-1];
    
    always_ff @(posedge clock) begin
        if (writeEnable)
            mem[writeAddr] <= writeData;
    end

    always_ff @(posedge clock) begin
        readData <= mem[readAddr];
    end

endmodule: ImageMem


module ImageSensorDataProcessor
    (
        input  logic clock, reset,
        output logic error,

        input  logic start,
        output logic done,
        input  logic [11:0] sensorDout,
        input  logic sensorPixclk,
        input  logic sensorLineValid, sensorFrameValid,

        input  logic readEnable,
        input  logic [`ImageAddrWidth-1:0] readAddr,
        output logic [`ImageBitDepth-1:0] readData
    );

    // Commit current pixel
    logic pixelCommit;
    logic [`ImageAddrWidth-1:0] pixelAddr;
    logic pixelAddrClr, pixelAddrInc;

    ImageMem m_imgMem(
        .clock,
        .writeEnable(pixelCommit),
        .writeAddr(pixelAddr),
        .writeData(sensorDout),
        .readEnable, .readAddr, .readData
    );

    always_ff @(posedge clock) begin
        if (pixelAddrClr)
            pixelAddr <= 0;
        else if (pixelAddrInc)
            pixelAddr <= pixelAddr + 1;
    end

    logic [`TriggerCntWidth-1:0] triggerCnt;
    logic triggerCntClr, triggerCntInc;
    always_ff @(posedge clock) begin
        if (triggerCntClr)
            triggerCnt <= 0;
        else if (triggerCntInc)
            triggerCnt <= triggerCnt + 1;
    end

    // Idle -> Trigger -> Ready -> Active
    enum logic [2:0] {
        IDLE, TRIGGER, READY, ACTIVE
    } state, stateNext;

    always_ff @(posedge clock) begin
        if (reset)
            state <= IDLE;
        else
            state <= stateNext;
    end

    always_comb begin
        stateNext = state;

        pixelCommit = 0;
        pixelAddrClr = 0;
        pixelAddrInc = 0;

        triggerCntClr = 0;
        triggerCntInc = 0;

        case (state)
        IDLE: begin
            if (start) begin
                stateNext = TRIGGER;

                triggerCntClr = 1;
                pixelAddrClr = 1;
            end
        end
        TRIGGER: begin
            triggerCntInc = 1;
            if (triggerCnt == `TriggerCycles) begin
                stateNext = READY;
            end
        end
        READY: begin
            if (sensorPixclk && sensorLineValid && sensorFrameValid) begin
                stateNext = ACTIVE;

                pixelCommit = 1;
                pixelAddrInc = 1;
            end
        end
        ACTIVE: begin
            if (!sensorPixclk)
                stateNext = READY;
            if (pixelAddr == `ImageMemSize)
                stateNext = IDLE;
        end
        endcase
    end

endmodule: ImageSensorDataProcessor
