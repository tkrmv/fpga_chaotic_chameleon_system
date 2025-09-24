`timescale 1ns/1ps

module test;

// Параметры тестирования
parameter CLK_PERIOD = 10;       // 10ns = 100MHz
parameter SIM_TIME = 2830;       // full wave
parameter START_ANGLE = -9*16'sd1608; // -9π/2 в Q6.10
parameter END_ANGLE = 9*16'sd1608;   // 9π/2 в Q6.10
parameter STEP_ANGLE = 16'sd102;     // 0.1 - increment
parameter PI_Q610 = 16'sd3217;       // π в Q6.10

// Сигналы
reg clk;
reg reset;
reg start;
reg signed [15:0] angle;
wire signed [15:0] cos_out;
wire signed [15:0] sin_out;
wire ready;

// Вспомогательные переменные
integer file;
integer i;
real angle_real, cos_real, sin_real;

// Экземпляр тестируемого модуля
cos_sin_cordic_q610 dut (
    .iCLK(clk),
    .iEN(start),
    .iAngle(angle),
    .oRDY(ready),
    .oUcos(cos_out),
    .oUsin(sin_out)
);

// Генератор тактового сигнала
initial begin
    clk = 0;
    forever #(CLK_PERIOD/2) clk = ~clk;
//    #(SIM_TIME) $finish; // Останов сыимуляции
end

// Функция преобразования Q6.10 в real
function real q610_to_real;
    input signed [15:0] val;
    begin
        q610_to_real = $signed(val) / 1024.0;
    end
endfunction

// Основной процесс тестирования
initial begin
    // Инициализация
    reset = 1;
    start = 0;
    angle = START_ANGLE;
end

// Открытие файла для записи результатов
initial begin
    
 /*   file = $fopen("cos_sin_results.txt", "w");
    $fwrite(file, "Angle(rad)\tAngle(deg)\tCos(Q6.10)\tCos(real)\tSin(Q6.10)\tSin(real)\n");
      */
    // Сброс
    #(CLK_PERIOD*2);
    reset = 0;
    
    // Перебор углов
    for (i = 0; angle <= END_ANGLE; i = i + 1) begin
        angle = START_ANGLE + i*STEP_ANGLE;
        
        // Запуск вычисления
        start = 1;
        #(CLK_PERIOD);
        start = 0;
        
        // Ожидание готовности результата
        @(posedge ready);
        #(CLK_PERIOD/2);
        
        // Преобразование в вещественные числа
        angle_real = q610_to_real(angle);
        cos_real = q610_to_real(cos_out);
        sin_real = q610_to_real(sin_out);
        
        // Запись в файл
        $fwrite(file, "%f\t%f\t%h\t%f\t%h\t%f\n",
                angle_real,
                angle_real * 180.0 / 3.1415926535,
                cos_out,
                cos_real,
                sin_out,
                sin_real);
        
        // Вывод в консоль для контроля
   /*     $display("Angle: %f rad (%f deg) Cos: %f Sin: %f",
                 angle_real,
                 angle_real * 180.0 / 3.1415926535,
                 cos_real,
                 sin_real);*/
        
        // Пауза между вычислениями
        #(CLK_PERIOD*2);
    end
    
    // Завершение симуляции
    $fclose(file);
    $dumpoff;
    $display("Simulation completed successfully");
    $finish;
end

initial begin
    // Настройка VCD дампа
    $dumpfile("cordic_q610_wave.vcd");
    $dumpvars(0, test);
end
endmodule