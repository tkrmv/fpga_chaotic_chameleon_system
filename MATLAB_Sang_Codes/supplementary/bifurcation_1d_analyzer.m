classdef bifurcation_1d_analyzer < handle
    %BIFURCATION_1D_ANALYZER tool for getting basic types of bifurcation
    %analysis for nonlinear systems, defined as ODE.
    %
    %   Contains the following functions:
    %   bifurcation_1d_analyzer(fun, h, Tmax, solver) - initialization
    %   simulate(initial_conditions, bif_param_val)   - run ODE solver
    %   plot_phase_portrait(initial_conditions, bif_param_val, var_idx,
    %       var_names) - run simulation and visualize attractor excluding
    %       transient time
    %   plot_time_series(obj, initial_conditions, bif_param_val, var_idx,
    %       var_names) - run simulation and show waveforms for state variables
    %       defined in var_idx
    %   fast_run(obj, var_idx, PVals, initial_conditions,
    %       continuation_flag) - run bifurcation analysis, analyzing waveforms only using
    %       peakfinder and user function UserAnalysisFunction (if defined)
    %   run(obj, var_idx, PVals, initial_conditions)  - run bifurcation
    %       analysis, analyzing waveforms with several analysis methods and 
    %       user function UserAnalysisFunction (if defined)
    %   get_continuation_bifurcation_diagram(obj, var_idx, PVals,
    %       initial_conditions, PName, VarName) - execute fast_run twice in two 
    %       directions of bifurcation parameter increment/decrement,
    %       transferring last simulation point as initial condition for the
    %       next run. This type of analysis used to reveal multistability of ODE.
    %   plot_all(obj, PName, VarName) - execute after run/fast_run to
    %       visualize all availible types of plots. These include:
    %   plot_density_bifurcation_diagram(obj, PName, VarName)
    %   plot_bifurcation_diagram(obj, PName, VarName, color, figure_id)
    %   plot_density_colored_bifurcation_diagram(obj, PName, VarName)
    %   plot_interpeak_diagram(obj, PName, VarName, nBins)
    %   plot_spectral_bifurcation_diagram(obj, PName)
    %
    %   Main properties:
    %   LLE	- array of largest Lyapulov exponent values. Address to it
    %       after executing run
    %   UserAnalysisFunction - assign hanle to your analysis function,
    %       which takes waveform as argument, with scalar or vector output.
    %       E.g.: 
    %       analyzer.UserAnalysisFunction = @(x)myFunction(x); % x - timeserie
    %   UserAnalysisResultsArray - 1D or 2D array of values. Address to it
    %       after executing run or fast_run
    %
    %   Application example:
    %   analyzer = bifurcation_1d_analyzer(fun, h, Tmax); %fun - ODE, h -
    %   time step, Tmax - simulation time
    %   analyzer.run(1, p_vals,  initial_conditions); %
    %   p_vals - array of bifurcation parameter values
    %   analyzer.plot_all('p', 'x'); % 'p' - parameter
    %   name to label horizontal axis of the plot; 'x' - analysed variable name to label
    %   vertical axis

    %   Author: Timur Karimov
    %   For examples of using this tool, please refer to the following papers:
    %   DOI: 10.3390/s22145212, DOI: 10.1007/s11071-021-07062-2, DOI: 10.1109/ElConRus51938.2021.9396657
    
    properties
        Solver %example of class rk_solver for simulating the system with fixed step
        Param_name %name of bifurcation
        Peaks %array of peaks 
        Intervals %array of intervals
        Freq_Data %data for spectral analysis
        Fun %ODE for analysis
        LLE %array of largest Lyapulov exponent values
        N_peak_values %number of peaks stored in memory for each time series
        Param_Vals %array of bifurcation parameter values
        Freqs %array of frequencies in spectral analysis
        UserAnalysisFunction %handle to user function which is applies for time-series analysis and returns a scalar
        UserAnalysisResultsArray %array of values of user analysis function
    end

    methods
        function obj = bifurcation_1d_analyzer(fun, h, Tmax, solver)
            %BIFURCATION_1D_ANALYZER Construct an instance of this class
            %   Detailed explanation goes here
            obj.Fun = fun;
            obj.N_peak_values = 250;
            if nargin < 4
                obj.Solver = rk_solver_expilcit('RK2');
            elseif ischar(solver) || isstring(solver)
                if strcmp(solver, 'RK4')
                    obj.Solver = rk_solver_expilcit('RK4');
                elseif strcmp(solver, 'Euler') || strcmp(solver, 'RK1') 
                    obj.Solver = rk_solver_expilcit('RK1');
                end
            else
                obj.Solver = solver;
            end
            obj.Solver.Ts = h;
            obj.Solver.Tmax = Tmax;
            obj.UserAnalysisFunction = [];

        end
        
        function [T,Y] = simulate(obj, initial_conditions, bif_param_val)
            % SIMULATE - run ODE solver to get time-series solution
            % initial_conditions - start poiint
            % bif_param_val - value of bifurcation parameter

            fun = @(t, Y)obj.Fun(t, Y, bif_param_val);
            [T, Y] = obj.Solver.run(fun, initial_conditions);
        end
        
        function h_fig = plot_phase_portrait(obj, initial_conditions, bif_param_val, var_idx, var_names, fig)
            % PLOT_PHASE_PORTRAIT - visualize attractor
            fun = @(t,y) obj.Fun(t,y,bif_param_val);
            [~, Y, lam] = sim_n_lyap(obj, fun, initial_conditions, var_idx(1));
