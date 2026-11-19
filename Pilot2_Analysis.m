
%% PILOT 2 - COMPLETE DATA ANALYSIS
% Confidence Calibration and Metacognition Project
% Based on the measures used in the Rahnev (2025) paper.
%
% Measures:
% Accuracy
% Mean Confidence
% Calibration Gap
% AUC2
% Gamma
% Phi
% Delta Confidence
% Decision Reaction Time
% Confidence Reaction Time
%
% Outputs:
% Combined dataset
% Trial counts
% Individual participant results
% Group mean and SD results
% Individual graphs
% Group graphs with error bars
%
% No Statistics Toolbox required.

clear;
clc;
close all;


%% SECTION 1: FOLDER PATH

folder = 'C:\Users\PC\Desktop\Pilot 2';

fprintf('Checking folder...\n');
fprintf('%s\n', folder);

if exist(folder,'dir') ~= 7
    error('MATLAB cannot find the Pilot 2 folder.');
else
    fprintf('SUCCESS: Folder found!\n');
end


%% SECTION 2: IMPORT PARTICIPANT FILES

files = dir(fullfile(folder,'*_trials.csv'));

if isempty(files)
    error('No files ending in _trials.csv found in Pilot 2.');
end

allData = table();

fprintf('\nIMPORTING PARTICIPANT FILES\n');

for i = 1:length(files)

    filename = fullfile(folder,files(i).name);

    T = readtable(filename);

    T.source_file = repmat(string(files(i).name),height(T),1);

    allData = [allData; T];

    fprintf('Imported: %s\n',files(i).name);

end

fprintf('\nFiles imported: %d\n',length(files));
fprintf('Total rows: %d\n',height(allData));

writetable(allData, ...
    fullfile(folder,'Pilot2_AllParticipants.csv'));


%% SECTION 3: CHECK REQUIRED COLUMNS

requiredColumns = { ...
    'participant','phase','level','correct', ...
    'confidence','confidence_rating','rt','conf_rt'};

for i = 1:length(requiredColumns)

    if ~ismember(requiredColumns{i}, ...
            allData.Properties.VariableNames)

        error('Missing required column: %s',requiredColumns{i});

    end

end


%% SECTION 4: PREPARE MAIN DATA

allData.participant = str2double(string(allData.participant));

phaseValues = lower(strtrim(string(allData.phase)));

mainData = allData(phaseValues == "main",:);

if isempty(mainData)
    error('No main trials found. Check the phase column.');
end

levels = ["easy","medium","hard"];

participants = unique(mainData.participant);
participants = participants(~isnan(participants));
participants = sort(participants);

fprintf('\nDATA SUMMARY\n');
fprintf('Number of participants: %d\n',length(participants));
fprintf('Number of main trials: %d\n',height(mainData));


%% SECTION 5: TRIAL COUNTS

trialCounts = table();

for p = 1:length(participants)

    for d = 1:length(levels)

        idx = mainData.participant == participants(p) & ...
            lower(strtrim(string(mainData.level))) == levels(d);

        newRow = table(participants(p),levels(d),sum(idx), ...
            'VariableNames', ...
            {'Participant','Difficulty','TrialCount'});

        trialCounts = [trialCounts;newRow];

    end

end

fprintf('\nTRIAL COUNTS:\n');
disp(trialCounts);

writetable(trialCounts, ...
    fullfile(folder,'Pilot2_TrialCounts.csv'));


%% SECTION 6: INDIVIDUAL PARTICIPANT ANALYSIS

participantResults = table();

