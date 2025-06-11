% Step 1: Define the filename of the Excel file
filename = 'Year_2016_2017_2018__2019_data_.xlsx'; % Replace with your file name

% Step 2: Read the data from the Excel file into a table
data = readtable(filename);

% Step 3: Extract the 'Time' column from the table
timeData = data.Time;

% Step 4: Extract the 'Load' column from the table
loadData = data.Load;

% Step 5: Define the expected format of the time data in the Excel file
inputTimeFormat = 'dd.MM.yyyy HH:mm';

% Step 6: Convert the 'Time' data from its string format to datetime objects
timeData = datetime(timeData, 'InputFormat', inputTimeFormat);

% Step 7: Extract the month number from the datetime objects
monthData = month(timeData);

% Step 8: Extract the hour of the day from the datetime objects
hourData = hour(timeData);

% Step 9: Create a new table to be used for grouping and summarization
groupingTable = table(monthData, hourData, loadData);

% Step 10: Define the variables to group by
groupingVariables = {'monthData', 'hourData'};

% Step 11: Define the variable to calculate the mean of
dataVariableToMean = 'loadData';

% Step 12: Calculate the mean of the 'loadData' for each group of month and hour
hourlyMonthlySummary = groupsummary(groupingTable, groupingVariables, 'mean', dataVariableToMean);

% Step 13: Remove the 'GroupCount' column
hourlyMonthlySummary = removevars(hourlyMonthlySummary, 'GroupCount');

% Step 14: Define the desired names for the columns in the resulting table
newColumnNames = {'Month', 'Hour', 'AverageLoad'};

% Step 15: Assign the new column names to the 'hourlyMonthlySummary' table
hourlyMonthlySummary.Properties.VariableNames = newColumnNames;

% Step 16: Display the resulting table containing the average load for each hour of each month
disp(hourlyMonthlySummary);

%% Plot the data

% Assuming you have the 'hourlyMonthlySummary' table from the previous steps
% Initialize a cell array to store mean hourly data for each month
mean_hourlyLoad_data = cell(12, 1);

% Step 1: Create a figure with a specific size and position
fig = figure;
set(fig, 'Position', [100, 100, 800, 400]);

% Step 2: Hold on to the current axes to allow multiple plots
hold on;

% Step 3: Get the unique month numbers from the summary table
uniqueMonths = unique(hourlyMonthlySummary.Month);

% Step 4: Create a cell array to store month names for display
monthNames = {'January', 'February', 'March', 'April', 'May', 'June', ...
              'July', 'August', 'September', 'October', 'November', 'December'};

% Step 5: Loop through each unique month
for i = 1:length(uniqueMonths)
    currentMonthNumber = uniqueMonths(i);

    % Step 6: Extract the data for the current month
    monthlyData = hourlyMonthlySummary(hourlyMonthlySummary.Month == currentMonthNumber, :);

    % Step 7: Sort the monthly data by hour for a smooth plot
    monthlyData = sortrows(monthlyData, 'Hour');

    % Step 8: Get the corresponding month name
    currentMonthName = monthNames{currentMonthNumber};

    % Step 9: Determine line style based on the month (October to March = dotted)
    if currentMonthNumber >= 10 || currentMonthNumber <= 3 % October (10) to March (3)
        lineStyle = '--'; % Dotted line
    else
        lineStyle = '-'; % Solid line (default)
    end

    % Step 10: Plot the average load for the current month with the month name and style
    plot(monthlyData.Hour, monthlyData.AverageLoad, 'DisplayName', currentMonthName, 'LineStyle', lineStyle);
    % Store the smoothed mean hourly data for the current month
    mean_hourlyLoad_data{i} = monthlyData.AverageLoad;
end
% Save the data for later use
save("mean_hourlyLoad_data.mat", "mean_hourlyLoad_data")

% Step 11: Add labels and a title to the plot
xlim([0 23]); % Set the x-axis limits
xlabel('Hour of the Day');
ylabel('MWh');
title('Average Hourly Load in Albania[2016-2019]');
% Set the x-axis ticks to show each hour from 0 to 23
xticks(0:23);
xticklabels(0:23); % Optional: explicitly label each tick
legend('show'); % Display the legend with month names
grid on; % Add a grid for better readability
hold off; % Release the hold on the axes

