module cos_chaos_core
#(parameter
	COEFF_WL=16,
	FRAC_LEN=10)
(
    input clk,
    input start,
    output ready,
    input [15:0] X_in,
    input [15:0] Y_in,
    input [15:0] Z_in,
    input [15:0] a,
    input [15:0] b,
    input [15:0] c,
    input [15:0] mu,
    input [15:0] omega,
    output [15:0] dX_out,
    output [15:0] dY_out,
    output [15:0] dZ_out
);
    
wire signed [15:0] aZ, cY, omegaY, muZ, bCos;
wire signed [15:0] cos_output;

// module CORDIC for cosine calculation
cos_cordic_q610 cordic_unit( 
    .iCLK (clk),
    .iEN (start),
    .iAngle (omegaY),
    .oRDY(ready),
    .oUcos (cos_output)
    //.oUsin ()
); 

// multipliers
mult_shifted #(COEFF_WL,FRAC_LEN) M0
(.dataa(c),
.datab(Y_in),
.result(cY)
);
mult_shifted #(COEFF_WL,FRAC_LEN) M1
(.dataa(a),
.datab(Z_in),
.result(aZ)
);
mult_shifted #(COEFF_WL,FRAC_LEN) M2
(.dataa(omega),
.datab(Y_in),
.result(omegaY)
);
mult_shifted #(COEFF_WL,FRAC_LEN) M3
(.dataa(mu),
.datab(Z_in),
.result(muZ)
);
mult_shifted #(COEFF_WL,FRAC_LEN) M4
(.dataa(b),
.datab(cos_output),
.result(bCos)
);

assign dX_out = (-Y_in);
assign dY_out = (X_in + cY + aZ);
assign dZ_out = (-muZ + bCos);
endmodule