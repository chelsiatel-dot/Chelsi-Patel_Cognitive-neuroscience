
%  Dependence of estimated metacognitive scores on metacognitive bias
%
%  Datasets:
%  1. Haddara
%  2. Maniscalco
%  3. Shekhar
%
%  Outputs:
%  - Separate Shekhar Figure 3A
%  - Combined Figure 3A
%  - Combined Figure 3B
%
%  IMPORTANT:
%  Shekhar's final plotted values use the author arrays saved in
%  Shekhar_author_arrays.mat, as in our previous analysis.
%  Independently calculated Shekhar values are retained separately.
%% ================================================================

clc;
close all;

%% 1. SET PROJECT FOLDER AND LOAD HELPER FUNCTIONS

projectFolder = pwd;
addpath(genpath(projectFolder));

fprintf('\nStarting Figure 3 analysis...\n');

%% 2. LOAD THE THREE ORIGINAL DATASETS

Haddara = load(fullfile(projectFolder, ...
    'Preprocess','dataset_Haddara_2022_Expt2.mat'));

Maniscalco = load(fullfile(projectFolder, ...
    'Preprocess','dataset_Maniscalco_2017_expt1.mat'));

Shekhar = load(fullfile(projectFolder, ...
    'Preprocess','dataset_Shekhar_2021.mat'));

fprintf('Original datasets loaded successfully.\n');

fprintf('Haddara participants: %d\n',length(Haddara.data));
fprintf('Maniscalco participants: %d\n',length(Maniscalco.data));
fprintf('Shekhar participants: %d\n',length(Shekhar.data));

%% 3. LOAD SHEKHAR AUTHOR ARRAYS

% These are the same author arrays used in final figures.
% They must be included with the project files.

authorFile = fullfile(projectFolder,'Shekhar_author_arrays.mat');

if ~isfile(authorFile)
    error(['Shekhar_author_arrays.mat is missing. ', ...
        'Save author_low and author_high from the original workspace ', ...
        'and place the MAT file in the project folder.']);
end

authorResults = load(authorFile);

if ~isfield(authorResults,'author_low') || ...
   ~isfield(authorResults,'author_high')
    error('The MAT file must contain author_low and author_high.');
end

author_low = authorResults.author_low;
author_high = authorResults.author_high;

if ~isequal(size(author_low),[20 3 20]) || ...
   ~isequal(size(author_high),[20 3 20])
    error('The Shekhar author arrays must both be 20 x 3 x 20.');
end

% Average across the three difficulty levels for each participant
author_low_avg = squeeze(mean(author_low,2));
author_high_avg = squeeze(mean(author_high,2));

fprintf('Shekhar author arrays loaded successfully.\n');

%% 4. INDEPENDENT SHEKHAR CALCULATIONS
%
% Calculate original, low-recoded and high-recoded measures
% separately for each participant and difficulty level.
%
% These independently calculated arrays are retained for comparison.
% The final Shekhar figures below continue to use author_low_avg
% and author_high_avg, as in our previous analysis.

edges = 50:50/6:100;

metas_original = NaN(20,3,20);
metas_low = NaN(20,3,20);
metas_high = NaN(20,3,20);

rng(1);

for p = 1:20

    d = Shekhar.data{p};

    conf6_all = discretize(d.conf,edges);

    for k = 1:3

        idx = d.contrast == k;

        stim = d.stim(idx);
        resp = d.resp(idx);
        conf = conf6_all(idx);

        metas_original(p,k,:) = reshape( ...
            compute_all_measures(stim,resp,conf,6),1,1,20);

        conf_low = xue_recode(conf,1);
        metas_low(p,k,:) = reshape( ...
            compute_all_measures(stim,resp,conf_low,5),1,1,20);

        conf_high = xue_recode(conf,2);
        metas_high(p,k,:) = reshape( ...
            compute_all_measures(stim,resp,conf_high,5),1,1,20);

    end
end

fprintf('Independent Shekhar calculations completed.\n');

%% 5. HADDARA: LOW AND HIGH CONFIDENCE RECODING

