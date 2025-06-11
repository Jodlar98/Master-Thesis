% MATLAB Code for Chart 2: REMOVED CANDLES ANALYSIS

% 1. Define categories and their counts
categories_rc = {'Yes', 'No'};
counts_rc = [10, 2];
% Data is already sorted
[sorted_counts_rc, sort_order_rc] = sort(counts_rc, 'descend');
sorted_categories_rc = categories_rc(sort_order_rc);

% 2. Create the horizontal bar chart in a new figure
fig1 = figure; % Creates a new figure window for the first chart
set (fig1, "Position", [100, 100, 600, 200])
b2 = barh(sorted_counts_rc);

% --- Add custom colors ---
bar_colors_rc = [
    [0.2, 0.7, 0.3];  % Green for 'Yes'
    [0.9, 0.2, 0.2]   % Red for 'No'
];
b2.FaceColor = 'flat';
b2.CData = bar_colors_rc;

% 3. Customize the chart
title('Household Removed Candles After SHS');
xlabel('Number of Responses');
%ylabel('Response');
set(gca, 'yticklabel', sorted_categories_rc);
grid on;
ylim([0.5, length(categories_rc) + 0.5]);
xlim([0, 12]);

% 4. Add count labels inside the bars
xtips = b2.YData;
ytips = b2.XData;
labels = string(xtips);
text(xtips - 0.5, ytips, labels, 'HorizontalAlignment', 'center', ...
     'VerticalAlignment', 'middle', 'Color', 'white', 'FontWeight', 'bold');