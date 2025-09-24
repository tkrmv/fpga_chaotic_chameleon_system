//////////////////////////////////////////////
`timescale 1ns / 1ns

module test();

// testing params
parameter CLK_PERIOD = 10;  // 10 ns = 100 MHz
parameter SIM_TIME = 1000000; // > 1 us

// systems parameters (format Q6.10)
localparam [15:0] a      = 16'sh0A00; // 2.5  (2.5 * 2^10 = 2560 = 0x0A00)
localparam [15:0] b      = 16'sh0400; // 1.0
localparam [15:0] c      = 16'sd10; //16'sd10; // 0.01
localparam [15:0] mu     = 16'sh0400; // 1.0
localparam [15:0] omega  = 16'sd1894; // 1.85 (1.85 * 2^10 ≈ 1894 = 0x0768)

// integraton step (Q6.10)
localparam [15:0] h      = 16'sd51; // 0.05 (0.05 * 2^10 ≈ 51 = 0x0033)

// initial conditions (Q6.10)
localparam [15:0] X0 = 16'sd0000; // 0.0
localparam [15:0] Y0 = 16'sd5120; // 5.0
localparam [15:0] Z0 = 16'sd0000; // 0.0

// signals
reg clk;
reg reset;
reg start;
wire [15:0] x, y, z;
wire ready;

// file variables
integer file;
real x_real, y_real;

//unit under test
cos_chaos uut
(
    .clk(clk),
    .reset(reset),
    .ready(ready),
    .a(a),
    .b(b),
    .c(c),
    .mu(mu),
    .omega(omega),
    .h(h),
    .X0(X0),
    .Y0(Y0),
    .Z0(Z0),
    .X(x),
    .Y(y),
    .Z(z)
);

// clock generations
initial begin
    clk = 0;
    forever #(CLK_PERIOD/2) clk = ~clk; // clock (10 ns)
end

// initialization and reset
initial begin
    reset = 1;
    #(CLK_PERIOD) reset = 0;
    #(SIM_TIME) $finish; // finish simulation 
end

// open file, add header
initial begin
    file = $fopen("cos_chaos_xy_output.txt", "w");
    if (file == 0) begin
        $display("Ошибка: не удалось открыть файл");
    end else begin
        $fdisplay(file, "Time [ns]\tX (Q6.10)\tX (Decimal)\tY (Q6.10)\tY (Decimal)");
    end
end

// write solution to file
always @(posedge ready) begin
    if (!reset) begin
        x_real = $signed(x) / 1024.0; // convert Q6.10 → decimal
        y_real = $signed(y) / 1024.0; // convert Q6.10 → decimal
        $fdisplay(file, "%0t\t%d\t%f\t%d\t%f", $time, x, x_real, y, y_real);
    end
end

// file close
initial begin
    #(SIM_TIME);
    $fclose(file);
end

// VCD-dump for GTKWave
initial begin
    $dumpfile("cos_chaos.vcd");
    $dumpvars(0, test);
end

endmodule