metas_Haddara_low = NaN(70,1,20);
metas_Haddara_high = NaN(70,1,20);

for p = 1:70

    d = Haddara.data{p};

    conf_low = xue_recode(d.conf,1);
    conf_high = xue_recode(d.conf,2);

    metas_Haddara_low(p,1,:) = reshape( ...
        compute_all_measures(d.stim,d.resp,conf_low,3),1,1,20);

    metas_Haddara_high(p,1,:) = reshape( ...
        compute_all_measures(d.stim,d.resp,conf_high,3),1,1,20);

end

Haddara_low_avg = squeeze(metas_Haddara_low);
Haddara_high_avg = squeeze(metas_Haddara_high);

fprintf('Haddara calculations completed.\n');

%% 6. MANISCALCO: LOW AND HIGH CONFIDENCE RECODING

metas_Maniscalco_low = NaN(22,1,20);
metas_Maniscalco_high = NaN(22,1,20);

for p = 1:22

    d = Maniscalco.data{p};

    conf_low = xue_recode(d.conf,1);
    conf_high = xue_recode(d.conf,2);

    metas_Maniscalco_low(p,1,:) = reshape( ...
        compute_all_measures(d.stim,d.resp,conf_low,3),1,1,20);

    metas_Maniscalco_high(p,1,:) = reshape( ...
        compute_all_measures(d.stim,d.resp,conf_high,3),1,1,20);

end

Maniscalco_low_avg = squeeze(metas_Maniscalco_low);
Maniscalco_high_avg = squeeze(metas_Maniscalco_high);

fprintf('Maniscalco calculations completed.\n');

%% 7. CALCULATE MEANS AND SEMs
%
% Haddara

mean_H_low = mean(Haddara_low_avg,1,'omitnan');
mean_H_high = mean(Haddara_high_avg,1,'omitnan');

sem_H_low = std(Haddara_low_avg,0,1,'omitnan') ./ ...
    sqrt(sum(~isnan(Haddara_low_avg),1));

sem_H_high = std(Haddara_high_avg,0,1,'omitnan') ./ ...
    sqrt(sum(~isnan(Haddara_high_avg),1));

% Maniscalco

mean_M_low = mean(Maniscalco_low_avg,1,'omitnan');
mean_M_high = mean(Maniscalco_high_avg,1,'omitnan');

sem_M_low = std(Maniscalco_low_avg,0,1,'omitnan') ./ ...
    sqrt(sum(~isnan(Maniscalco_low_avg),1));

sem_M_high = std(Maniscalco_high_avg,0,1,'omitnan') ./ ...
    sqrt(sum(~isnan(Maniscalco_high_avg),1));

% Shekhar: use author arrays averaged across difficulty levels

mean_S_low = mean(author_low_avg,1,'omitnan');
mean_S_high = mean(author_high_avg,1,'omitnan');

sem_S_low = std(author_low_avg,0,1,'omitnan') ./ ...
    sqrt(sum(~isnan(author_low_avg),1));

sem_S_high = std(author_high_avg,0,1,'omitnan') ./ ...
    sqrt(sum(~isnan(author_high_avg),1));

%% 8. CALCULATE HIGH-LOW DIFFERENCES

diff_Haddara = Haddara_high_avg - Haddara_low_avg;

diff_Maniscalco = Maniscalco_high_avg - Maniscalco_low_avg;

diff_Shekhar = author_high_avg - author_low_avg;

%% 9. CALCULATE P-VALUES
%
% Paired t-test p-values using the Student t-distribution beta identity.
% This avoids requiring the Statistics and Machine Learning Toolbox.

p_Haddara = calculate_pvalues(diff_Haddara);
p_Maniscalco = calculate_pvalues(diff_Maniscalco);
p_Shekhar = calculate_pvalues(diff_Shekhar);

fprintf('P-values calculated.\n');

%% 10. MEASURE NAMES

