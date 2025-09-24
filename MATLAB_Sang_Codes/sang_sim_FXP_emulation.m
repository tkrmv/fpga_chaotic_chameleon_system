currentPath = fileparts(mfilename('fullpath'));
addpath([currentPath, '\supplementary']);

close all

% Параметры системы
params = [2.5, 1, 0, 1, 1.85]; %a, b, c, mu,omega
x0 = [0; 5; 0]; % Начальные условия
tspan = [0 200]; % Интервал интегрирования
h = 0.05; % Шаг

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

    frac_scale = 2^fraction_length;

    % Инициализация переменных состояния
    X = round(x0(1) * frac_scale);
    Y = round(x0(2) * frac_scale);
    Z = round(x0(3) * frac_scale);

    % Преобразование параметров в фиксированную точку
    a = round(paramset(1) * frac_scale);
    b = round(paramset(2) * frac_scale);
    c = round(paramset(3) * frac_scale);
    mu = round(paramset(4) * frac_scale);
    omega = round(paramset(5) * frac_scale);

    % Преобразование шага в фиксированную точку
    h_fi = round(h * frac_scale);
    half_h = round(h/2 * frac_scale);

    X_array(1) = X / frac_scale;
    Y_array(1) = Y / frac_scale;
    Z_array(1) = Z / frac_scale;

    % Метод Хойна (предиктор-корректор)
    for i = 1:n-1

        % Шаг предиктора (Эйлер)        
        dX = -Y;
        dY = X + round(c*Y/frac_scale) + round(a*Z/frac_scale);
        cordic_input = round((omega * Y) / frac_scale);
        cos_output = round(cos(cordic_input / frac_scale) * frac_scale);
        dZ = round(-mu * Z / frac_scale) + round(b * cos_output / frac_scale);

        % Шаг предиктора (Эйлер)
        X_pred = X + round(h_fi * dX / frac_scale);
        Y_pred = Y + round(h_fi * dY / frac_scale);
        Z_pred = Z + round(h_fi * dZ / frac_scale);

        % Шаг корректора
        dX_pred = -Y_pred;
        dY_pred = X_pred + round(c*Y_pred/frac_scale) + round(a*Z_pred/frac_scale) ;
        cordic_input = round((omega * Y_pred) / frac_scale);
        cos_output = round(cos(cordic_input / frac_scale) * frac_scale);
        dZ_pred = round(-mu * Z_pred / frac_scale) + round(b * cos_output / frac_scale) ;

        % Шаг корректора (Хойн)
        X = X + round(half_h * (dX + dX_pred) / frac_scale);
        Y = Y + round(half_h * (dY + dY_pred) / frac_scale);
        Z = Z + round(half_h * (dZ + dZ_pred) / frac_scale);

        % Сохранение результатов
        X_array(i+1) = X / frac_scale;
        Y_array(i+1) = Y / frac_scale;
        Z_array(i+1) = Z / frac_scale;
    end
end


% storedInteger(X)