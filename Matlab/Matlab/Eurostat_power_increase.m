% Read the data from the CSV file
T = readtable('estat_nrg_pc_204_filtered_en.csv');

% Extract the data
time = T.TIME_PERIOD;
values = T.OBS_VALUE;

% Convert values to numeric
if iscell(values)
    numericValues = cellfun(@(x) double(x), values);
else
    numericValues = values;
end

% Apply one-sided weighted average with increasing window
windowSize = 5; % Adjust window size as needed
weights = [1, 2, 3, 4, 5]; % Example weights, adjust as desired (increasing weights)
weights = weights / sum(weights); % Normalize weights

weightedAverage = zeros(size(numericValues));

for i = 1:length(numericValues)
    if i < 2
        weightedAverage(i) = numericValues(i); % No average for the first point
    elseif i < windowSize
        % Calculate average with increasing window
        currentWindowSize = i;
        currentWeights = weights(end - currentWindowSize + 1:end); % Get relevant weights
        currentWeights = currentWeights / sum(currentWeights); % Normalize
        window = numericValues(i - currentWindowSize + 1:i);
        weightedAverage(i) = sum(window .* currentWeights');
    else
        % Calculate average with full window
        window = numericValues(i - windowSize + 1:i);
        weightedAverage(i) = sum(window .* weights');
    end
end

% Calculate rise percentage using only the first and last weighted average values
averageRisePercentage = (numericValues(35) - numericValues(1))/length(time);

% Extrapolate using average rise percentage
extensionPoints = 16;
extendedValues = weightedAverage(end); % Start with the last weighted average value
for i = 1:extensionPoints
    extendedValues = [extendedValues, extendedValues(end) + averageRisePercentage ];
end

% Create extended time labels (2024-S1, 2025-S1, etc.)
lastYear = str2double(extractBefore(time(end), '-')); % Extract the year from the last time value
lastSemester = extractAfter(time(end), '-'); % Extract the semester from the last time value

extendedTime = [time; strings(extensionPoints, 1)]; % Initialize extended time with original time and empty strings.
for i = 1:extensionPoints
    if strcmp(lastSemester, 'S1')
        lastSemester = 'S2';
    else
        lastSemester = 'S1';
        lastYear = lastYear + 1;
    end
    extendedTime(length(time) + i) = sprintf('%d-%s', lastYear, lastSemester);
end

% Plot the data, weighted average, and extrapolated values
fig = figure;
set(fig, 'Position', [100, 100, 800, 400]);

plot(1:length(time), numericValues, Color="red", LineWidth=2, DisplayName='Electricty price');
hold on;
%plot(1:length(time), weightedAverage, Color="blue", LineStyle="-", LineWidth=1,DisplayName='Weighted Average'); %plot the full weighted average.
%plot(length(time):length(time) + extensionPoints, extendedValues, Color="blue", LineStyle="--", LineWidth=1,DisplayName='Estimated prices');
hold off;

% Add labels and title
xlabel('');
ylabel('Price in euro [€]');
title('Electricity prices in EU-27 area');
legend;

% Show every 5th x-axis label for original data and extended labels
indices = 1:3:(length(time)+extensionPoints);
xticks(indices);
xticklabels(extendedTime(indices));
xtickangle(0);
xlim([10 length(time)]);
ylim([0.08 0.3])