variable_names = { ...
    'meta-d''', ...
    'AUC2', ...
    'Gamma', ...
    'Phi', ...
    '\DeltaConf', ...
    'M-Ratio', ...
    'AUC2-Ratio', ...
    'Gamma-Ratio', ...
    'Phi-Ratio', ...
    '\DeltaConf-Ratio', ...
    'M-Diff', ...
    'AUC2-Diff', ...
    'Gamma-Diff', ...
    'Phi-Diff', ...
    '\DeltaConf-Diff', ...
    'meta-noise', ...
    'meta-uncertainty', ...
    'd''', ...
    'Criterion', ...
    'Confidence'};

%% 11. FIGURE 3A - SHEKHAR ALONE

plotShekharOnly(author_low_avg,author_high_avg, ...
    variable_names,p_Shekhar);

savefig(gcf,fullfile(projectFolder,'Figure3A_Shekhar.fig'));

exportgraphics(gcf, ...
    fullfile(projectFolder,'Figure3A_Shekhar.png'), ...
    'Resolution',300);

%% 12. FIGURE 3A - ALL THREE DATASETS TOGETHER

plotFigure3A( ...
    Haddara_low_avg,Haddara_high_avg, ...
    Maniscalco_low_avg,Maniscalco_high_avg, ...
    author_low_avg,author_high_avg, ...
    p_Haddara,p_Maniscalco,p_Shekhar, ...
    variable_names);

savefig(gcf,fullfile(projectFolder,'Figure3A.fig'));

exportgraphics(gcf, ...
    fullfile(projectFolder,'Figure3A.png'), ...
    'Resolution',300);

fprintf('Figure 3A saved.\n');

%% 13. FIGURE 3B - COHEN'S d
%
% Cohen's d is calculated from paired high-minus-low differences.
% This is equivalent to t/sqrt(n), as in the original analysis.
% The first 17 measures are plotted.

Cohen_d_all = NaN(3,17);

for m = 1:17

    % Haddara
    x = diff_Haddara(:,m);
    x = x(~isnan(x));

    if numel(x) >= 2
        sd = std(x,0);
        if sd > 0
            Cohen_d_all(1,m) = mean(x)/sd;
        end
    end

    % Maniscalco
    x = diff_Maniscalco(:,m);
    x = x(~isnan(x));

    if numel(x) >= 2
        sd = std(x,0);
        if sd > 0
            Cohen_d_all(2,m) = mean(x)/sd;
        end
    end

    % Shekhar
    x = diff_Shekhar(:,m);
    x = x(~isnan(x));

    if numel(x) >= 2
        sd = std(x,0);
        if sd > 0
            Cohen_d_all(3,m) = mean(x)/sd;
        end
    end

end

%% 14. PLOT FIGURE 3B

figure('Color','w','Position',[100 100 1500 600]);

