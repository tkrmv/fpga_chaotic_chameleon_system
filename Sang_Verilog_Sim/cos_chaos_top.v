module cos_chaos_top (
    input clk,
    input reset,
    input btn,
    output reg [5:0] led,
    output [7:0] x8bit,
	output uart_tx
);

    localparam BYTE_COUNTER = 5;
    
    //выставить эти параметры для компиляции
/*	localparam DELAY = 234;
	localparam FREQ_DIVIDER = 4500000;*/
  //выставить эти параметры для запуска тестбенча
	localparam DELAY = 1;
	localparam FREQ_DIVIDER = 40;
    localparam DEBOUNCE_DELAY = 10;
    // Сигналы
    reg start;
    reg nEN;
    wire [15:0] x, y, z;
    wire ready;
    wire bta_enable;
    wire [BYTE_COUNTER*8-1:0] buffer;

    reg [31:0] counter;
    reg [15:0] btn_debounce_ctr;
    reg [1:0] btn_event;
    reg  signed [15:0] c_val;

    
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

    //module itself
    cos_chaos uut
    (
        .clk(clk),
        .reset(reset),
        .ready(ready),
        .a(a),
        .b(b),
        .c(c_val), //variable parameter
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

    assign x8bit = (x + (1 << 14)) >>> 7; //convert to 8 number for UART


    //представление анализируемого числа в виде трех десятичных разрядов
    binary_to_ascii ba(.nEN(nEN), .binary_in(x8bit), .ascii_htu(buffer[23:0]));
    //конец строки + перевод каретки
	assign buffer[31:24] = 8'h0D;
	assign buffer[39:32] = 8'h0A;
	//передача анализируемого числа по UART
	uart_tx #(
        .DELAY_FRAMES(DELAY),
        .BUF_SIZE(BYTE_COUNTER)
    ) ut(.clk(clk), .buffer(buffer), .nEN(nEN), .uart_tx(uart_tx), .nReady());
	
    always @(posedge clk)
    begin
        if(reset) begin
            counter <= 0;
            led <= 6'b0;
            c_val <= c;
            btn_debounce_ctr <= 0;
            btn_event <= 0;
        end else begin
            counter <= counter + 1;

            //debounce automata
            if((btn) && (~btn_event))
            begin
                if(btn_debounce_ctr == 0)
                begin
                    btn_debounce_ctr <= btn_debounce_ctr + 1;
                end
            end
            else
            begin //release button
                if (btn_event == 1)
                    c_val = -c_val;

                btn_event <= 0;
                btn_debounce_ctr <= 0;
            end

            if(btn_debounce_ctr > DEBOUNCE_DELAY)
            begin
                if(btn)
                begin
                    //button event
                    btn_event <= 1;
                end
            end
            else if(btn_debounce_ctr > 0)
                btn_debounce_ctr <= btn_debounce_ctr + 1;

            //main logic
            if (counter == FREQ_DIVIDER)  // 4500000 для прошивки (1/6 секунды), 50 для симуляции
			begin
                start <= 1;
			    counter <= 0;
				nEN <= 0; //запуск записи по UART
                start <= 1; //запуск вычисления новой точки хаотической динамики

                //indicate c_val by running led direction
                if (c_val > 0)
                    led <= led == 6'b011111 ? 6'b111110 : {led[4:0], 1'b1};
                else
                    led <= led == 6'b111110 ? 6'b011111 : {1'b1, led[5:1]};
            end
			else
            begin
				nEN <= 1; 
                start <= 0;
            end
        end
    end

endmodule