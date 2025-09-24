`timescale 1ns / 1ns

module test();

    parameter SIM_TIME = 600000; // 100 us симуляции
    
    // Inputs
    reg clk;
    reg reset;
    reg btn;

    // Outputs
    wire [5:0] led;
    wire [7:0] x8bit;
    wire uart_tx;

    // Instantiate the Unit Under Test (UUT)
    cos_chaos_top uut (
        .clk(clk), 
        .reset(reset), 
        .btn(btn),
        .led(led), 
        .x8bit(x8bit), 
        .uart_tx(uart_tx)
    );

    // Clock generation
    initial begin
        clk = 0;
        btn = 0;
        forever #5 clk = ~clk; // 50 MHz clock
    end

    // Reset and button event generation
    initial begin
        reset = 1;
        #20;
        reset = 0;
        #(SIM_TIME/3);
        btn = 1;
        #1000;
        btn = 0;
        #(SIM_TIME/3);
        btn = 1;
        #1000;
        btn = 0;
        #(SIM_TIME/3) $finish; // Симуляция 
    end

    // Stimulus and monitoring
    initial begin
        $dumpfile("cos_chaos_top.vcd");
        $dumpvars(0, test);
    end

endmodule