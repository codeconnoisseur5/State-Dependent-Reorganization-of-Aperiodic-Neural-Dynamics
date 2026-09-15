%% Prior to executing this code, please first create the corresponding protocol in Brainstorm and add the participant subjects.

clear;clc
path_protocol = '/Users/.....';
cond_name = 'EO';
subj_names = dir([path_protocol, filesep, 'subject*']);


for i = 1:length(subj_names)
    subj_files = dir([path_protocol, filesep, subj_names(i).name, filesep, cond_name, filesep, 'data*']);
    sFiles = append([subj_names(i).name, filesep, cond_name, filesep], {subj_files.name});
    bst_report('Start', sFiles);
    sFiles = bst_process('CallProcess', 'process_fft', sFiles, [], ...
        'timewindow',  [], ...
        'units',       'physical', ...  % Physical: U2/Hz
        'sensortypes', 'MEG, EEG', ...
        'avgoutput',   1);
    
    % Process: specparam: Fitting oscillations and 1/f
    sFiles = bst_process('CallProcess', 'process_fooof', sFiles, [], ...
        'implementation', 'matlab', ...  % Matlab
        'freqrange',      [1, 40], ...
        'powerline',      '-5', ...  % None
        'method',         'leastsquare', ...  % Default
        'peakwidth',      [1, 40], ...
        'maxpeaks',       3, ...
        'minpeakheight',  3, ...
        'proxthresh',     5, ...
        'apermode',       'fixed', ...  % Fixed
        'guessweight',    'weak', ...  % Weak
        'sorttype',       'param', ...  % Peak parameters
        'sortparam',      'frequency', ...  % Frequency
        'sortbands',      {});
    
end

%% Summarize the FOOOF calculation results

data_csv0 = {'subjnames'};  %  
data_csv1 = {};
data_csv2 = {};
data_csv3 = {};