for p = 1:length(participants)

    for d = 1:length(levels)

        idx = mainData.participant == participants(p) & ...
            lower(strtrim(string(mainData.level))) == levels(d);

        T = mainData(idx,:);

        if isempty(T)
            continue;
        end

        correctAll = double(T.correct);
        confidenceAll = double(T.confidence);

        % Convert confidence proportions to percentages
        nonMissingConf = confidenceAll(~isnan(confidenceAll));

        if ~isempty(nonMissingConf) && max(nonMissingConf) <= 1.5
            confidenceAll = confidenceAll * 100;
        end

        % Keep valid correctness and confidence observations
        valid = ~isnan(correctAll) & ...
            ~isnan(confidenceAll) & ...
            (correctAll == 0 | correctAll == 1);

        correct = correctAll(valid);
        confidence = confidenceAll(valid);

        if isempty(correct)
            continue;
        end


        %% 6A. ACCURACY

        accuracy = mean(correct) * 100;


        %% 6B. MEAN CONFIDENCE

        meanConfidence = mean(confidence);


        %% 6C. CALIBRATION GAP

        calibrationGap = meanConfidence - accuracy;


        %% 6D. CONFIDENCE ON CORRECT AND INCORRECT TRIALS

        correctConf = confidence(correct == 1);
        incorrectConf = confidence(correct == 0);


        %% 6E. DELTA CONFIDENCE

        if ~isempty(correctConf) && ~isempty(incorrectConf)

            deltaConf = mean(correctConf) - mean(incorrectConf);

        else

            deltaConf = NaN;

        end


        %% 6F. AUC2

        if ~isempty(correctConf) && ~isempty(incorrectConf)

            differences = correctConf(:) - incorrectConf(:)';

            concordant = sum(differences(:) > 0);
            ties = sum(differences(:) == 0);

            auc2 = (concordant + 0.5*ties) / numel(differences);

        else

            auc2 = NaN;

        end


        %% 6G. GAMMA

        if ~isempty(correctConf) && ~isempty(incorrectConf)

            differences = correctConf(:) - incorrectConf(:)';

            concordant = sum(differences(:) > 0);
            discordant = sum(differences(:) < 0);

            if concordant + discordant > 0

                gamma = (concordant - discordant) / ...
                    (concordant + discordant);

            else

                gamma = NaN;

            end

        else

            gamma = NaN;

        end


        %% 6H. PHI

        if length(correct) > 1 && ...
                std(correct) > 0 && std(confidence) > 0

            x = confidence(:);
            y = correct(:);

            xCentered = x - mean(x);
            yCentered = y - mean(y);

            phi = sum(xCentered .* yCentered) / ...
                sqrt(sum(xCentered.^2)*sum(yCentered.^2));

        else

            phi = NaN;

        end


        %% 6I. DECISION REACTION TIME

        rtValues = double(T.rt);
        rtValues = rtValues(~isnan(rtValues));

        if isempty(rtValues)
            meanRT = NaN;
        else
            meanRT = mean(rtValues);
        end


        %% 6J. CONFIDENCE REACTION TIME

        confRTValues = double(T.conf_rt);
        confRTValues = confRTValues(~isnan(confRTValues));

        if isempty(confRTValues)
            meanConfRT = NaN;
        else
            meanConfRT = mean(confRTValues);
        end


        %% 6K. NUMBER OF CORRECT AND INCORRECT TRIALS

        nCorrect = sum(correct == 1);
        nIncorrect = sum(correct == 0);


        %% 6L. SAVE RESULTS

        newRow = table( ...
            participants(p),levels(d), ...
            accuracy,meanConfidence,calibrationGap, ...
            auc2,gamma,phi,deltaConf, ...
            meanRT,meanConfRT,nCorrect,nIncorrect, ...
            'VariableNames',{ ...
            'Participant','Difficulty', ...
            'Accuracy','MeanConfidence','CalibrationGap', ...
            'AUC2','Gamma','Phi','DeltaConf', ...
            'MeanRT','MeanConfRT','NCorrect','NIncorrect'});

        participantResults = [participantResults;newRow];

    end

end

fprintf('\nINDIVIDUAL PARTICIPANT RESULTS:\n');
disp(participantResults);

writetable(participantResults, ...
    fullfile(folder,'Pilot2_ParticipantResults.csv'));


%% SECTION 7: GROUP MEANS AND STANDARD DEVIATIONS

measureNames = { ...
    'Accuracy','MeanConfidence','CalibrationGap', ...
    'AUC2','Gamma','Phi','DeltaConf','MeanRT','MeanConfRT'};

groupResults = table();