%             [~, Y] = simulate(obj, initial_conditions, bif_param_val);
            obj.LLE = lam;
            %get off transient
            Lstab = round(0.3 * size(Y, 2)):size(Y, 2);
            Y = Y(:,Lstab);
            if nargin < 6
                h_fig = figure;
            else
                figure(fig);
                hold on;
            end
            if length(var_idx) == 2
                plot(Y(var_idx(1),:), Y(var_idx(2),:));
                grid on
                obj.setAxesLabels(var_names{1}, var_names{2});
            else
                plot3(Y(var_idx(1),:), Y(var_idx(2),:), Y(var_idx(3),:));
                grid on
                obj.setAxesLabels(var_names{1}, var_names{2}, var_names{3});
            end
        end
        
        function plot_time_series(obj, initial_conditions, bif_param_val, var_idx, var_names)
            % PLOT_TIME_SERIES - run simulation and show waveforms for state variables
            % defined in var_idx
            [T, Y] = simulate(obj, initial_conditions, bif_param_val);

            %get off transient
%             Lstab = round(0.3 * size(Y, 2)):size(Y, 2);
%             Y = Y(:,Lstab);
%             T = T(:,Lstab);
            figure;
            hold on;
            for i=1:length(var_idx)
                plot(T, Y(var_idx(i),:));
            end
            lgn = legend(var_names);
            set(lgn,'Interpreter','latex');
            grid on
            obj.setAxesLabels('Time \, (s)', 'Amplitude');
        end
        
        function Yend = fast_run(obj, var_idx, PVals, initial_conditions, continuation_flag)
            % FAST_RUN - bifurcation analysis of the system
            % Find only peaks and intervals for ordinary and density bifurcation diagrams.
            if nargin < 5
                continuation_flag = 0;
            end
            param_vals = PVals;
            obj.Param_Vals = PVals;
            N_pts_bif = obj.N_peak_values;
            i = 1;
            
            PEAKS = zeros(length(param_vals), N_pts_bif);
            LOCS = PEAKS;
            wb = waitbar(0, 'Calculating bifurcation diagram data...');

            if ~isempty(obj.UserAnalysisFunction)
                [~, Y] = obj.simulate(initial_conditions, param_vals(1));
                tmp = feval(obj.UserAnalysisFunction, Y(var_idx(1),:));
                sz = size(tmp);
                obj.UserAnalysisResultsArray = zeros(length(param_vals), max(sz));
            end
            % main cycle
            for x = param_vals

                waitbar(i/length(param_vals));
                [~, Y] = obj.simulate(initial_conditions, x);
                
                if continuation_flag
                    initial_conditions = Y(:,end);
                end

                %get off transient
                Lstab = [round(0.3 * size(Y, 2)):size(Y, 2)];
                Y = Y(:,Lstab);

                [peakLocr, peakMagr] = peakfinder(Y(var_idx(1),:), 0.01);
                %крайние пики исключаем
                peakMagr = peakMagr(12:(length(peakMagr)-1));
                peakLocr = peakLocr(12:(length(peakLocr)-1));

                Lpm = length(peakMagr);
                if Lpm <  N_pts_bif
                    tmp = zeros(1, N_pts_bif - Lpm);
                    PEAKS(i,:) = [peakMagr, tmp];
                    LOCS(i,:) = [peakLocr, tmp];
                else
                    PEAKS(i,:) = obj.reduce_num_of_peaks(peakMagr, N_pts_bif); %delete peaks that are very close to each other
                    LOCS(i,:) = peakLocr(1:N_pts_bif); %leave only first N_pts_bif locations
                end

                % add user-defined function output
                if ~isempty(obj.UserAnalysisFunction)
                    tmp = feval(obj.UserAnalysisFunction, Y(var_idx(1),:));
                    sz = size(tmp);
                    if sz(1) == sz(2) && sz(1) == 1
                        obj.UserAnalysisResultsArray(i) = tmp;
                    else
                        if sz(1) == 1
                            obj.UserAnalysisResultsArray(i, :) = tmp;
                        else
                            obj.UserAnalysisResultsArray(i, :) = tmp';
                        end
                    end
                end
                %
                i = i + 1;
            end
            close(wb);
            obj.Peaks = PEAKS; %array of peaks 
            obj.Intervals = LOCS; %array of intervals
            Yend = Y(:, end);
        end
        
        function Yend = run(obj, var_idx, PVals, initial_conditions)
            % RUN - execute bifurcation analysis of the system, with no
            % visualization
            % var_idx - index(ex) of variable(s) under investigation. If numel(var_idx) >= 2, attractor is visualized

            param_vals = PVals;
            obj.Param_Vals = PVals;
            N_pts_bif = obj.N_peak_values;
            h = obj.Solver.Ts;
            Tmax = obj.Solver.Tmax;

            N_ex = length(param_vals);
            
            N_pts = 2^9 + 1;
            C = zeros(N_ex, N_pts);
            lam = zeros(1, N_ex); 
            f0 = 0.0001/h;
            f1 = 0.1/h;
            i = 1;
            
            PEAKS = zeros(length(param_vals), N_pts_bif);
            LOCS = PEAKS;
            f = obj.Fun;
            userFcn = [];
            tmpUserAnalysisResultsArray = [];
            if ~isempty(obj.UserAnalysisFunction)
                userFcn = @(x)obj.UserAnalysisFunction(x);
                [~, Y] = obj.simulate(initial_conditions, param_vals(1));
                res = obj.UserAnalysisFunction(Y(var_idx(1),:));
                sz = size(res);
                if sz(1) > 1
                    userFcn = @(x)userFcn(x)';
                end
                obj.UserAnalysisResultsArray = zeros(length(param_vals), max(sz));
                tmpUserAnalysisResultsArray = obj.UserAnalysisResultsArray;
            end
            % main cycle

            siml = @(fun)obj.sim_n_lyap(fun, initial_conditions, var_idx(1));
            reduce_peaks = @(peaks)obj.reduce_num_of_peaks(peaks, N_pts_bif);
            Yend = zeros(length(initial_conditions), N_pts_bif);
            xFs = [];
             wb = waitbar(0, 'Calculating bifurcation diagram data...');
