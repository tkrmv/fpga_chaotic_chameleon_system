currentPath = fileparts(mfilename('fullpath'));
addpath([currentPath, '\supplementary']);

close all
% Реализация системы Санга с помощью функций fixed point, 
% встроенных в MATLAB

% Параметры системы
params = [2.5, 1, 0.01, 1, 1.85]; %a, b, c, mu,omega
x0 = [0; 5; 0]; % Начальные условия
tspan = [0 200]; % Интервал интегрирования
h = 0.025; % Шаг

word_length = 16;
fraction_length = 10;

% Решение
[t, X, Y, Z] = heun_method_cos_chaos(tspan, x0, params, h, word_length, fraction_length);
% Визуализация
figure;
plot(X, Y);
xlabel('x')
ylabel('y')
title('Решение системы методом Хойна');

figure;
plot(t, X, t, Y, t, Z);
xlabel('Time')
ylabel('Variable')
legend('x','y','z')

% plotscope(X, Y, 800, 800);

function [t, X_array, Y_array, Z_array] = heun_method_cos_chaos(tspan, x0, paramset, h, word_length, fraction_length)
    % tspan - интервал времени [t0, tf]
    % x0 - начальные условия [x1(0); x2(0); x3(0)]
    % paramset - параметры [a, b, c, mu, omega]
    % h - шаг интегрирования
    
    % Инициализация
    t = tspan(1):h:tspan(2);
    n = length(t);
    x = zeros(3, n);

    X_array = zeros(1, n);
    Y_array = zeros(1, n);
    Z_array = zeros(1, n);

    %преобразование в фиксед поинт
    f = fimath('RoundingMethod', 'Nearest', ...
               'OverflowAction', 'Wrap', ...
               'ProductMode', 'SpecifyPrecision', ...
               'ProductWordLength', word_length, ...
               'ProductFractionLength', fraction_length, ...
               'SumMode', 'SpecifyPrecision', ...
               'SumWordLength', word_length, ...
               'SumFractionLength', fraction_length);

    % Инициализация переменных состояния
    X = fi(x0(1), 1, word_length, fraction_length, f);
    Y = fi(x0(2), 1, word_length, fraction_length, f);
    Z = fi(x0(3), 1, word_length, fraction_length, f);

    % Преобразование параметров в фиксированную точку
    a = fi(paramset(1), 1, word_length, fraction_length, f);
    b = fi(paramset(2), 1, word_length, fraction_length, f);
    c = fi(paramset(3), 1, word_length, fraction_length, f);
    mu = fi(paramset(4), 1, word_length, fraction_length, f);
    omega = fi(paramset(5), 1, word_length, fraction_length, f);

    % Преобразование шага в фиксированную точку
    h_fi = fi(h, 1, word_length, fraction_length, f);
    half_h = fi(h/2, 1, word_length, fraction_length, f);

    X_array(1) = double(X);
    Y_array(1) = double(Y);
    Z_array(1) = double(Z);

    % Метод Хойна (предиктор-корректор)
    for i = 1:n-1
        % Шаг предиктора (Эйлер)
%         f = cos_chaos(t(i), x(:, i), paramset);
%         x_pred = x(:, i) + h * f;
        
        dX = -Y;
        dY = X + c*Y + a*Z;
        dZ = -mu*Z + b * fi(cos(double(omega * Y)), 1, word_length, fraction_length, f);

        % Шаг предиктора (Эйлер)
        X_pred = X + h_fi * dX;
        Y_pred = Y + h_fi * dY;
        Z_pred = Z + h_fi * dZ;

        % Шаг корректора
        dX_pred = -Y_pred;
        dY_pred = X_pred + c*Y_pred + a*Z_pred;
        dZ_pred = -mu*Z_pred + b * fi(cos(double(omega * Y_pred)), 1, word_length, fraction_length, f);

        % Шаг корректора (Хойн)
        X = X + half_h * (dX + dX_pred);
        Y = Y + half_h * (dY + dY_pred);
        Z = Z + half_h * (dZ + dZ_pred);

        % Сохранение результатов
        X_array(i+1) = double(X);
        Y_array(i+1) = double(Y);
        Z_array(i+1) = double(Z);
    end
end


% storedInteger(X)