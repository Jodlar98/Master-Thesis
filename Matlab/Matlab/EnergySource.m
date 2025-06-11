% MATLAB Code for Horizontal Bar Chart - ENERGY SOURCES

% 1. Define the categories and their corresponding counts
categories = {'Gas', 'Wood', 'Electricity'};
counts = [10, 6, 14];

% To make the chart more intuitive, let's sort the data
[sorted_counts, sort_order] = sort(counts, 'descend');
sorted_categories = categories(sort_order);

% 2. Create the horizontal bar chart
fig1 = figure; % Creates a new figure window for the first chart
set (fig1, "Position", [100, 100, 600, 200])
b = barh(sorted_counts);

% --- NEW: Add custom colors ---
% Define RGB colors for the bars (rows correspond to sorted data)
bar_colors = [
    0.1, 0.5, 0.8;  % Blue for 'Electricity' (highest)
    0.9, 0.4, 0.1;  % Orange for 'Gas'
    0.5, 0.3, 0.1   % Brown for 'Wood' (lowest)
];
b.FaceColor = 'flat';      % Allow each bar to have a different color
b.CData = bar_colors;      % Apply the color matrix

% 3. Customize the chart for clarity
title('Household Energy Sources');
xlabel('Number of Households');
ylabel('Energy Source');
set(gca, 'yticklabel', sorted_categories);
xlim([0, 17]); % Set x-axis limit
grid on;

% 4. Add the exact counts as text labels on the bars
xtips = b.YData;
ytips = b.XData;
labels = string(xtips);
text(xtips-0.5, ytips, labels, 'HorizontalAlignment', 'center', 'VerticalAlignment', 'middle', 'Color', 'white', 'FontWeight', 'bold');

% Adjust axis limits to provide some space
ylim([0.5, length(categories) + 0.5]);

%% Electricity access

% MATLAB Code for Horizontal Bar Chart - GRID CONNECTION

% 1. Define the new categories and their counts from the image
categories_grid = {'Grid', 'Illegal', 'Off-Grid'};
counts_grid = [14, 5, 3];

% Sort the data for better visualization
[sorted_counts_grid, sort_order_grid] = sort(counts_grid, 'descend');
sorted_categories_grid = categories_grid(sort_order_grid);

% 2. Create the new horizontal bar chart in a new figure
fig2 = figure; % Creates a new figure window for the second chart
set (fig2, "Position", [200, 200, 600, 200])
b2 = barh(sorted_counts_grid);

% --- Add custom colors ---
% Define RGB colors for the new set of bars
bar_colors_grid = [
    0.2, 0.7, 0.3;  % Green for 'Grid' (highest)
    0.8, 0.2, 0.2;  % Red for 'Illegal'
    0.5, 0.5, 0.5   % Grey for 'Off-Grid' (lowest)
];
b2.FaceColor = 'flat';      % Allow each bar to have a different color
b2.CData = bar_colors_grid; % Apply the color matrix

% 3. Customize the chart for clarity
title('Grid Connection Status');
xlabel('Number of Households');
ylabel('Connection Type');
set(gca, 'yticklabel', sorted_categories_grid);
xlim([0, 17]); % Set x-axis limit
grid on;

% 4. Add the exact counts as text labels on the bars
xtips = b2.YData;
ytips = b2.XData;
labels = string(xtips);
text(xtips-0.5, ytips, labels, 'HorizontalAlignment', 'center', 'VerticalAlignment', 'middle', 'Color', 'white', 'FontWeight', 'bold');

% Adjust axis limits to provide some space
ylim([0.5, length(categories_grid) + 0.5]);