for d = 1:length(levels)

    idx = participantResults.Difficulty == levels(d);

    difficultyData = participantResults(idx,:);

    newRow = table(levels(d), ...
        'VariableNames',{'Difficulty'});

    for m = 1:length(measureNames)

        measure = measureNames{m};

        values = difficultyData.(measure);
        values = values(~isnan(values));

        if isempty(values)

            groupMean = NaN;
            groupSD = NaN;

        else

            groupMean = mean(values);
            groupSD = std(values,0);

        end

        meanName = ['Mean' measure];
        sdName = ['SD' measure];

        newRow.(meanName) = groupMean;
        newRow.(sdName) = groupSD;

    end

    groupResults = [groupResults;newRow];

end

fprintf('\nGROUP RESULTS:\n');
disp(groupResults);

writetable(groupResults, ...
    fullfile(folder,'Pilot2_GroupResults.csv'));


%% SECTION 8: INDIVIDUAL PARTICIPANT GRAPHS

plotTitles = { ...
    'Accuracy (%)', ...
    'Mean Confidence (%)', ...
    'Calibration Gap (percentage points)', ...
    'AUC2', ...
    'Gamma', ...
    'Phi', ...
    'Delta Confidence (percentage points)', ...
    'Decision RT (s)', ...
    'Confidence RT (s)'};

nP = length(participants);

participantColors = lines(nP);

fig1 = figure('Name','Pilot 2 Individual Results', ...
    'NumberTitle','off','Position',[50 50 1500 900]);

for m = 1:length(measureNames)

    ax = subplot(3,3,m);

    values = NaN(3,nP);

    for p = 1:nP

        for d = 1:3

            idx = participantResults.Participant == participants(p) & ...
                participantResults.Difficulty == levels(d);

            if any(idx)

                rowNumber = find(idx,1);

                values(d,p) = ...
                    participantResults.(measureNames{m})(rowNumber);

            end

        end

    end

    b = bar(ax,values,'grouped');

    for p = 1:nP
        b(p).FaceColor = participantColors(p,:);
    end

    title(ax,plotTitles{m});
    xlabel(ax,'Difficulty');
    ylabel(ax,plotTitles{m});

    set(ax,'XTick',1:3,'XTickLabel',levels);

    grid(ax,'on');

    if m == 1

        legend(ax,"P" + string(participants), ...
            'Location','bestoutside');

    end

end

sgtitle('Pilot 2: Individual Participant Results');

saveas(fig1,fullfile(folder,'Pilot2_IndividualGraphs.png'));


%% SECTION 9: GROUP GRAPHS WITH STANDARD DEVIATION

fig2 = figure('Name','Pilot 2 Group Results', ...
    'NumberTitle','off','Position',[50 50 1500 900]);

for m = 1:length(measureNames)

    ax = subplot(3,3,m);

    meanColumn = ['Mean' measureNames{m}];
    sdColumn = ['SD' measureNames{m}];

    means = groupResults.(meanColumn);
    sds = groupResults.(sdColumn);

    bar(ax,1:3,means);

    hold(ax,'on');

    errorbar(ax,1:3,means,sds,'k.', ...
        'LineWidth',1.5,'CapSize',8);

    hold(ax,'off');

    title(ax,plotTitles{m});
    xlabel(ax,'Difficulty');
    ylabel(ax,plotTitles{m});

    set(ax,'XTick',1:3,'XTickLabel',levels);

    grid(ax,'on');

end

sgtitle('Pilot 2: Group Mean Results (Mean ± SD)');

saveas(fig2,fullfile(folder,'Pilot2_GroupGraphs.png'));


%% SECTION 10: FINAL OUTPUT

fprintf('\n========================================\n');
fprintf('PILOT 2 ANALYSIS COMPLETED SUCCESSFULLY\n');
fprintf('========================================\n');

fprintf('Participants analysed: %d\n',length(participants));
fprintf('Main trials analysed: %d\n',height(mainData));

fprintf('\nFILES SAVED IN:\n%s\n',folder);

fprintf('\nOUTPUT FILES:\n');

fprintf('1. Pilot2_AllParticipants.csv\n');
fprintf('2. Pilot2_TrialCounts.csv\n');
fprintf('3. Pilot2_ParticipantResults.csv\n');
fprintf('4. Pilot2_GroupResults.csv\n');
fprintf('5. Pilot2_IndividualGraphs.png\n');
fprintf('6. Pilot2_GroupGraphs.png\n');

fprintf('\nANALYSIS FINISHED.\n')


