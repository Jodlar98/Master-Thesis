% Set figure size
fig = figure;
set(fig, 'Position', [100, 100, 800, 400]);

% Read the CSV file
data = readtable('estat_ten00117_filtered_en.csv', 'PreserveVariableNames', true);

% Extract relevant data for Albania
albania_data = data(strcmp(data.('Geopolitical entity (reporting)'), 'Albania'), :);
years_albania = albania_data{:, 16}; % Extract years
prices_albania = albania_data{:, 18}; % Extract prices

% Albania has a missing data point for 2018. Interpolate it.
years_albania_full = 2013:2024; % Full range of years
prices_albania_full = interp1(years_albania, prices_albania, years_albania_full, 'linear'); % Linear interpolation

% Extract relevant data for European Union - 27 countries
eu_data = data(strcmp(data.('Geopolitical entity (reporting)'), 'European Union - 27 countries (from 2020)'), :);
years_eu = eu_data{:, 16}; % Extract years
prices_eu = eu_data{:, 18}; % Extract prices

% Plot the data for Albania
plot(years_albania_full, prices_albania_full, "-", 'LineWidth', 2, 'DisplayName', 'Albania', 'Color','red');
hold on;

% Highlight the interpolated point for Albania (2018)
interpolated_year = 2018;
interpolated_price = interp1(years_albania, prices_albania, interpolated_year, 'linear');
plot(interpolated_year, interpolated_price, 'ro', 'MarkerSize', 8, 'DisplayName', 'Interpolated Point'); % Red circle for the interpolated point

% Plot the data for EU-27
plot(years_eu, prices_eu, "--", 'LineWidth', 2, 'DisplayName', 'EU-27');
hold off;

% Add labels, title, and legend
xlabel('Year');
ylabel('Electricity Price (EUR/KWH)');
title('Electricity Prices in Albania and EU-27');
legend('Location', 'northwest');
xlim([2013 2024]);
grid on;

% Save the figure (optional)
% saveas(fig, 'electricity_prices.png');