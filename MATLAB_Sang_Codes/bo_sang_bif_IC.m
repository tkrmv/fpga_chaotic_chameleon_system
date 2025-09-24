%
currentPath = fileparts(mfilename('fullpath'));
addpath([currentPath, '\supplementary']);

close all
paramset = [2.5, 1, 0, 1, 1.85]; %a, b, c, mu,omega
fraction_length = 10; %10 bit for fractional part
resolution = 300; %dpi

h = 0.025;   %simulation time step
Tmax = h*9e4; %simulation time
tspan = [0 Tmax]; 

s = [5, 6];
initial_conditions = zeros(3, length(s));
for i=1:length(s)
    initial_conditions(:,i) = [0; s(i); 0];
end

% initial_conditions = [initial_conditions, [0; 5; 0]];
ic_vector_len = length(s);

colors = {[0.3010    0.7450    0.9330],...   % голубой
    [0.8500 0.3250 0.0980],...% красный
    [0.9290    0.6940    0.1250],...    % желтый
    [0.4660    0.6740    0.1880],...    % зеленый
    [0.4940    0.1840    0.5560],...    % фиолетовый
    [0.8500    0.3250    0.0980],...    % оранжевый
    [0    0.4470    0.7410]};   % синий

Npts = 500; %number of points in bifurcation diagram
param_name = '$a$'; %label for horizontal axis
p_vals = linspace(0.1, 0.5, Npts); %array of bifurcation parameter values
analysed_variable_idx = 1; % analysis is performed on the variable X of ODE
analysed_variable_name = '$x$';

mu = paramset(4);

%% c < 0 = hidden attractor
paramset(3) = -0.01; %c
filename = 'bif_IC_c_neg.png';

h_fig = figure;
h_fig.Units = 'pixels';
h_fig.Position = [0 0 250 250];
xlim = [-8, 10];
ylim = [-8, 10];
xy_name = 'bd.png';
colId = [1 2];
for i = 1:ic_vector_len
    [t, X, Y, Z] = sang_system_heun_method(tspan, [0;s(i);0], paramset, h, 16, fraction_length);
    Lstab = round(0.3 * length(t)):length(t);
    X = X(Lstab);
    Y = Y(Lstab);
    hold on
    plot(X, Y, 'Color', colors{colId(i)});
    setLatexLabels('$x$', '$y$',...
        ['$c = ', num2str(paramset(3)),'$'],... % $(x_0, y_0, z_0) = (0, s, 0)$, 
        {'$s = 5$', '$s = 6$'})
    set(gca, 'XLim', xlim)
    set(gca, 'YLim', ylim)
    grid on
end
exportgraphics(h_fig, xy_name, 'Resolution', resolution, 'ContentType', 'image')

N_pts_bif = 500;
color_eps = 0.5;
s_vals = linspace(2, 12, N_pts_bif);

% bifurcation diagram with respect to IC
fig = figure;
fig.Units = 'pixels';
fig.Position = [0 0 300 250];
hold on;
means_arr = [];
colors_ctr = 0;
for sv = s_vals
    [t, X, Y, Z] = sang_system_heun_method(tspan, [0;sv;0], paramset, h, 16, fraction_length);
    Lstab = round(0.3 * length(t)):length(t);
    X = X(Lstab);
    [peakLocr, peakMagr] = peakfinder(X, 0.01);

    %крайние пики исключаем
    peakMagr = peakMagr(5:(length(peakMagr)-1));
    peakLocr = peakLocr(5:(length(peakLocr)-1));

    Lpm = length(peakMagr);
    tmp = zeros(1, N_pts_bif - Lpm);
    new_mean = mean(peakMagr);
    if ((new_mean > -10) && (new_mean < 20))
        ncflag = 1;
        for j=1:length(means_arr)
            if abs(new_mean - means_arr(j)) < color_eps
                colors_ctr = j;
                ncflag = 0;
                break;
            end    
        end
        if isempty(means_arr)
            j = 0;
        end
        if ncflag
            colors_ctr = j + 1;
            means_arr = [means_arr, new_mean];
        end
        plot(ones(1,Lpm) * sv, peakMagr,...
            'LineStyle', 'none', 'Marker', '.', 'Color', colors{colors_ctr}, 'MarkerSize', 2);
    end
    drawnow
