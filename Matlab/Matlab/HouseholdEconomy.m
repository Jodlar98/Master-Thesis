% MATLAB Code to create box plots for statistical analysis 📊

% 1. Define the data for each category from your image
%    NaN (Not a Number) is used as a placeholder for missing values.
income_data      = [396, 495, 600, 100, 0, 310, 500, 300, 350, 110, 700, 100, 270];
electricity_data = [30, 30, 35, 10, 0, 0, 50, 25, 30, 50, 100];
payment_data     = [10, 30, 15];
percent_data     = [7.6, 6.1, 5.8, 10.0, 10.0, 8.3, 14.3, 37.0];

% 2. Create a new figure window
fig1 = figure; % Creates a new figure window for the first chart
set (fig1, "Position", [100, 100, 900, 300])
sgtitle('Household Electricity Economics', 'FontSize', 14, 'FontWeight', 'bold');

% --- Subplot 1: Income ---
subplot(1, 4, 1); % Create axes in a 2x2 grid, position 1
boxplot(income_data);
title('Household Total Income');
ylabel('EUR');
grid on;

% --- Subplot 2: Electricity ---
subplot(1, 4, 2); % Position 2
boxplot(electricity_data);
title('Electricity Cost');
ylabel('EUR');
grid on;

% --- Subplot 3: Payment ---
subplot(1, 4, 3); % Position 3
boxplot(payment_data);
title('Payment Reduction');
ylabel('EUR');
grid on;

% --- Subplot 4: Percent of Income ---
subplot(1, 4, 4); % Position 4
boxplot(percent_data);
title('Electricity bill as % of Income');
ylabel('Percent (%)');
grid on;