%             WaitMessage = parfor_wait(N_ex, 'Waitbar', true);
            %parfor i = 1:N_ex
            for i = 1:N_ex

                waitbar(i/length(param_vals));
%                 WaitMessage.Send;
                x = param_vals(i);
                fun = @(t, Y)f(t, Y, x);
                [T, Y, lyap] = obj.sim_n_lyap(fun, initial_conditions, var_idx(1));
                %[~, Y, lyap] = siml(fun);
                
                lam(i) = lyap;
                %get off transient
                Lstab = [round(0.3 * size(Y, 2)):size(Y, 2)];
                Y = Y(:,Lstab);
                
                [peakLocr, peakMagr] = peakfinder(Y(var_idx(1),:), 0.01);
                %крайние пики исключаем
                peakMagr = peakMagr(12:(length(peakMagr)-1));
                peakLocr = peakLocr(12:(length(peakLocr)-1));

                Lpm = length(peakMagr);
                if Lpm <  N_pts_bif
                    tmp = zeros(1, N_pts_bif - Lpm);
                    PEAKS(i,:) = [peakMagr, tmp];
                    LOCS(i,:) = [peakLocr, tmp];
                else
                    PEAKS(i,:) = reduce_peaks(peakMagr); %delete peaks that are very close to each other
                    LOCS(i,:) = peakLocr(1:N_pts_bif); %leave only first N_pts_bif locations
                end

                try
                    [C(i,:), xFs] = pwelchmap(Y(var_idx(1),:), 1/h, f0, f1, N_pts);
                catch
                    C(i,:) = zeros(1, N_pts);
                end
                % add user-defined function output
                if ~isempty(userFcn)
                    tmp = userFcn(Y(var_idx(1),:));