end
setLatexLabels('$s$','$x$','$(x_0, y_0, z_0) = (0, s, 0)$, $c = -0.01$');
grid on
exportgraphics(fig, filename, 'Resolution', 300, 'ContentType', 'image')

%% c > 0 = self-excited attractor
paramset(3) = 0.01; %c
filename = 'bif_IC_c_pos.png';

h_fig = figure;
h_fig.Units = 'pixels';
h_fig.Position = [0 0 250 250];
xlim = [-8, 10];
ylim = [-8, 10];
xy_name = 'ac.png';
colId = [2 3];
for i = 1:ic_vector_len
    [t, X, Y, Z] = sang_system_heun_method(tspan, [0;s(i);0], paramset, h, 16, fraction_length);
    Lstab = round(0.3 * length(t)):length(t);
    X = X(Lstab);
    Y = Y(Lstab);
    hold on
    plot(X, Y, 'Color', colors{colId(i)});
    setLatexLabels('$x$', '$y$',...
        [' $c = ', num2str(paramset(3)),'$'],... %$(x_0, y_0, z_0) = (0, s, 0)$,
        {'$s = 5$', '$s = 6$'})
    set(gca, 'XLim', xlim)
    set(gca, 'YLim', ylim)
    grid on
end
exportgraphics(h_fig, xy_name, 'Resolution', resolution, 'ContentType', 'image')

% bifurcation diagram with respect to IC
fig = figure;
fig.Units = 'pixels';
fig.Position = [0 0 300 250];

hold on;
means_arr = [];
colors_ctr = 0;
for s = s_vals
        [t, X, Y, Z] = sang_system_heun_method(tspan, [0;s;0], paramset, h, 16, fraction_length);
    Lstab = round(0.3 * length(t)):length(t);
    X = X(Lstab);
    [peakLocr, peakMagr] = peakfinder(X, 0.01);

    %крайние пики исключаем
    peakMagr = peakMagr(5:(length(peakMagr)-1));
    peakLocr = peakLocr(5:(length(peakLocr)-1));

    Lpm = length(peakMagr);
    tmp = zeros(1, N_pts_bif - Lpm);
    new_mean = mean(peakMagr);
    ncflag = 1;
    if ((new_mean > -10) && (new_mean < 20))
        for j=1:length(means_arr)
            if abs(new_mean - means_arr(j)) < color_eps
                colors_ctr = j;
                ncflag = 0;
                break;
            end    
        end
        if isempty(means_arr)
            j = 0;
        end
        if ncflag
            colors_ctr = j + 1;
            means_arr = [means_arr, new_mean];
        end
        plot(ones(1,Lpm) * s, peakMagr,...
            'LineStyle', 'none', 'Marker', '.', 'Color', colors{colors_ctr}, 'MarkerSize', 2);
    end
    drawnow
end
setLatexLabels('$s$','$x$','$(x_0, y_0, z_0) = (0, s, 0)$, $c = 0.01$');
grid on
exportgraphics(fig, filename, 'Resolution', 300, 'ContentType', 'image')


%%  ORIGINAL ODE %%
% function dy = cos_chaos(t, x, paramset)
% 
% % a = 2.5;
% % b = 1;
% a = paramset(1);
% b = paramset(2);
% c = paramset(3);
% mu = paramset(4);
% omega = paramset(5);
% 
% dy = [-x(2);...
%     x(1) + c*x(2) + a*x(3);
%     -mu*x(3) + b * cos(omega * x(2))];
% 
% end