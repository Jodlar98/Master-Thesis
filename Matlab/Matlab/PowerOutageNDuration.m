% MATLAB Code for Chart 1: POWER OUTAGE CHARACTERISTICS

% 1. Define categories and counts from your summary data
categories = {'Often', 'Off-grid', 'Sometimes'};
counts = [7, 5, 3];
% The data is already sorted, but we keep the sort logic for consistency
[sorted_counts, sort_order] = sort(counts, 'descend');
sorted_categories = categories(sort_order);

% 2. Create the horizontal bar chart
fig1 = figure; % Creates a new figure window for the first chart
set (fig1, "Position", [100, 100, 600, 200])
b = barh(sorted_counts);

% --- Add custom colors ---
bar_colors = [
    [0.9, 0.2, 0.2];  % Red for 'Often'
    [0.5, 0.5, 0.5];  % Grey for 'Off-grid'
    [0.9, 0.7, 0.2]   % Yellow for 'Sometimes'
];
b.FaceColor = 'flat';
b.CData = bar_colors;

% 3. Customize the chart
title('Frequency of Power Outages');
xlabel('Number of Occurrences');
%ylabel('Category');
set(gca, 'yticklabel', sorted_categories);
grid on;
ylim([0.5, length(categories) + 0.5]);
xlim([0, 8]); % Adjust x-limit to fit data and annotations

% 4. Add count labels inside the bars
xtips = b.YData;
ytips = b.XData;
labels = string(xtips);
text(xtips - 0.3, ytips, labels, 'HorizontalAlignment', 'center', ...
     'VerticalAlignment', 'middle', 'Color', 'white', 'FontWeight', 'bold');

% --- SPECIAL: Add annotation for average outage duration ---
% Find the bar corresponding to 'Often'
often_bar_index = find(strcmp(sorted_categories, 'Often'));
% Add text annotation next to that bar
annotation_text = 'Avg. max duration = 3 hours';
text(sorted_counts(often_bar_index) + 0.2, ... % x-position (just right of the bar)
     often_bar_index, ...                         % y-position (at the bar's height)
     annotation_text, ...
     'VerticalAlignment', 'middle', 'FontWeight', 'bold');