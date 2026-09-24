% Manuscript code distribution. See docs/REPRODUCIBILITY_STATUS.md.
function fig = DT_plotout(out,expdata)
% This function plots the output of the model
% Input:
% out is a structure containing the output of the model
% expdata is a structure containing the experimental data
% Output:
% fig is a figure handle
% plot 2x2 subplot, top left is VCD, top right is Glucose, bottom left is Lactate, bottom right is mAb
% each plot has two lines, one for simulation and one for experiment

% Author: Zhao Wang, UMass Lowell, zhao_wang@student.uml.edu,2025
arguments
    out
    expdata
end

% Set error margin to 10%
err_margin = 0.10;
band_color = [0.2 0.4 0.8]; % Nice professional blue for the band
alpha_val = 0.15;           % Transparency of the band (15%)

figure('Position',[100 100 1200 800]);

%% Subplot 1: VCD
subplot(2,2,1);
hold on; grid on;
% Extract valid time index and data
idx = (expdata.Xv.Time < seconds(out.bioreactor.conc.Xv.Time(end)));
t_exp = seconds(expdata.Xv.Time(idx));
y_exp = expdata.Xv.Var1(idx);
% Calculate and plot 10% error band
y_err = y_exp * err_margin;
x_fill = [t_exp(:); flip(t_exp(:))];
y_fill = [y_exp(:) + y_err(:); flip(y_exp(:) - y_err(:))];
fill(x_fill, y_fill, band_color, 'FaceAlpha', alpha_val, 'EdgeColor', 'none', 'HandleVisibility', 'off');

% Plot data
plot(out.bioreactor.conc.Xv.time, out.bioreactor.conc.Xv.data, 'r', 'LineWidth', 1.5, 'DisplayName', 'Simulation');
plot(t_exp, y_exp, 'b', 'LineWidth', 1.5, 'DisplayName', 'Experiment');

ylabel('VCD (e6 cells/mL)');
xlabel('Time (h)');
legend('Location', 'best');
title('VCD');

%% Subplot 2: Glucose
subplot(2,2,2);
hold on; grid on;

idx = (expdata.Glc.Time < seconds(out.bioreactor.conc.Glc.Time(end)));
t_exp = seconds(expdata.Glc.Time(idx));
y_exp = expdata.Glc.Var1(idx);

y_err = y_exp * err_margin;
x_fill = [t_exp(:); flip(t_exp(:))];
y_fill = [y_exp(:) + y_err(:); flip(y_exp(:) - y_err(:))];
fill(x_fill, y_fill, band_color, 'FaceAlpha', alpha_val, 'EdgeColor', 'none', 'HandleVisibility', 'off');

plot(out.bioreactor.conc.Glc.time, out.bioreactor.conc.Glc.data, 'r', 'LineWidth', 1.5, 'DisplayName', 'Simulation');
plot(t_exp, y_exp, 'b', 'LineWidth', 1.5, 'DisplayName', 'Experiment');

ylabel('Glucose (g/L)');
xlabel('Time (h)');
legend('Location', 'best');
title('Glucose');

%% Subplot 3: Lactate
subplot(2,2,3);
hold on; grid on;

idx = (expdata.Lac.Time < seconds(out.bioreactor.conc.Lac.Time(end)));
t_exp = seconds(expdata.Lac.Time(idx));
y_exp = expdata.Lac.Var1(idx);

y_err = y_exp * err_margin;
x_fill = [t_exp(:); flip(t_exp(:))];
y_fill = [y_exp(:) + y_err(:); flip(y_exp(:) - y_err(:))];
fill(x_fill, y_fill, band_color, 'FaceAlpha', alpha_val, 'EdgeColor', 'none', 'HandleVisibility', 'off');

plot(out.bioreactor.conc.Lac.time, out.bioreactor.conc.Lac.data, 'r', 'LineWidth', 1.5, 'DisplayName', 'Simulation');
plot(t_exp, y_exp, 'b', 'LineWidth', 1.5, 'DisplayName', 'Experiment');

ylabel('Lactate (g/L)');
xlabel('Time (h)');
legend('Location', 'best');
title('Lactate');

%% Subplot 4: mAb
subplot(2,2,4);
hold on; grid on;

idx = (expdata.mAb.Time < seconds(out.bioreactor.conc.mAb.Time(end)));
t_exp = seconds(expdata.mAb.Time(idx));
y_exp = expdata.mAb.Var1(idx);

y_err = y_exp * err_margin;
x_fill = [t_exp(:); flip(t_exp(:))];
y_fill = [y_exp(:) + y_err(:); flip(y_exp(:) - y_err(:))];
fill(x_fill, y_fill, band_color, 'FaceAlpha', alpha_val, 'EdgeColor', 'none', 'HandleVisibility', 'off');

plot(out.bioreactor.conc.mAb.time, out.bioreactor.conc.mAb.data, 'r', 'LineWidth', 1.5, 'DisplayName', 'Simulation');
plot(t_exp, y_exp, 'b', 'LineWidth', 1.5, 'DisplayName', 'Experiment');

ylabel('mAb (g/L)');
xlabel('Time (h)');
legend('Location', 'best');
title('mAb');
end
