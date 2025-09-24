module uart_tx
#(
    parameter DELAY_FRAMES =  234,// 234 - 27,000,000 (27Mhz) / 115200 Baud rate, 1 for debug
    parameter BUF_SIZE = 3
)
(
    input clk,
    input [8*BUF_SIZE-1:0] buffer,
    input nEN, //пин запуска по значению 0 на входе
    output uart_tx, //пин UART TX
    output reg nReady //сигнал окончания передачи
);

reg [3:0] txState = 0;
reg [24:0] txCounter = 0;
reg [7:0] dataOut = 0;
reg txPinRegister = 1;
reg [2:0] txBitNumber = 0;
reg [3:0] txByteCounter = 0;

assign uart_tx = txPinRegister;

localparam TX_STATE_IDLE = 0;
localparam TX_STATE_START_BIT = 1;
localparam TX_STATE_WRITE = 2;
localparam TX_STATE_STOP_BIT = 3;
//localparam TX_STATE_DEBOUNCE = 4;
integer i;

always @(posedge clk) begin
    case (txState)
        TX_STATE_IDLE: begin
            if (nEN == 0) begin
                txState <= TX_STATE_START_BIT;
                txCounter <= 0;
                txByteCounter <= 0;
            end
            else begin
                txPinRegister <= 1;
            end
            nReady <= 1;
        end 
        TX_STATE_START_BIT: begin
            txPinRegister <= 0;
            if ((txCounter + 1) == DELAY_FRAMES) begin
                txState <= TX_STATE_WRITE;
                for(i = 0; i < 7; i = i + 1)
                    dataOut[i] <= buffer[(txByteCounter) * 8 + i]; //txByteCounter
                txBitNumber <= 0;
                txCounter <= 0;
            end else 
                txCounter <= txCounter + 1;
        end
        TX_STATE_WRITE: begin
            txPinRegister <= dataOut[txBitNumber];
            if ((txCounter + 1) == DELAY_FRAMES) begin
                if (txBitNumber == 3'b111) begin
                    txState <= TX_STATE_STOP_BIT;
                end else begin
                    txState <= TX_STATE_WRITE;
                    txBitNumber <= txBitNumber + 1;
                end
                txCounter <= 0;
            end else 
                txCounter <= txCounter + 1;
        end
        TX_STATE_STOP_BIT: begin
            txPinRegister <= 1;
            if ((txCounter + 1) == DELAY_FRAMES) begin
                if (txByteCounter == BUF_SIZE - 1) begin
                    txState <= TX_STATE_IDLE;
                    nReady <= 0;
                end else begin
                    txByteCounter <= txByteCounter + 1;
                    txState <= TX_STATE_START_BIT;
                end
                txCounter <= 0;
            end else 
                txCounter <= txCounter + 1;
        end
      /*  TX_STATE_DEBOUNCE: begin
            if (txCounter == 23'b111111111111111111) begin
                if (nEN == 1) 
                    txState <= TX_STATE_IDLE;
            end else
                txCounter <= txCounter + 1;
        end*/
    endcase      
end
endmodule