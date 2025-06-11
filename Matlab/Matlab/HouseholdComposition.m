% MATLAB Code to create box plots for statistical analysis 📊

% 1. Define the data for each household category from your new image
household_size_data = [4, 3, 9, 9, 4, 6, 5, 3, 6, 2, 4, 7, 5];
kids_disabled_data  = [2, 1, 4, 2, 2, 4, 3, 2, 3, 0, 3, 3, 1];
elderly_data        = [2, 2, 1, 3, 2, 1, 1, 2, 1, 0, 1];
adults_work_data    = [0, 0, 4, 4, 0, 2, 2, 0, 2, 0, 4, 3];

% 2. Create a new figure window with a specific size and title
fig2 = figure; % Creates a new figure window
set (fig2, "Position", [100, 100, 900, 300]); % Set figure size and position
sgtitle('Household Composition', 'FontSize', 14, 'FontWeight', 'bold');

% --- Subplot 1: Total Household Size ---
subplot(1, 4, 1);
boxplot(household_size_data);
title('Total Household Size');
ylabel('Number of Persons');
grid on;

% --- Subplot 2: Kids or Disabled Persons ---
subplot(1, 4, 2);
boxplot(kids_disabled_data);
title('Kids or Disabled');
ylabel('Number of Persons');
grid on;

% --- Subplot 3: Elderly Persons ---
subplot(1, 4, 3);
boxplot(elderly_data);
title('Elderly');
ylabel('Number of Persons');
grid on;

% --- Subplot 4: Adults in Work ---
subplot(1, 4, 4);
boxplot(adults_work_data);
title('Working Age Adult');
ylabel('Number of Persons');
grid on;