bar(Cohen_d_all','grouped');

hold on;
yline(0,'--','HandleVisibility','off');

ylim([-1 1.5]);
yticks(-1:0.5:1.5);

xticks(1:17);
xticklabels(variable_names(1:17));

xtickangle(45);

ylabel("Cohen's d");
title('Effect of confidence recoding on metacognitive measures');

legend({'Haddara','Maniscalco','Shekhar'}, ...
    'Location','best');

set(gca,'FontSize',9);

hold off;

savefig(gcf,fullfile(projectFolder,'Figure3B.fig'));

exportgraphics(gcf, ...
    fullfile(projectFolder,'Figure3B.png'), ...
    'Resolution',300);

fprintf('Figure 3B saved.\n');

%% 15. SAVE THE ANALYSIS RESULTS

save(fullfile(projectFolder,'Figure3_Analysis_Results.mat'), ...
    'metas_original','metas_low','metas_high', ...
    'author_low','author_high', ...
    'author_low_avg','author_high_avg', ...
    'metas_Haddara_low','metas_Haddara_high', ...
    'metas_Maniscalco_low','metas_Maniscalco_high', ...
    'Haddara_low_avg','Haddara_high_avg', ...
    'Maniscalco_low_avg','Maniscalco_high_avg', ...
    'diff_Haddara','diff_Maniscalco','diff_Shekhar', ...
    'p_Haddara','p_Maniscalco','p_Shekhar', ...
    'Cohen_d_all');

fprintf('\n========================================\n');
fprintf('FIGURE 3 ANALYSIS COMPLETED SUCCESSFULLY\n');
fprintf('========================================\n');

fprintf('Saved files:\n');
fprintf('Figure3A_Shekhar.png and .fig\n');
fprintf('Figure3A.png and .fig\n');
fprintf('Figure3B.png and .fig\n');
fprintf('Figure3_Analysis_Results.mat\n');


%% ================================================================
%  LOCAL FUNCTIONS
%% ================================================================

function p_values = calculate_pvalues(differences)

    n = sum(~isnan(differences),1);

    average = mean(differences,1,'omitnan');
    deviation = std(differences,0,1,'omitnan');

    p_values = NaN(1,size(differences,2));

    for m = 1:size(differences,2)

        if n(m) < 2
            continue;
        end

        if deviation(m) == 0

            if average(m) == 0
                p_values(m) = 1;
            else
                p_values(m) = 0;
            end

        else

            t_value = average(m)/(deviation(m)/sqrt(n(m)));
            df = n(m)-1;

            p_values(m) = betainc( ...
                df/(df+t_value^2),df/2,0.5);

        end
    end
end


function plotFigure3A( ...
    H_low,H_high,M_low,M_high,S_low,S_high, ...
    p_H,p_M,p_S,variable_names)

    figure('Color','w','Position',[100 100 1500 850]);

    t = tiledlayout(4,5, ...
        'TileSpacing','compact', ...
        'Padding','compact');

    colors = lines(3);

    legendHandles = gobjects(1,3);

    for m = 1:20

        ax = nexttile;
        hold(ax,'on');

        % Haddara
        h1 = errorbar(ax,[1 2], ...
            [mean(H_low(:,m),'omitnan'), ...
             mean(H_high(:,m),'omitnan')], ...
            [std(H_low(:,m),0,'omitnan')/sqrt(sum(~isnan(H_low(:,m)))), ...
             std(H_high(:,m),0,'omitnan')/sqrt(sum(~isnan(H_high(:,m))))], ...
            '-o','Color',colors(1,:), ...
            'LineWidth',1.1,'MarkerSize',3.5);

        % Maniscalco
        h2 = errorbar(ax,[4 5], ...
            [mean(M_low(:,m),'omitnan'), ...
             mean(M_high(:,m),'omitnan')], ...
            [std(M_low(:,m),0,'omitnan')/sqrt(sum(~isnan(M_low(:,m)))), ...
             std(M_high(:,m),0,'omitnan')/sqrt(sum(~isnan(M_high(:,m))))], ...
            '-o','Color',colors(2,:), ...
            'LineWidth',1.1,'MarkerSize',3.5);

        % Shekhar
        h3 = errorbar(ax,[7 8], ...
            [mean(S_low(:,m),'omitnan'), ...
             mean(S_high(:,m),'omitnan')], ...
            [std(S_low(:,m),0,'omitnan')/sqrt(sum(~isnan(S_low(:,m)))), ...
             std(S_high(:,m),0,'omitnan')/sqrt(sum(~isnan(S_high(:,m))))], ...
            '-o','Color',colors(3,:), ...
            'LineWidth',1.1,'MarkerSize',3.5);

        if m == 1
            legendHandles = [h1 h2 h3];
        end

        xlim(ax,[0 9]);

        xticks(ax,[1 2 4 5 7 8]);

        xticklabels(ax, ...
            {'Low','High','Low','High','Low','High'});

        % Small labels so Low and High remain visually separate
        set(ax,'FontSize',6);

        title(ax,variable_names{m}, ...
            'Interpreter','tex','FontSize',9);

        % Significance annotations
        y_limits = ylim(ax);
        y_range = y_limits(2)-y_limits(1);

        if y_range == 0
            y_range = 1;
        end

        upper_values = [ ...
            mean(H_low(:,m),'omitnan') + ...
                std(H_low(:,m),0,'omitnan')/sqrt(sum(~isnan(H_low(:,m)))), ...
            mean(H_high(:,m),'omitnan') + ...
                std(H_high(:,m),0,'omitnan')/sqrt(sum(~isnan(H_high(:,m)))), ...
            mean(M_low(:,m),'omitnan') + ...
                std(M_low(:,m),0,'omitnan')/sqrt(sum(~isnan(M_low(:,m)))), ...
            mean(M_high(:,m),'omitnan') + ...
                std(M_high(:,m),0,'omitnan')/sqrt(sum(~isnan(M_high(:,m)))), ...
            mean(S_low(:,m),'omitnan') + ...
                std(S_low(:,m),0,'omitnan')/sqrt(sum(~isnan(S_low(:,m)))), ...
            mean(S_high(:,m),'omitnan') + ...
                std(S_high(:,m),0,'omitnan')/sqrt(sum(~isnan(S_high(:,m))))];

        y_H = max(upper_values(1:2));
        y_M = max(upper_values(3:4));
        y_S = max(upper_values(5:6));

        y_top = max([y_H y_M y_S]);

        ylim(ax,[y_limits(1), ...
            max(y_limits(2),y_top+0.25*y_range)]);

        y_offset = 0.06*y_range;

        % Haddara significance
        stars = significance_label(p_H(m));
        text(ax,1.5,y_H+y_offset,stars, ...
            'HorizontalAlignment','center','FontSize',7);

        % Maniscalco significance
        stars = significance_label(p_M(m));
        text(ax,4.5,y_M+y_offset,stars, ...
            'HorizontalAlignment','center','FontSize',7);

        % Shekhar significance
        stars = significance_label(p_S(m));
        text(ax,7.5,y_S+y_offset,stars, ...
            'HorizontalAlignment','center','FontSize',7);

        hold(ax,'off');

    end

    % Shared legend outside the 20 panels, on the right
    lgd = legend(legendHandles, ...
        {'Haddara','Maniscalco','Shekhar'}, ...
        'Orientation','vertical');

    lgd.Layout.Tile = 'east';

    title(t, ...
        'Dependence of estimated metacognitive scores on metacognitive bias');

end


function plotShekharOnly(S_low,S_high,variable_names,p_S)

    figure('Color','w','Position',[100 100 1400 800]);

    t = tiledlayout(4,5, ...
        'TileSpacing','compact', ...
        'Padding','compact');

    for m = 1:20

        ax = nexttile;
        hold(ax,'on');

        low_mean = mean(S_low(:,m),'omitnan');
        high_mean = mean(S_high(:,m),'omitnan');

        low_sem = std(S_low(:,m),0,'omitnan') / ...
            sqrt(sum(~isnan(S_low(:,m))));

        high_sem = std(S_high(:,m),0,'omitnan') / ...
            sqrt(sum(~isnan(S_high(:,m))));

        errorbar(ax,[1 2],[low_mean high_mean], ...
            [low_sem high_sem],'-o', ...
            'LineWidth',1.2,'MarkerSize',4);

        xlim(ax,[0.5 2.5]);

        xticks(ax,[1 2]);
        xticklabels(ax,{'Low','High'});

        set(ax,'FontSize',7);

        title(ax,variable_names{m}, ...
            'Interpreter','tex','FontSize',9);

        y_limits = ylim(ax);
        y_range = y_limits(2)-y_limits(1);

        if y_range == 0
            y_range = 1;
        end

        y_top = max([low_mean+low_sem,high_mean+high_sem]);

        ylim(ax,[y_limits(1),max(y_limits(2),y_top+0.25*y_range)]);

        stars = significance_label(p_S(m));

        text(ax,1.5,y_top+0.06*y_range,stars, ...
            'HorizontalAlignment','center','FontSize',8);

        hold(ax,'off');

    end

    title(t,'Shekhar dataset: Dependence of metacognitive scores on metacognitive bias');

end


function stars = significance_label(p)

    if isnan(p)
        stars = 'n/a';
    elseif p < 0.001
        stars = '***';
    elseif p < 0.01
        stars = '**';
    elseif p < 0.05
        stars = '*';
    else
        stars = 'ns';
    end

end

