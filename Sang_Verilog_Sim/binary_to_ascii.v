module binary_to_ascii (
    input wire nEN,
    input wire [7:0] binary_in,  // 8-битное входное число (0-255)
    output [23:0] ascii_htu    // ASCII (3 цифры)
);

reg [3:0] hundreds;  // Цифра сотен (0-2)
reg [3:0] tens;      // Цифра десятков (0-9)
reg [3:0] units;     // Цифра единиц (0-9)
reg [7:0] tmp;

// Преобразуем цифры в ASCII
assign ascii_htu[7:0] = {4'b0011, hundreds};
assign ascii_htu[15:8] = {4'b0011, tens};
assign ascii_htu[23:16] = {4'b0011, units};

always @(negedge nEN) begin
    // Вычисляем цифры
  /*  hundreds = binary_in / 8'b01100100; //100
    tmp = binary_in - hundreds;
    tens = tmp / 8'b00001010; //10
    units = tmp - tens;*/

    hundreds <= binary_in / 8'b01100100;
    tens <= (binary_in % 8'b01100100) / 8'b00001010;
    units <= binary_in % 8'b00001010;
end

endmodule