% function bo_sang_summer
currentPath = fileparts(mfilename('fullpath'));
addpath([currentPath, '\supplementary']);

close all
paramset = [2.5, 1, 0, 1, 1.85]; %a, b, c, mu,omega

Tmax = 1000; %simulation time
h = 0.03;   %simulation time step
% initial_conditions = [2.9405; -2.1225; 0.0351];
% s = [5, 5.74, 6.2, 6.8, 7, 7.5, 7.96];
s = [5, 3, 2.5];
initial_conditions = zeros(3, length(s));
for i=1:length(s)
    initial_conditions(:,i) = [0; 0; s(i)];
end
% initial_conditions = [initial_conditions, [0; 5; 0]];
ic_vector_len = length(s);

% colors = {[0 0.4470 0.7410],...
%     [0.8500 0.3250 0.0980],...
%     [0.9290 0.6940 0.1250],...
%     [0.4940 0.1840 0.5560]};
%     [0.6350    0.0780    0.1840],...   % бордовый

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
fun = @(t,x,p) cos_chaos(t, x, [paramset(1:3), p, paramset(5)]);
analyzer = bifurcation_1d_analyzer(fun, h, Tmax); % initialize bifurcation analyzer

h_fig = figure;

for i = 1:ic_vector_len
    analyzer.plot_phase_portrait(initial_conditions(:,i), mu,...
        [1 2], {'$x$', '$y$'}, h_fig); % plot attractor to check simulation is ok
end

%test for cos periods
h_cos = figure; hold on
h_wave = figure; hold on
for i = 1:ic_vector_len
    [t, x] = analyzer.simulate(initial_conditions(:,i), mu);

    figure(h_cos)
    plot(x(2,:), cos(paramset(5)*x(2,:)), 'LineWidth', 2)

    figure(h_wave)
    plot(t, x(1,:))
end
legend('s = 5', 's = 3', 's = 2.5')
ylabel('x')
grid on


% bifurcation diagram
h_fig_bd = figure;
mu_vals = linspace(0.4, 1.2, Npts);
bif_ic = [0; 5; 0];

analyzer.fast_run(analysed_variable_idx, mu_vals,...
     bif_ic); %run bifurcation analysis
analyzer.plot_bifurcation_diagram('$\mu$', '$x$', 'k', h_fig_bd)
title('Bif. Diag., c $\textless$ 0');

N_pts_bif = 500;
color_eps = 0.5;
s_vals = linspace(2, 5.5, N_pts_bif);

figure;
hold on;
means_arr = [];
colors_ctr = 0;
for s = s_vals
    [t, Y] = analyzer.simulate([0;0;s], mu);
    Lstab = round(0.3 * size(Y, 2)):size(Y, 2);
    Y = Y(:,Lstab);

    [peakLocr, peakMagr] = peakfinder(Y(1,:), 0.01);
    %крайние пики исключаем
    peakMagr = peakMagr(5:(length(peakMagr)-1));
    peakLocr = peakLocr(5:(length(peakLocr)-1));

    Lpm = length(peakMagr);
    tmp = zeros(1, N_pts_bif - Lpm);
    new_mean = mean(peakMagr);
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
    plot(ones(1,Lpm) * s, peakMagr,...
        'LineStyle', 'none', 'Marker', '.', 'Color', colors{colors_ctr}, 'MarkerSize', 2);
    drawnow
end
setLatexLabels('$s$','$x$','Bif. Diag. vs IC, c $\textless$ 0')

%% c > 0 = self-excited attractor
paramset(3) = 0.01; %c
fun = @(t,x,p) cos_chaos(t, x, [paramset(1:3), p, paramset(5)]);
analyzer = bifurcation_1d_analyzer(fun, h, Tmax); % initialize bifurcation analyzer

h_fig = figure;

initial_conditions(:,3) = [0; 0; 2];

for i = 1:ic_vector_len
    analyzer.plot_phase_portrait(initial_conditions(:,i), mu,...
        [1 2], {'$x$', '$y$'}, h_fig); % plot attractor to check simulation is ok
end

%test for cos periods
figure;
for i = 1:ic_vector_len
    [t, x] = analyzer.simulate(initial_conditions(:,i), mu);
    hold on
    plot(x(2,:), cos(paramset(5)*x(2,:)), 'LineWidth', 2)
end

% bifurcation diagram
h_fig_bd = figure;
mu_vals = linspace(0.4, 1.2, Npts);
bif_ic = [0; 5; 0];

analyzer.fast_run(analysed_variable_idx, mu_vals,...
     bif_ic); %run bifurcation analysis
analyzer.plot_bifurcation_diagram('$\mu$', '$x$', 'k', h_fig_bd)
title('Bif. Diag. vs IC, c $\textgreater$ 0')

% bifurcation diagram with respect to IC
figure;
hold on;
means_arr = [];
colors_ctr = 0;
for s = s_vals
    [t, Y] = analyzer.simulate([0;0;s], mu);
    Lstab = round(0.3 * size(Y, 2)):size(Y, 2);
    Y = Y(:,Lstab);

    [peakLocr, peakMagr] = peakfinder(Y(1,:), 0.01);
    %крайние пики исключаем
    peakMagr = peakMagr(5:(length(peakMagr)-1));
    peakLocr = peakLocr(5:(length(peakLocr)-1));

    Lpm = length(peakMagr);
    tmp = zeros(1, N_pts_bif - Lpm);
    new_mean = mean(peakMagr);
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
    plot(ones(1,Lpm) * s, peakMagr,...
        'LineStyle', 'none', 'Marker', '.', 'Color', colors{colors_ctr}, 'MarkerSize', 2);
    drawnow
end
setLatexLabels('$s$','$x$','Bif. Diag. vs IC, c $\textgreater$ 0')

% return
% analyzer.get_continuation_bifurcation_diagram(1, p_vals,...
%            initial_conditions, param_name, analysed_variable_name);


function dy = cos_chaos(t, x, paramset)

% a = 2.5;
% b = 1;
a = paramset(1);
b = paramset(2);
c = paramset(3);
mu = paramset(4);
omega = paramset(5);

dy = [-x(2);...
    x(1) + c*x(2) + a*x(3);
    -mu*x(3) + b * cos(omega * x(2))];

end