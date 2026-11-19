
%% ================================================================
% PILOT 1 - COMPLETE ANALYSIS
% Dot Number Comparison + Confidence
%
% Input: Pilot1_allData.csv
% Location: Desktop
%
% Figure B1: Group means +/- SD
% Figure B2: Individual participant results
%
% ================================================================

clear;
clc;
close all;

%% 1. LOAD THE EXISTING COMBINED DATASET

filename = 'C:\Users\PC\Desktop\Pilot1_allData.csv';

if ~isfile(filename)
    error('Pilot1_allData.csv was not found on your Desktop.');
end

allData = readtable(filename);

disp('Dataset imported successfully.');
fprintf('Total rows: %d\n', height(allData));

%% 2. KEEP MAIN TRIALS ONLY

mainData = allData( ...
    strcmpi(string(allData.phase), 'main'), :);

fprintf('Main trials: %d\n', height(mainData));

%% 3. DEFINE PARTICIPANTS AND DIFFICULTY LEVELS

levels = ["easy", "medium", "hard"];

participants = unique( ...
    string(mainData.participant), 'stable');

nP = length(participants);
nL = length(levels);

fprintf('Number of participants: %d\n', nP);

disp('Participants:');
disp(participants);

%% 4. CALCULATE POOLED RESULTS

pooledAccuracy = zeros(nL,1);
pooledConfidence = zeros(nL,1);
pooledGap = zeros(nL,1);

for l = 1:nL

    idx = strcmpi(string(mainData.level), levels(l));

    pooledAccuracy(l) = ...
        mean(mainData.correct(idx)) * 100;

    pooledConfidence(l) = ...
        mean(mainData.confidence(idx)) * 100;

    pooledGap(l) = ...
        pooledConfidence(l) - pooledAccuracy(l);

end

pooledResults = table( ...
    levels', pooledAccuracy, pooledConfidence, pooledGap, ...
    'VariableNames', ...
    {'Difficulty','Accuracy','MeanConfidence','CalibrationGap'});

disp('POOLED RESULTS:');
disp(pooledResults);

%% 5. CALCULATE PARTICIPANT-LEVEL MEASURES

AccuracyMatrix = nan(nP,nL);
ConfidenceMatrix = nan(nP,nL);
GapMatrix = nan(nP,nL);

ConfCorrectMatrix = nan(nP,nL);
ConfIncorrectMatrix = nan(nP,nL);
DiscriminationMatrix = nan(nP,nL);

RTMatrix = nan(nP,nL);
ConfRTMatrix = nan(nP,nL);

for p = 1:nP

    for l = 1:nL

        idx = ...
            string(mainData.participant) == participants(p) & ...
            strcmpi(string(mainData.level), levels(l));

        T = mainData(idx,:);

        % Accuracy
        AccuracyMatrix(p,l) = mean(T.correct) * 100;

        % Mean confidence
        ConfidenceMatrix(p,l) = mean(T.confidence) * 100;

        % Calibration gap
        GapMatrix(p,l) = ...
            ConfidenceMatrix(p,l) - AccuracyMatrix(p,l);

        % Correct and incorrect trials
        correctIdx = T.correct == 1;
        incorrectIdx = T.correct == 0;

        if any(correctIdx)
            ConfCorrectMatrix(p,l) = ...
                mean(T.confidence(correctIdx)) * 100;
        end

        if any(incorrectIdx)
            ConfIncorrectMatrix(p,l) = ...
                mean(T.confidence(incorrectIdx)) * 100;
        end

        % Confidence discrimination (Delta Conf)
        if any(correctIdx) && any(incorrectIdx)

            DiscriminationMatrix(p,l) = ...
                ConfCorrectMatrix(p,l) - ...
                ConfIncorrectMatrix(p,l);

        end

        % Decision reaction time
        RTMatrix(p,l) = mean(T.rt);

        % Confidence reaction time
        ConfRTMatrix(p,l) = mean(T.conf_rt);

    end
end

%% 6. CREATE PARTICIPANT RESULTS TABLE

Participant = strings(nP*nL,1);
Difficulty = strings(nP*nL,1);

Accuracy = zeros(nP*nL,1);
Confidence = zeros(nP*nL,1);
CalibrationGap = zeros(nP*nL,1);

ConfidenceCorrect = nan(nP*nL,1);
ConfidenceIncorrect = nan(nP*nL,1);
Discrimination = nan(nP*nL,1);

MeanRT = zeros(nP*nL,1);
MeanConfRT = zeros(nP*nL,1);