for i = 1:length(subj_names)

    FOOOF_file = dir([path_protocol, filesep, subj_names(i).name, filesep, cond_name, filesep, '*specparam.mat']);
    copyfile([path_protocol, filesep, subj_names(i).name, filesep, cond_name, filesep, FOOOF_file.name], [subj_names(i).name, '_', FOOOF_file.name])
    sub_fooof = load([subj_names(i).name, '_', FOOOF_file.name]);
    data_csv0 = vertcat(data_csv0, [subj_names(i).name, '_', FOOOF_file.name]);
    
    % aperiodic
    data_csv1 = vertcat(data_csv1, {sub_fooof.Options.FOOOF.aperiodics.offset});
    data_csv2 = vertcat(data_csv2, {sub_fooof.Options.FOOOF.aperiodics.exponent});
    
    % periodic
    data_csv3 = vertcat(data_csv3, {sub_fooof.Options.FOOOF.data.peak_params});
    date_csv3 = cellfun(@(x) reshape(x',1,[]), data_csv3, 'UniformOutput', false);
    

    f_idx = find(ismember(sub_fooof.Freqs, sub_fooof.Options.FOOOF.freqs));

    group_PSD_raw(i,:,:) = 10*log10(squeeze(sub_fooof.TF(:,:,f_idx)));
    group_PSD_pe(i,:,:) = 10*log10(cat(1,sub_fooof.Options.FOOOF.data.peak_fit));
    group_PSD_ape(i,:,:) = 10*log10(cat(1,sub_fooof.Options.FOOOF.data.ap_fit));
    group_PSD_fooof(i,:,:) = 10*log10(cat(1,sub_fooof.Options.FOOOF.data.fooofed_spectrum));

end

table_csv1 = horzcat(data_csv0, vertcat(sub_fooof.RowNames, data_csv1));
table_csv2 = horzcat(data_csv0, vertcat(sub_fooof.RowNames, data_csv2));
table_csv3 = horzcat(data_csv0, vertcat(sub_fooof.RowNames, date_csv3));

writecell(table_csv1, 'ape_offest.csv')
writecell(table_csv2, 'ape_exponent.csv')
writecell(table_csv3, 'pe_peak_prarms.csv')

freqs = sub_fooof.Options.FOOOF.freqs;
save group_PSD.mat group_PSD_raw group_PSD_pe group_PSD_ape group_PSD_fooof freqs

%% FOOOF Visualization
clear;clc
load group_PSD4.mat

chan = 22;

figure
nexttile
y = squeeze(mean(group_PSD_raw(:,chan,:),1));
plot(freqs, y)
xlim([freqs(1), freqs(end)])
legend('PSD')
nexttile
hold on
y1 = squeeze(mean(group_PSD_fooof(:,chan,:),1));
y2 = squeeze(mean(group_PSD_ape(:,chan,:),1));
plot(freqs, y1)
plot(freqs, y2,'--')
fill([freqs, flip(freqs)], [y1; flip(y2)], 'g', 'FaceAlpha', 0.3, 'LineStyle','none');
xlim([freqs(1), freqs(end)])
legend('Final model fit', 'Aperiodic fit', 'Periodic activity')
nexttile
y3 = squeeze(mean(group_PSD_pe(:,chan,:),1));
plot(freqs, y3)
xlim([freqs(1), freqs(end)])
legend('Aperiodic removed spetra')

%%
clear; clc

font_name = 'Arial';
font_size_labels = 11;
font_size_ticks = 10;
font_size_title = 12;
font_size_legend = 10;
line_width = 2;
dashed_width = 1.8;
dashed_style = '--';
fill_alpha = 0.25;


color_nh_ec = [0, 0.45, 0.74];     % Normal Hearing 
color_hi_ec = [0.85, 0.33, 0.1];   % Hearing Impaired 
color_nh_eo = [0.5, 0.5, 0.5];     % Normal Hearing
color_hi_eo = [0.7, 0.7, 0.7];     % Hearing Impaired 

color_fill_nh_ec = [0.7, 0.8, 0.9];    %  
color_fill_hi_ec = [0.95, 0.8, 0.7];   %  
color_fill_nh_eo = [0.85, 0.85, 0.85]; %  
color_fill_hi_eo = [0.9, 0.9, 0.9];    %  

chan = 22;

y_limits_psd = [-118, -98];

%% Data Loading - Normal Hearing Group
% Normal Hearing - EC
load('group_PSD_NH_EC.mat');
freqs_nh_ec = freqs;

y_fooof_nh_ec = squeeze(mean(group_PSD_fooof(:,chan,:),1));
y_ape_nh_ec = squeeze(mean(group_PSD_ape(:,chan,:),1));

if size(y_fooof_nh_ec, 2) > 1, y_fooof_nh_ec = y_fooof_nh_ec'; end
if size(y_ape_nh_ec, 2) > 1, y_ape_nh_ec = y_ape_nh_ec'; end
if size(freqs_nh_ec, 2) > 1, freqs_nh_ec = freqs_nh_ec'; end

% Normal Hearing - EO
load('group_PSD_NH_EO.mat');
freqs_nh_eo = freqs;

y_fooof_nh_eo = squeeze(mean(group_PSD_fooof(:,chan,:),1));
y_ape_nh_eo = squeeze(mean(group_PSD_ape(:,chan,:),1));

if size(y_fooof_nh_eo, 2) > 1, y_fooof_nh_eo = y_fooof_nh_eo'; end
if size(y_ape_nh_eo, 2) > 1, y_ape_nh_eo = y_ape_nh_eo'; end
if size(freqs_nh_eo, 2) > 1, freqs_nh_eo = freqs_nh_eo'; end

%% Data Loading - Hearing Impaired Group
% Hearing Impaired - EC
load('group_PSD_HI_EC.mat');
freqs_hi_ec = freqs;

y_fooof_hi_ec = squeeze(mean(group_PSD_fooof(:,chan,:),1));
y_ape_hi_ec = squeeze(mean(group_PSD_ape(:,chan,:),1));

if size(y_fooof_hi_ec, 2) > 1, y_fooof_hi_ec = y_fooof_hi_ec'; end
if size(y_ape_hi_ec, 2) > 1, y_ape_hi_ec = y_ape_hi_ec'; end
if size(freqs_hi_ec, 2) > 1, freqs_hi_ec = freqs_hi_ec'; end

% Hearing Impaired - EO
load('group_PSD_HI_EO.mat');
freqs_hi_eo = freqs;

y_fooof_hi_eo = squeeze(mean(group_PSD_fooof(:,chan,:),1));
y_ape_hi_eo = squeeze(mean(group_PSD_ape(:,chan,:),1));

if size(y_fooof_hi_eo, 2) > 1, y_fooof_hi_eo = y_fooof_hi_eo'; end
if size(y_ape_hi_eo, 2) > 1, y_ape_hi_eo = y_ape_hi_eo'; end
if size(freqs_hi_eo, 2) > 1, freqs_hi_eo = freqs_hi_eo'; end

%% Normal Hearing (EC vs EO)
figure('Position', [100, 100, 850, 550], 'Color', 'w', 'InvertHardcopy', 'off')
set(gcf, 'DefaultAxesFontName', font_name)
set(gcf, 'DefaultTextFontName', font_name)

hold on


x_fill_nh_ec = [freqs_nh_ec; flipud(freqs_nh_ec)];
y_fill_nh_ec = [y_fooof_nh_ec; flipud(y_ape_nh_ec)];

x_fill_nh_eo = [freqs_nh_eo; flipud(freqs_nh_eo)];
y_fill_nh_eo = [y_fooof_nh_eo; flipud(y_ape_nh_eo)];


fill(x_fill_nh_ec, y_fill_nh_ec, color_fill_nh_ec, 'FaceAlpha', fill_alpha, 'EdgeColor', 'none')
fill(x_fill_nh_eo, y_fill_nh_eo, color_fill_nh_eo, 'FaceAlpha', fill_alpha*0.8, 'EdgeColor', 'none')


h1 = plot(freqs_nh_ec, y_fooof_nh_ec, 'Color', color_nh_ec, 'LineWidth', line_width);
h2 = plot(freqs_nh_ec, y_ape_nh_ec, 'LineStyle', dashed_style, 'Color', color_nh_ec, 'LineWidth', dashed_width);
h3 = plot(freqs_nh_eo, y_fooof_nh_eo, 'Color', color_nh_eo, 'LineWidth', line_width);
h4 = plot(freqs_nh_eo, y_ape_nh_eo, 'LineStyle', dashed_style, 'Color', color_nh_eo, 'LineWidth', dashed_width);

xlim([freqs_nh_ec(1), freqs_nh_ec(end)])
ylim(y_limits_psd)
box on
grid off


xlabel('Frequency (Hz)', 'FontSize', font_size_labels, 'FontWeight', 'normal')
ylabel('Power (dB)', 'FontSize', font_size_labels, 'FontWeight', 'normal')
title('Normal Hearing Group - FOOOF Model Decomposition', 'FontSize', font_size_title, 'FontWeight', 'bold')


ax = gca;
ax.FontSize = font_size_ticks;
ax.LineWidth = 1.2;
ax.TickDir = 'out';
ax.TickLength = [0.015, 0.015];
ax.XColor = [0.2, 0.2, 0.2];
ax.YColor = [0.2, 0.2, 0.2];


h_fill_nh_ec = fill([NaN, NaN], [NaN, NaN], color_fill_nh_ec, 'FaceAlpha', fill_alpha, 'EdgeColor', 'none');
h_fill_nh_eo = fill([NaN, NaN], [NaN, NaN], color_fill_nh_eo, 'FaceAlpha', fill_alpha*0.8, 'EdgeColor', 'none');
legend([h1, h2, h_fill_nh_ec, h3, h4, h_fill_nh_eo], ...
    {'EC - Full model', 'EC - Aperiodic', 'EC - Oscillatory', ...
     'EO - Full model', 'EO - Aperiodic', 'EO - Oscillatory'}, ...
    'Location', 'best', 'FontSize', font_size_legend, 'Box', 'off', 'NumColumns', 2)


saveas(gcf, 'FOOOF_Normal_Hearing_EC_EO.svg', 'svg')
print('FOOOF_Normal_Hearing_EC_EO', '-dsvg', '-r300')
close(gcf)

%% Hearing Impaired (EC vs EO)
figure('Position', [100, 100, 850, 550], 'Color', 'w', 'InvertHardcopy', 'off')
set(gcf, 'DefaultAxesFontName', font_name)
set(gcf, 'DefaultTextFontName', font_name)

hold on

x_fill_hi_ec = [freqs_hi_ec; flipud(freqs_hi_ec)];
y_fill_hi_ec = [y_fooof_hi_ec; flipud(y_ape_hi_ec)];

x_fill_hi_eo = [freqs_hi_eo; flipud(freqs_hi_eo)];
y_fill_hi_eo = [y_fooof_hi_eo; flipud(y_ape_hi_eo)];


fill(x_fill_hi_ec, y_fill_hi_ec, color_fill_hi_ec, 'FaceAlpha', fill_alpha, 'EdgeColor', 'none')
fill(x_fill_hi_eo, y_fill_hi_eo, color_fill_hi_eo, 'FaceAlpha', fill_alpha*0.8, 'EdgeColor', 'none')


h1 = plot(freqs_hi_ec, y_fooof_hi_ec, 'Color', color_hi_ec, 'LineWidth', line_width);
h2 = plot(freqs_hi_ec, y_ape_hi_ec, 'LineStyle', dashed_style, 'Color', color_hi_ec, 'LineWidth', dashed_width);
h3 = plot(freqs_hi_eo, y_fooof_hi_eo, 'Color', color_hi_eo, 'LineWidth', line_width);
h4 = plot(freqs_hi_eo, y_ape_hi_eo, 'LineStyle', dashed_style, 'Color', color_hi_eo, 'LineWidth', dashed_width);

xlim([freqs_hi_ec(1), freqs_hi_ec(end)])
ylim(y_limits_psd)
box on
grid off

xlabel('Frequency (Hz)', 'FontSize', font_size_labels, 'FontWeight', 'normal')
ylabel('Power (dB)', 'FontSize', font_size_labels, 'FontWeight', 'normal')
title('Hearing Impaired Group - FOOOF Model Decomposition', 'FontSize', font_size_title, 'FontWeight', 'bold')


ax = gca;
ax.FontSize = font_size_ticks;
ax.LineWidth = 1.2;
ax.TickDir = 'out';
ax.TickLength = [0.015, 0.015];
ax.XColor = [0.2, 0.2, 0.2];
ax.YColor = [0.2, 0.2, 0.2];


h_fill_hi_ec = fill([NaN, NaN], [NaN, NaN], color_fill_hi_ec, 'FaceAlpha', fill_alpha, 'EdgeColor', 'none');
h_fill_hi_eo = fill([NaN, NaN], [NaN, NaN], color_fill_hi_eo, 'FaceAlpha', fill_alpha*0.8, 'EdgeColor', 'none');
legend([h1, h2, h_fill_hi_ec, h3, h4, h_fill_hi_eo], ...
    {'EC - Full model', 'EC - Aperiodic', 'EC - Oscillatory', ...
     'EO - Full model', 'EO - Aperiodic', 'EO - Oscillatory'}, ...
    'Location', 'best', 'FontSize', font_size_legend, 'Box', 'off', 'NumColumns', 2)


saveas(gcf, 'FOOOF_Hearing_Impaired_EC_EO.svg', 'svg')
print('FOOOF_Hearing_Impaired_EC_EO', '-dsvg', '-r300')
close(gcf)

%%  
figure('Position', [100, 100, 900, 700], 'Color', 'w', 'InvertHardcopy', 'off')
set(gcf, 'DefaultAxesFontName', font_name)
set(gcf, 'DefaultTextFontName', font_name)

%  Normal Hearing
subplot(2, 1, 1)
hold on


x_fill_nh_ec = [freqs_nh_ec; flipud(freqs_nh_ec)];
y_fill_nh_ec = [y_fooof_nh_ec; flipud(y_ape_nh_ec)];
x_fill_nh_eo = [freqs_nh_eo; flipud(freqs_nh_eo)];
y_fill_nh_eo = [y_fooof_nh_eo; flipud(y_ape_nh_eo)];


fill(x_fill_nh_ec, y_fill_nh_ec, color_fill_nh_ec, 'FaceAlpha', fill_alpha, 'EdgeColor', 'none')
fill(x_fill_nh_eo, y_fill_nh_eo, color_fill_nh_eo, 'FaceAlpha', fill_alpha*0.8, 'EdgeColor', 'none')


h1 = plot(freqs_nh_ec, y_fooof_nh_ec, 'Color', color_nh_ec, 'LineWidth', line_width);
h2 = plot(freqs_nh_ec, y_ape_nh_ec, 'LineStyle', dashed_style, 'Color', color_nh_ec, 'LineWidth', dashed_width);
h3 = plot(freqs_nh_eo, y_fooof_nh_eo, 'Color', color_nh_eo, 'LineWidth', line_width);
h4 = plot(freqs_nh_eo, y_ape_nh_eo, 'LineStyle', dashed_style, 'Color', color_nh_eo, 'LineWidth', dashed_width);

xlim([freqs_nh_ec(1), freqs_nh_ec(end)])
ylim(y_limits_psd)
box on
grid off
ylabel('Power (dB)', 'FontSize', font_size_labels, 'FontWeight', 'normal')
title('Normal Hearing Group', 'FontSize', font_size_title, 'FontWeight', 'bold')
ax = gca;
ax.FontSize = font_size_ticks;
ax.LineWidth = 1.2;
ax.TickDir = 'out';
ax.TickLength = [0.015, 0.015];
ax.XColor = [0.2, 0.2, 0.2];
ax.YColor = [0.2, 0.2, 0.2];
ax.XTickLabel = [];

% Hearing Impaired
subplot(2, 1, 2)
hold on


x_fill_hi_ec = [freqs_hi_ec; flipud(freqs_hi_ec)];
y_fill_hi_ec = [y_fooof_hi_ec; flipud(y_ape_hi_ec)];
x_fill_hi_eo = [freqs_hi_eo; flipud(freqs_hi_eo)];
y_fill_hi_eo = [y_fooof_hi_eo; flipud(y_ape_hi_eo)];


fill(x_fill_hi_ec, y_fill_hi_ec, color_fill_hi_ec, 'FaceAlpha', fill_alpha, 'EdgeColor', 'none')
fill(x_fill_hi_eo, y_fill_hi_eo, color_fill_hi_eo, 'FaceAlpha', fill_alpha*0.8, 'EdgeColor', 'none')


h5 = plot(freqs_hi_ec, y_fooof_hi_ec, 'Color', color_hi_ec, 'LineWidth', line_width);
h6 = plot(freqs_hi_ec, y_ape_hi_ec, 'LineStyle', dashed_style, 'Color', color_hi_ec, 'LineWidth', dashed_width);
h7 = plot(freqs_hi_eo, y_fooof_hi_eo, 'Color', color_hi_eo, 'LineWidth', line_width);
h8 = plot(freqs_hi_eo, y_ape_hi_eo, 'LineStyle', dashed_style, 'Color', color_hi_eo, 'LineWidth', dashed_width);

xlim([freqs_hi_ec(1), freqs_hi_ec(end)])
ylim(y_limits_psd)
box on
grid off
xlabel('Frequency (Hz)', 'FontSize', font_size_labels, 'FontWeight', 'normal')
ylabel('Power (dB)', 'FontSize', font_size_labels, 'FontWeight', 'normal')
title('Hearing Impaired Group', 'FontSize', font_size_title, 'FontWeight', 'bold')
ax = gca;
ax.FontSize = font_size_ticks;
ax.LineWidth = 1.2;
ax.TickDir = 'out';
ax.TickLength = [0.015, 0.015];
ax.XColor = [0.2, 0.2, 0.2];
ax.YColor = [0.2, 0.2, 0.2];


h_fill_ec = fill([NaN, NaN], [NaN, NaN], color_fill_nh_ec, 'FaceAlpha', fill_alpha, 'EdgeColor', 'none');
h_fill_eo = fill([NaN, NaN], [NaN, NaN], color_fill_nh_eo, 'FaceAlpha', fill_alpha*0.8, 'EdgeColor', 'none');
lgd = legend([h1, h2, h_fill_ec, h3, h4, h_fill_eo], ...
    {'EC - Full model', 'EC - Aperiodic', 'EC - Oscillatory', ...
     'EO - Full model', 'EO - Aperiodic', 'EO - Oscillatory'}, ...
    'FontSize', font_size_legend-1, 'Box', 'off', 'NumColumns', 3, ...
    'Position', [0.3, 0.01, 0.4, 0.05], 'Orientation', 'horizontal');


saveas(gcf, 'FOOOF_Comparison_Summary.svg', 'svg')
print('FOOOF_Comparison_Summary', '-dsvg', '-r300')


disp('SVG：')
disp('1. FOOOF_Normal_Hearing_EC_EO.svg')
disp('2. FOOOF_Hearing_Impaired_EC_EO.svg')
disp('3. FOOOF_Comparison_Summary.svg')
disp(' ')
disp('color scheme：')
disp('  - Normal Hearing - EC')
disp('  - Hearing Impaired - EC')
disp('  - Normal Hearing - EO')
disp('  - Hearing Impaired - EO')
disp(' ')
disp('Graph Layout：')
disp('  Normal Hearing')
disp('  Hearing Impaired')
disp('  Summary Figure: Two-row, one-column comparison diagram')
disp(' ')
