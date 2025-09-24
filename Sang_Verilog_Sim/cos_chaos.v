module cos_chaos
(
    input clk,
    input reset,
    output reg ready,
    input [15:0] a,
    input [15:0] b,
    input [15:0] c,
    input [15:0] mu,
    input [15:0] omega,
    input [15:0] h,
    input [15:0] X0,
    input [15:0] Y0,
    input [15:0] Z0,
    output reg [15:0] X,
    output reg [15:0] Y,
    output reg [15:0] Z
);

reg  signed [15:0] dX1, dY1, dZ1;
reg  signed [15:0] dX2, dY2, dZ2;
reg core_start;
wire core_ready;
wire signed [15:0] dX_out, dY_out, dZ_out;
wire signed [15:0] X_pred, Y_pred, Z_pred;

wire signed [15:0] X_in, Y_in, Z_in;
wire signed [15:0] mult_h_sum_X, mult_h_sum_Y, mult_h_sum_Z;

// state automata definition
reg [2:0] state;
reg reset_flag;

// main calculation core
cos_chaos_core #(16,10) ucore
(
    .clk(clk),
    .start(core_start),
    .ready(core_ready),
    .X_in(X_in),
    .Y_in(Y_in),
    .Z_in(Z_in),
    .a(a),
    .b(b),
    .c(c),
    .mu(mu),
    .omega(omega),
    .dX_out(dX_out),
    .dY_out(dY_out),
    .dZ_out(dZ_out)
);

//multiply results by h and add to state variables
mult_h_sum #(16,10) ux
(.in_1(mult_h_sum_X), .in_2(X), .h(h), .res(X_pred));

mult_h_sum #(16,10) uy
(.in_1(mult_h_sum_Y), .in_2(Y), .h(h), .res(Y_pred));

mult_h_sum #(16,10) uz
(.in_1(mult_h_sum_Z), .in_2(Z), .h(h), .res(Z_pred));

//switches routing
assign X_in = (state ) ? X_pred : X;
assign Y_in = (state ) ? Y_pred : Y;
assign Z_in = (state ) ? Z_pred : Z;

assign mult_h_sum_X = (state ) ? ((dX1 + dX2) >>> 1) : dX1;
assign mult_h_sum_Y = (state ) ? ((dY1 + dY2) >>> 1) : dY1;
assign mult_h_sum_Z = (state ) ? ((dZ1 + dZ2) >>> 1) : dZ1;

always @(posedge clk) begin
    if (reset) begin
        state <= 0;
        X <= X0;
        Y <= Y0;
        Z <= Z0;
        dX1 <= 0;
        dY1 <= 0;
        dZ1 <= 0;
        dX2 <= 0;
        dY2 <= 0;
        dZ2 <= 0;
        core_start <= 0;
        reset_flag <= 1;
        ready <= 0;
        
    end else begin
        if(reset_flag)
        begin
            reset_flag <= 0;
            core_start <= 1;
        end
        else
        begin
            if((core_ready) || (state > 1))
            begin   
                dX1 <= dX_out;
                dY1 <= dY_out;
                dZ1 <= dZ_out;  
                dX2 <= dX1;
                dY2 <= dY1;
                dZ2 <= dZ1;  
                        
                case (state)
                        0: begin                                                    
                            core_start <= 1; 
                            state <= state + 1; 
                        end
                        1: begin       
                            core_start <= 1; 
                            state <= state + 1; 
                        end
                        2: begin
                            state <= 0;
                            ready <= 1;
                            X <= X_pred;
                            Y <= Y_pred;
                            Z <= Z_pred;
                        end
                endcase
            end
            else
            begin
                core_start <= 0;
                ready <= 0;
            end
        end
    end
end
endmodule