k = 0;

for p = 1:nP

    for l = 1:nL

        k = k + 1;

        Participant(k) = participants(p);
        Difficulty(k) = levels(l);

        Accuracy(k) = AccuracyMatrix(p,l);
        Confidence(k) = ConfidenceMatrix(p,l);
        CalibrationGap(k) = GapMatrix(p,l);

        ConfidenceCorrect(k) = ConfCorrectMatrix(p,l);
        ConfidenceIncorrect(k) = ConfIncorrectMatrix(p,l);

        Discrimination(k) = DiscriminationMatrix(p,l);

        MeanRT(k) = RTMatrix(p,l);
        MeanConfRT(k) = ConfRTMatrix(p,l);

    end
end

participantResults = table( ...
    Participant, Difficulty, Accuracy, Confidence, ...
    CalibrationGap, ConfidenceCorrect, ...
    ConfidenceIncorrect, Discrimination, ...
    MeanRT, MeanConfRT);

disp('PARTICIPANT-LEVEL RESULTS:');
disp(participantResults);

%% 7. GROUP MEANS AND STANDARD DEVIATIONS

% Each participant contributes equally to the group mean.

groupAccuracy = mean(AccuracyMatrix,1,'omitnan');
sdAccuracy = std(AccuracyMatrix,0,1,'omitnan');

groupConfidence = mean(ConfidenceMatrix,1,'omitnan');
sdConfidence = std(ConfidenceMatrix,0,1,'omitnan');

groupGap = mean(GapMatrix,1,'omitnan');
sdGap = std(GapMatrix,0,1,'omitnan');

groupDiscrimination = mean(DiscriminationMatrix,1,'omitnan');
sdDiscrimination = std(DiscriminationMatrix,0,1,'omitnan');

groupRT = mean(RTMatrix,1,'omitnan');
sdRT = std(RTMatrix,0,1,'omitnan');

groupConfRT = mean(ConfRTMatrix,1,'omitnan');
sdConfRT = std(ConfRTMatrix,0,1,'omitnan');

groupResults = table( ...
    levels', ...
    groupAccuracy', sdAccuracy', ...
    groupConfidence', sdConfidence', ...
    groupGap', sdGap', ...
    groupDiscrimination', sdDiscrimination', ...
    groupRT', sdRT', ...
    groupConfRT', sdConfRT', ...
    'VariableNames', { ...
    'Difficulty', ...
    'MeanAccuracy','SD_Accuracy', ...
    'MeanConfidence','SD_Confidence', ...
    'MeanCalibrationGap','SD_CalibrationGap', ...
    'MeanDiscrimination','SD_Discrimination', ...
    'MeanRT','SD_RT', ...
    'MeanConfRT','SD_ConfRT'});

disp('GROUP RESULTS (MEAN +/- SD):');
disp(groupResults);

%% 8. FIGURE B1 - GROUP MEANS +/- SD

figure('Name','Figure B1 - Group Results', ...
    'Position',[100 100 1500 1050]);

tiledlayout(3,2, ...
    'TileSpacing','loose', ...
    'Padding','loose');

x = 1:3;

% A. Accuracy
nexttile;

bar(x,groupAccuracy);
hold on;
errorbar(x,groupAccuracy,sdAccuracy, ...
    'k','LineStyle','none','LineWidth',1.2);

title('A. Accuracy');
ylabel('Accuracy (%)');
xticks(x);
xticklabels(levels);
ylim([0 105]);
grid on;

% B. Mean confidence
nexttile;

bar(x,groupConfidence);
hold on;
errorbar(x,groupConfidence,sdConfidence, ...
    'k','LineStyle','none','LineWidth',1.2);

title('B. Mean Confidence');
ylabel('Confidence (%)');
xticks(x);
xticklabels(levels);
ylim([0 105]);
grid on;

% C. Calibration gap
nexttile;

bar(x,groupGap);
hold on;
yline(0,'k--');

errorbar(x,groupGap,sdGap, ...
    'k','LineStyle','none','LineWidth',1.2);

title('C. Calibration Gap');
ylabel('Confidence - Accuracy (percentage points)');
xticks(x);
xticklabels(levels);
grid on;

% D. Confidence discrimination
nexttile;

bar(x,groupDiscrimination);
hold on;
yline(0,'k--');

errorbar(x,groupDiscrimination,sdDiscrimination, ...
    'k','LineStyle','none','LineWidth',1.2);

title('D. Confidence Discrimination');
ylabel('\Delta Conf (percentage points)');
xticks(x);
xticklabels(levels);
grid on;

