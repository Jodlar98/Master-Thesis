% MATLAB Code to Visualize Payback Times

% 1. Define the payback time data
% Each row represents a system (300, 600, 800)
% Each column represents a specific payback scenario:
% Col 1: Consumption / Cost Quan
% Col 2: Production / Cost Quan
% Col 3: Consumption / Fair Price
% Col 4: Production / Fair Price

payback_times = [
    125, 125, 60, 60;   % Data for System 300
    106, 80,  33, 25;   % Data for System 600
    114, 56,  63, 31    % Data for System 800
];

% 2. Create the grouped bar chart
figure; % Create a new figure window
b = bar(payback_times, 'grouped');

% 3. Customize the chart for clarity
% Add title and axis labels
title('Comparison of Payback Times Across Systems');
ylabel('Payback Time (Years)');
xlabel('System Scenario');

% Set the x-axis tick labels to match your systems
set(gca, 'xticklabel', {'System 300', 'System 600', 'System 800'});

% Add a descriptive legend
legend('Consumption - Cost Quan', 'Production - Cost Quan', ...
       'Consumption - Fair Price', 'Production - Fair Price', ...
       'Location', 'northeast');

% --- Optional: Add data labels on top of each bar ---
% This can be a bit crowded with 4 bars, but useful.
for i = 1:length(b)
    xtips = b(i).XEndPoints;
    ytips = b(i).YEndPoints;
    % Place text slightly above the bar
    labels = string(b(i).YData);
    text(xtips, ytips, labels, 'HorizontalAlignment','center',...
        'VerticalAlignment','bottom')
end

grid on; % Add a grid for better readability