%                     sz = size(tmp);
%                     if sz(1) == sz(2) && sz(1) == 1
%                        tmpUserAnalysisResultsArray(i) = tmp;
%                     else
%                         if sz(1) == 1
                            tmpUserAnalysisResultsArray(i, :) = tmp;
%                         else
%                             tmpUserAnalysisResultsArray(i, :) = tmp';
%                         end
%                     end
                end
                %
                Yend(:,i) =  Y(:, end);
            end
             close(wb);
%             WaitMessage.Destroy;
            obj.UserAnalysisResultsArray = tmpUserAnalysisResultsArray;
            obj.LLE = lam;
            obj.Peaks = PEAKS; %array of peaks 
            obj.Intervals = LOCS; %array of intervals
            obj.Freq_Data = C;
            obj.Freqs = xFs;
            
            Yend = Yend(end);
        end
        
        function get_continuation_bifurcation_diagram(obj, var_idx, PVals, initial_conditions, PName, VarName)
            %GET_CONTINUATION_BIFURCATION_DIAGRAM - execute fast_run twice in two 
            %       directions of bifurcation parameter increment/decrement,
            %       transferring last simulation point as initial condition for the
            %       next run. This type of analysis used to reveal multistability of ODE.
            %       var_idx - index of ODE state variable to be analyzed
            %       PVals - array of bifurcation parameter values
            %       initial_conditions - start point for simulation
            %       PName - name of bifurcation parameter to plot on
            %       horizontal axis
            %       VarName - name of ODE state variable to plot on
            %       vertical axis
            continuation_flag = 1;
            colors = {[0 0.4470 0.7410], [0.8500 0.3250 0.0980]};
            Y = fast_run(obj, var_idx, PVals, initial_conditions, continuation_flag);
            figure_id = figure;
            plot_bifurcation_diagram(obj, PName, VarName, colors{1}, figure_id);

            mx = max(max(obj.Peaks));
            mn = min(min(obj.Peaks));
            ypos = [(mx - mn)*0.9; (mx - mn)*0.8];
            tx = text(0.5*(PVals(1) + PVals(end)), ypos(1), 'Direction $\rightarrow$');
            set(tx, 'Interpreter', 'latex');
            set(tx, 'Color', colors{1});

            fast_run(obj, var_idx, flip(PVals), Y, continuation_flag);
            plot_bifurcation_diagram(obj, PName, VarName, colors{2}, figure_id);
            tx = text(0.5*(PVals(1) + PVals(end)), ypos(2), 'Direction $\leftarrow$');
            set(tx, 'Interpreter', 'latex');
            set(tx, 'Color', colors{2});
            title('Continuation Bifurcation Diagram', 'Interpreter','latex')
        end
        
        function plot_density_bifurcation_diagram(obj, PName, VarName)
            %PLOT_DENSITY_BIFURCATION_DIAGRAM - black/white bifurcation
            %diagram with points, transparency of which indicate of how
            %many trajectories are passing through their neighborhood
            PEAKS = obj.Peaks;
            param_vals = obj.Param_Vals;
            N_ex = length(param_vals);
            S_low = min(min(PEAKS));
            S_up  = max(max(PEAKS));
            spaces = linspace(S_low, S_up, obj.N_peak_values);

            BIF = obj.get_density_data();
            figure;
            hold on
            for i = 1:N_ex
                LB = (BIF(i,:));
                density =  LB/max(LB);
                s = scatter(param_vals(i) * ones(1, obj.N_peak_values), spaces, 2, 'filled');
                s.AlphaData = density;
                s.MarkerFaceAlpha = 'flat';
                s.MarkerFaceColor = [0 0 0];
            end
            obj.setAxesLabels(PName, VarName);
            title('Density \, Bifurcation \, Diagram', 'Interpreter','latex')
        end

        function h_figure = plot_bifurcation_diagram(obj, PName, VarName, color, h_fig)
            %PLOT_BIFURCATION_DIAGRAM - plot standard bifurcation
            %diagram

            param_vals = obj.Param_Vals;
            PEAKS = obj.Peaks;     

            if nargin < 4
                color = [0 0 0];
            end
            if nargin < 5
                h_figure = figure;
            else
                figure(h_fig);
            end
            hold on

            for i = 1:length(param_vals)

                pks = PEAKS(i,:);
                idx = find(pks ~= 0);
                s = scatter(param_vals(i) * ones(1, length(idx)), pks(idx), 1, 'filled');
                s.MarkerFaceColor = color;
            end
            obj.setAxesLabels(PName, VarName);
            title('Bifurcation \, Diagram', 'Interpreter','latex')
        end
        
        function plot_density_colored_bifurcation_diagram(obj, PName, VarName)
            %PLOT_DENSITY_COLORED_BIFURCATION_DIAGRAM - colored bifurcation
            %diagram with points, color of which indicate of how
            %many trajectories are passing through their neighborhood
            param_vals = obj.Param_Vals;
            BIF = obj.get_density_data();
            PEAKS = obj.Peaks;            
            S_low = min(min(PEAKS));
            S_up  = max(max(PEAKS));
            spaces = linspace(S_low, S_up, obj.N_peak_values);

             %% colored bif diagram plotting
            figure;
            imagesc(param_vals, spaces, BIF');
            set(gca,'YDir','normal')
            colormap('jet')
%             cbh = colorbar;
            obj.setAxesLabels(PName, VarName);
            title('Density \, Colored \, Bifurcation \, Diagram', 'Interpreter','latex')
        end
        
        function plot_interpeak_diagram(obj, PName, VarName, nBins)
            %PLOT_INTERPEAK_DIAGRAM - colored bifurcation
            %diagram with distances of peaks at vertical axis. Used
            %primarly to visualize dynamics of spiking neurons and other
            %systems with nearly constant amplitude, but diverse phase
            LOCS = obj.Intervals;
            param_vals = obj.Param_Vals;
            N_ex = length(param_vals);
            h = obj.Solver.Ts;

            %% interspike diagram
            figure;
            if nargin < 4
                nBins = 40;
            end
            C = zeros(N_ex, nBins);
            dTmax = 0;
            dTmin = 1e9;
            for i = 1:N_ex
                dT = diff(LOCS(i,:));
                tmp = max(dT);
                if tmp > dTmax
                    dTmax = tmp;
                end
                idx = find(dT > 0);
                tmp = min(dT(idx));
                if tmp < dTmin
                    dTmin = tmp;
                end
            end
            edges = linspace(dTmin, dTmax, nBins);
            for i = 1:N_ex
                dT = diff(LOCS(i,:));
                idx = find(dT > 0);
                c = hist(dT(idx), edges);
                C(i,:) = c;
            end
            imagesc(param_vals, edges * h, C');
            set(gca,'YDir','normal') 
            colormap jet;
            hcb=colorbar;
            hcb.Label.String = 'N \, entries';
            hcb.TickLabelInterpreter = 'latex';
            hcb.Label.Interpreter = 'latex';
            obj.setAxesLabels(PName, ['\Delta T \, ', VarName, ' \, (sec)']);
            title('Inter-peak \, Bifurcation \, Diagram', 'Interpreter','latex')
        end
        
        function plot_spectral_bifurcation_diagram(obj, PName)
            %% frequency plot
            figure;
            imagesc(obj.Param_Vals, obj.Freqs/1e3, obj.Freq_Data');
            set(gca,'YDir','normal')
            
            obj.setAxesLabels(PName, 'f, kHz');
            colormap jet
            hcb=colorbar;
            hcb.Label.String = 'Power, dB';
            hcb.TickLabelInterpreter = 'latex';
            hcb.Label.Interpreter = 'latex';
            title('Spectral \, Bifurcation \, Diagram', 'Interpreter','latex')
        end
        
        function plot_all(obj, PName, VarName)
        %   PLOT_ALL - execute after run/fast_run to
        %       visualize all availible types of plots
            plot_density_bifurcation_diagram(obj, PName, VarName);
            plot_density_colored_bifurcation_diagram(obj, PName, VarName);
            plot_bifurcation_diagram(obj, PName, VarName);
            plot_interpeak_diagram(obj, PName, VarName);
            plot_spectral_bifurcation_diagram(obj, PName);

            figure
            plot(obj.Param_Vals, obj.LLE);
            obj.setAxesLabels(PName, 'LLE');
            title('Largest \, Lyapunov \, Exponent', 'Interpreter','latex')
            grid on
                        
        end

    end
    methods (Access = 'private')

        function BIF = get_density_data(obj)
            PEAKS = obj.Peaks;
            param_vals = obj.Param_Vals;
            N_ex = length(param_vals);
            h = obj.Solver.Ts;

            S_low = min(min(PEAKS));
            S_up  = max(max(PEAKS));
            spaces = linspace(S_low, S_up, obj.N_peak_values);
            BIF = zeros(N_ex, obj.N_peak_values);
            for i=1:N_ex
                %Compute frequency for each interval
                
                idx = find(PEAKS(i,:) ~= 0);
                tmp2 = nnz(PEAKS(i,:));
                if tmp2 == 0
                    tmp2 = 1;
                end
                BIF(i,:) = hist(PEAKS(i, idx), spaces)./tmp2; %frequency percentage
            end
        end

        function setAxesLabels(obj, x_label, y_label, z_label)
            xlabel(['$',x_label,'$'],'interpreter','latex','FontSize',13);
            ylabel(['$',y_label,'$'],'interpreter','latex','FontSize',13);
            if nargin > 3
                zlabel(['$',z_label,'$'],'interpreter','latex','FontSize',13);
            end
            set(gca,'TickLabelInterpreter','latex','FontSize',11);
            
        end
            
         function pts = reduce_num_of_peaks(obj, peaks, N_max)
                pts = [];
                eps_range = 10;
                flag = 1;
                while(flag)
                    eps = (max(peaks) - min(peaks)) / N_max / eps_range;
                    for i = 1:length(peaks)
                        flag_2 = 1;
                        for j = 1:length(pts)
                            if (abs(peaks(i) - pts(j)) < eps) && (peaks(i) ~= pts(j))
                                flag_2 = 0;
                                break;
                            end
                        end
                        if flag_2
                            pts = [pts, peaks(i)];
                        end
                    end
                    L = length(pts);
                    if L < N_max
                        flag = 0;
                        pts = [pts, zeros(1, N_max - L)];
                    else
                        peaks = pts;
                        pts = [];
                        eps_range = eps_range / 2;
                    end
                end
         end
         function [T, Y, lyap] = sim_n_lyap(obj, fun, initial_conditions, dim)
            %fun - ODE
            %solver - RK solver
            % Tmax - simulation time
            % initial_conditions
            % h - simulation step
            % dim - lyapunov test dimension. If omitted, dim = 1;
            if nargin < 4
                dim = 1;
            end
            solver = obj.Solver;
            Tmax = obj.Solver.Tmax;
            h = obj.Solver.Ts;
                eps = 1e-10;
                dIC = 0 * initial_conditions;    
                dIC(dim) = eps;
                [T, Y] = solver.solve(fun, Tmax, initial_conditions, h);
                [T, Y2] = solver.solve(fun, Tmax, initial_conditions + dIC, h);
                %check maximal lyapunov exponent
            
                e = abs(Y - Y2);
                ef = medfilt1(e(dim,:), 20);
            
%                 hold off;
%                 figure
%                 semilogy(T, ef); 
%                 xlabel('time')
%                 ylabel('Y_{ic2} - Y_{ic1}')
%                 T1 = h; 
                
                %find one crossing
                ids = find(ef > mean(abs(Y(dim,:)))/2);
                
                if ~isempty(ids)
                    V1 = ef(2); 
                    T2 = T(ids(1)); V2 = ef(ids(1)); 
%                     hold on; 
%                     plot(T1, V1, 'o');
%                     plot(T2, V2, 'o');
                    lyap = (log(V2) - log(V1))/T2;
                else
            %         lyap = 0;
                    V1 = ef(2);
                    V2 = ef(end);
                    T2 = T(end);
                    if V2 > V1
                        lyap = (log(V2) - log(V1))/T2;
                    else
                        lyap = 0;
                    end
                end
%                 hold on
%                 plot([T1 T2], [(V1) (V2)]); 
         end
    end
end

