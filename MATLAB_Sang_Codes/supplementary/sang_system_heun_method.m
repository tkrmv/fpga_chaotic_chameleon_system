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
        
        tmpX = X;
        tmpY = Y;
        tmpZ = Z;
        X = X_pred;
        Y = Y_pred;
        Z = Z_pred;
        
        % Шаг корректора
        dX_pred = -Y;
        dY_pred = X + round(c*Y/frac_scale) + round(a*Z/frac_scale) ;
        cordic_input = round((omega * Y) / frac_scale);
        cos_output = round(cos(cordic_input / frac_scale) * frac_scale);
        dZ_pred = round(-mu * Z / frac_scale) + round(b * cos_output / frac_scale) ;

        % Шаг корректора (Хойн)
        X = tmpX + round(half_h * (dX + dX_pred) / frac_scale);
        Y = tmpY + round(half_h * (dY + dY_pred) / frac_scale);
        Z = tmpZ + round(half_h * (dZ + dZ_pred) / frac_scale);

        % Сохранение результатов
        X_array(i+1) = X / frac_scale;
        Y_array(i+1) = Y / frac_scale;
        Z_array(i+1) = Z / frac_scale;
    end
end
