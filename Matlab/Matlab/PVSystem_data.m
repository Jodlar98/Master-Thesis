%% Charging/Discharging Parameters
vCell = 12.8; % Cell voltage
Kp   = 100; % Proportional gain CV controller
Ki   = 10;  % Integral gain CV controller
Kaw  = 1;   % Antiwindup gain CV controller
Ts   = 1;   % Sample time (s)
%% Initial values and parameters
Wh = 80;
initialSOC = 0.6;
AH = Wh/vCell;
%% Production data
load("mean_hourlyProd_data.mat")
prod_month = cell(12, 1);
simProd = cell(12, 1); % Create a cell array to store simProd for all months
time = [0:3600:23*3600]; % Time vector
for m = 1:12
    prod_month{m} = mean_hourlyProd_data{m};% /vCell;
    production = rot90(prod_month{m}); % Rotate production data
    prod_month{m} = production;
end

%% Consumption data test
load("mean_hourlyLoad_data.mat")
cons_month_test = cell(12, 1);
households = 787000;
reduction = 350;
for m = 1:12
    cons_month_test{m} = (mean_hourlyLoad_data{m}*1000*1000)/(households*vCell*reduction);
end
time_cons_test = [0:3600:23*3600]; % Time vector
consumption_test = [cons_month_test{1}]; % Using the first month for the test consumption
consumption_test = rot90(consumption_test);
simCons_test = [time_cons_test', consumption_test'];
%% Consumption data SHS
load("mean_consumption_SHS_all_systems_winter.mat")
time_cons_shs = [0:3600:23*3600]; % Time vector
consumption_shs = [mean_current_per_hour]; % Production values
consumption_shs = rot90(consumption_shs);
simCons_shs = [time_cons_shs', consumption_shs'];

%% Extend simProds and simCons for 14 days
num_days = 14;
hours_per_day = 24;
seconds_per_hour = 3600;
total_hours = num_days * hours_per_day;

% Create the extended time vector (common for all months)
extended_time = (0:seconds_per_hour:(total_hours - 1) * seconds_per_hour)'; % Dimensions: 336x1

% Extend simProds and assign to individual variables
for m = 1:12
    % Extract the hourly production data for the month
    hourly_production = prod_month{m}'; % Ensure it's a row vector of 24 values

    % Create a matrix by repeating the hourly production for each day
    repeated_production_daily = repmat(hourly_production, num_days, 1); % Dimensions: 14x24

    % Reshape it into a single column vector
    repeated_production = reshape(repeated_production_daily', [], 1); % Dimensions: 336x1

    % Combine extended time and production data and assign to the corresponding variable
    if m == 1
        simProd1 = [extended_time, repeated_production];
    elseif m == 2
        simProd2 = [extended_time, repeated_production];
    elseif m == 3
        simProd3 = [extended_time, repeated_production];
    elseif m == 4
        simProd4 = [extended_time, repeated_production];
    elseif m == 5
        simProd5 = [extended_time, repeated_production];
    elseif m == 6
        simProd6 = [extended_time, repeated_production];
    elseif m == 7
        simProd7 = [extended_time, repeated_production];
    elseif m == 8
        simProd8 = [extended_time, repeated_production];
    elseif m == 9
        simProd9 = [extended_time, repeated_production];
    elseif m == 10
        simProd10 = [extended_time, repeated_production];
    elseif m == 11
        simProd11 = [extended_time, repeated_production];
    elseif m == 12
        simProd12 = [extended_time, repeated_production];
    end
end

% Extend simCons (assuming you want to extend the SHS consumption)
repeated_consumption_shs = repmat(simCons_shs(:, 2), num_days, 1);
extended_time_cons_shs = (0:seconds_per_hour:(total_hours - 1) * seconds_per_hour)';
simCons_extended_shs = [extended_time_cons_shs, repeated_consumption_shs];

% If you were using the test consumption:
repeated_consumption_test = repmat(simCons_test(:, 2), num_days, 1);
extended_time_cons_test = (0:seconds_per_hour:(total_hours - 1) * seconds_per_hour)';
simCons_extended_test = [extended_time_cons_test, repeated_consumption_test];

% Now you can choose which extended consumption you want to use as 'simCons'
% For example, to use the extended SHS consumption:
simCons = simCons_extended_shs;
