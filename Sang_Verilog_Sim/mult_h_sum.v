module mult_h_sum
#(parameter
	COEFF_WL=16,
	FRAC_LEN=10)
(
    input [15:0] in_1,
    input [15:0] in_2,  
    input [15:0] h,
    output [15:0] res
);


wire [15:0] mult_out;
// multipliers
mult_shifted #(COEFF_WL,FRAC_LEN) M0
(.dataa(in_1),
.datab(h),
.result(mult_out)
);

assign res = mult_out + in_2;

endmodule