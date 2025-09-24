module cos_cordic_q610
(
	input iCLK,
	input iEN,
	input signed [15:0] iAngle,
	output oRDY,
	// result calculate after 10 iterations:
	output reg signed [15:0]  oUcos
);

// Параметры CORDIC
localparam K = 16'sd622; // K в Q6.10 (0.607252935 * 2^10 ≈ 622)
localparam ITERATIONS = 10;

reg go_en;
reg [7:0] ctr;
reg ready;
// Registers for CORDIC iterative procedure
reg signed [15:0] x;
reg signed [15:0] y;
reg signed [15:0] resX;
reg signed [15:0] resY;
reg signed [15:0] z;
reg signed [15:0] xtmp;
reg signed [15:0] ytmp;
reg signed [1:0] sign;
wire cos_sign;
reg [2:0] quarterIdx;

assign oRDY = ready;

// LUT - 10 steps
wire signed [15:0] atan[9:0] ;
// 804   475   251   127    64    32    16     8     4     2     1 
assign atan[0]  = 16'sd804; // 45.000000 градусов (PI/4)
assign atan[1]  = 16'sd475; // 26.565051 градусов
assign atan[2]  = 16'sd251; // 14.036243 градусов
assign atan[3]  = 16'sd127; // 7.125016 градусов
assign atan[4]  = 16'sd64; // 3.576334 градусов
assign atan[5]  = 16'sd32; // 1.789911 градусов
assign atan[6]  = 16'sd16; // 0.895174 градусов
assign atan[7]  = 16'sd8; // 0.447614 градусов
assign atan[8]  = 16'sd4; // 0.223811 градусов
assign atan[9]  = 16'sd2; // 0.111906 градусов
//остальные шаги приводят к добавлению нуля


// Подключение модуля нормализации входного угла
wire signed [15:0] normalized_angle;

angle_normalizer_q610_comb norm_inst (
    .theta_in(iAngle),
    .theta_norm(normalized_angle),
    .cos_sgn(cos_sign)
); 

always @(posedge iCLK)
begin
	if(iEN)
	begin
        x <= K; // начальное значение
        y <= 0;
        xtmp <= K;
        ytmp <= 0;
        z <= normalized_angle;
        ctr <= 0;
        ready <= 0;
	end
    else
    begin
        // Main iterative procedure (rotation)
        if (ctr < ITERATIONS)
        begin
			ready <= 0;
            if (z < 0)
            begin
                x <= x + ytmp;
                y <= y - xtmp;
                z <= z + atan[ctr ];
                xtmp <= (x + ytmp) >>> (ctr + 1);
                ytmp <= (y - xtmp) >>> (ctr + 1);
            end
            else
            begin
                x <= x - ytmp;
                y <= y + xtmp;
                z <= z - atan[ctr ];
                xtmp <= (x - ytmp) >>> (ctr + 1);
                ytmp <= (y + xtmp) >>> (ctr + 1);
            end
            
        end

        if (ctr == ITERATIONS - 2)
        begin
            ready <= 1'b1;
           // oUcos <= (cos_sign ? x : -x);
            oUcos <= (cos_sign ? -x : x);
        end
        else
            ready <= 1'b0;

        ctr <= ctr + 8'b1;
    end
end


endmodule