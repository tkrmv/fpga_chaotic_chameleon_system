module angle_normalizer_q610_comb (
    input signed [15:0] theta_in,    // Q6.10 format input angle
    output signed [15:0] theta_norm, // Q6.10 normalized angle
    output cos_sgn                // Sign for cosine (1 or -1)
);

// Константы в формате Q6.10
// [pi/2, pi, 3*pi/2, 5*pi/2, 2*pi, 4*pi];
// 1608        3217        4825        8042        6434       12868
localparam signed [15:0] PI     = 16'sd3217;  // 3.141593 (π)
localparam signed [15:0] PI_2   = 16'sd1608;  // π/2
localparam signed [15:0] PI_3_2 = 16'sd4825;  // 3π/2
localparam signed [15:0] PI_5_2 = 16'sd8042;  // 5π/2
localparam signed [15:0] PI_2X  = 16'sd6434;  // 2π
localparam signed [15:0] PI_4X  = 16'sd12868;  // 4π
localparam signed [15:0] PI_3X  = 16'sd9651; // 3π 
localparam signed [15:0] PI_7_2 = 16'sd11259; // 7π/2

// Внутренние сигналы
wire signed [15:0] abs_theta = theta_in[15] ? -theta_in : theta_in;
wire signed [15:0] temp_theta;
wire sign_bit = theta_in[15];

// Логика нормализации
assign temp_theta = 
    (abs_theta < PI_2)   ? abs_theta :
   ((abs_theta < PI_3_2)  ? (abs_theta - PI) :
    ((abs_theta < PI_5_2) ? (abs_theta - PI_2X) :
    ((abs_theta < PI_7_2) ? (abs_theta - PI_3X) : (abs_theta - PI_4X))));

// Логика определения знака косинуса
assign cos_sgn = 
    (( (abs_theta > PI_2) & (abs_theta < PI_3_2) )||
    ( (abs_theta > PI_5_2) & (abs_theta < PI_7_2) )) ? 1 : 0;

// Восстановление знака угла
assign theta_norm = sign_bit ? -temp_theta : temp_theta;

endmodule