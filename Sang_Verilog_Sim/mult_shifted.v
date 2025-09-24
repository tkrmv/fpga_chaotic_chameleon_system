module mult_shifted
#(parameter
	COEFF_WL=16,
	FRAC_LEN=10)
(
	input signed [COEFF_WL-1:0] dataa,
	input signed [COEFF_WL-1:0] datab,
	output [COEFF_WL-1:0] result
);

	wire [2*COEFF_WL-1:0] temp;
	assign temp = dataa * datab;
	assign result = temp >>> FRAC_LEN;
endmodule