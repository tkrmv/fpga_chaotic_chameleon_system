currentPath = fileparts(mfilename('fullpath'));
addpath([currentPath, '\supplementary']);

close all
%path = 'C:\Users\elektroraum\YandexDisk\LETI2\2025\DPO_Verilog\FPGA_math\cos_chaos_2';
currentPath = fileparts(mfilename('fullpath'));
filePath = fullfile(fileparts(currentPath), 'Sang_Verilog_Sim');

M = readmatrix([filePath, '\cos_chaos_xy_output.txt']);
figure;
subplot(1,2,1)
plot(M(:,3), M(:,5));
setLatexLabels('$x$', '$y$', 'Verilog Simulation')
subplot(1,2,2)
plot(M(:,1), M(:,3), M(:,1), M(:,5));
setLatexLabels('$Time, ns$', 'State Var',...
    'Verilog Simulation', {'$x$','$y$'});
grid on