% E. Decision reaction time
nexttile;

bar(x,groupRT);
hold on;
errorbar(x,groupRT,sdRT, ...
    'k','LineStyle','none','LineWidth',1.2);

title('E. Decision Reaction Time');
ylabel('Reaction time (seconds)');
xticks(x);
xticklabels(levels);
grid on;

% F. Confidence reaction time
nexttile;

bar(x,groupConfRT);
hold on;
errorbar(x,groupConfRT,sdConfRT, ...
    'k','LineStyle','none','LineWidth',1.2);

title('F. Confidence Reaction Time');
ylabel('Reaction time (seconds)');
xticks(x);
xticklabels(levels);
grid on;

sgtitle('Pilot 1: Group-Level Results (Mean +/- SD)');

saveas(gcf,'Figure_B1_Group_Results.png');

%% 9. FIGURE B2 - INDIVIDUAL PARTICIPANT RESULTS

individualMatrices = { ...
    AccuracyMatrix, ...
    ConfidenceMatrix, ...
    GapMatrix, ...
    DiscriminationMatrix, ...
    RTMatrix, ...
    ConfRTMatrix};

individualTitles = { ...
    'A. Individual Accuracy', ...
    'B. Individual Mean Confidence', ...
    'C. Individual Calibration Gap', ...
    'D. Individual Confidence Discrimination', ...
    'E. Individual Decision RT', ...
    'F. Individual Confidence RT'};

individualYLabels = { ...
    'Accuracy (%)', ...
    'Confidence (%)', ...
    'Confidence - Accuracy (percentage points)', ...
    '\Delta Conf (percentage points)', ...
    'Reaction time (seconds)', ...
    'Reaction time (seconds)'};

figure('Name','Figure B2 - Individual Results', ...
    'Position',[100 100 1600 1100]);

tiledlayout(3,2, ...
    'TileSpacing','loose', ...
    'Padding','loose');

for m = 1:6

    nexttile;

    M = individualMatrices{m};

    bar(x,M');

    title(individualTitles{m});
    ylabel(individualYLabels{m});

    xticks(x);
    xticklabels(levels);

    grid on;

    if m == 1 || m == 2
        ylim([0 105]);
    end

    if m == 1

        legend(cellstr(participants), ...
            'Location','eastoutside', ...
            'Interpreter','none');

    end

end

sgtitle('Pilot 1: Individual Participant Results');

saveas(gcf,'Figure_B2_Individual_Results.png');

%% 10. EXPORT RESULTS

writetable(pooledResults, ...
    'Pilot1_Pooled_Results.csv');

writetable(participantResults, ...
    'Pilot1_Participant_Results.csv');

writetable(groupResults, ...
    'Pilot1_Group_Results.csv');

%% 11. FINAL SUMMARY

fprintf('\n====================================\n');
fprintf('PILOT 1 ANALYSIS COMPLETED\n');
fprintf('====================================\n');

fprintf('Participants: %d\n',nP);
fprintf('Main trials: %d\n',height(mainData));

disp('Group results:');
disp(groupResults);

fprintf('\nGenerated files:\n');
fprintf('1. Figure_B1_Group_Results.png\n');
fprintf('2. Figure_B2_Individual_Results.png\n');
fprintf('3. Pilot1_Pooled_Results.csv\n');
fprintf('4. Pilot1_Participant_Results.csv\n');
fprintf('5. Pilot1_Group_Results.csv\n')


%% EXTRA 1: trials and errors behind every cell
nTrials = nan(nP,nL);  nErrors = nan(nP,nL);
for p = 1:nP
    for l = 1:nL
        idx = string(mainData.participant)==participants(p) & ...
            strcmpi(string(mainData.level), levels(l));
        nTrials(p,l) = sum(idx);
        nErrors(p,l) = sum(mainData.correct(idx)==0);
    end
end
disp('Trials per cell:');  disp(nTrials);
disp('Errors per cell:');  disp(nErrors);
disp('Participants contributing to discrimination, per level:');
disp(sum(~isnan(DiscriminationMatrix),1));

%% EXTRA 2: how often each confidence key (1-6) was used, per participant (%)
keyUse = zeros(nP,6);
for p = 1:nP
    idx = string(mainData.participant)==participants(p);
    keyUse(p,:) = histcounts(mainData.confidence_rating(idx), 0.5:1:6.5) ...
        / sum(idx) * 100;
end
disp('Confidence key use (%), columns = keys 1..6:');  disp(keyUse);