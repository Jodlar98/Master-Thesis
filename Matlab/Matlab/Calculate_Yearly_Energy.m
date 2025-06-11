% Calculate_Yearly_Energy.m

clear; clc; close all;

fprintf('--- Yearly and Seasonal Energy Calculation ---\n');

%% --- Configuration ---
systems_to_analyze = [1, 2, 3]; % Corresponds to System ID 1, 2, 3
panel_wattages_wpp = [40, 20, 10]; % Wpp for System 1, 2, 3 respectively
base_panel_wattage_for_raw_profile = 40; % The raw production profile is for a 40Wpp panel

% Define days in each month (non-leap year)
days_in_month_nonleap = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]; % Jan to Dec

% Define months for seasons
winter_month_indices = [10, 11, 12, 1, 2, 3]; % October to March
summer_month_indices = [4, 5, 6, 7, 8, 9];   % April to September

num_winter_days = sum(days_in_month_nonleap(winter_month_indices));
num_summer_days = sum(days_in_month_nonleap(summer_month_indices));
fprintf('Number of Winter days: %d, Summer days: %d, Total: %d\n', num_winter_days, num_summer_days, num_winter_days + num_summer_days);

% Effectiveness factor to use for calculating "generated energy"
% Options: 'average' or 'optimal'. Let's use average for typical generation.
effectiveness_type_to_use = 'average'; 

%% --- 1. Load Production Data and Factors ---
fprintf('\nLoading production data and factors...\n');
production_data_file = fullfile('scenario_outputs_seasonal_effectiveness', 'all_panels_seasonal_effectiveness_data.mat');
try
    prod_data_loaded = load(production_data_file);
    fprintf('Loaded production data from: %s\n', production_data_file);
catch ME_prod_load
    fprintf('ERROR: Could not load production data file: %s\n', production_data_file);
    fprintf('Message: %s\nEnsure SlopesNSeasonal_analyze.m has been run.\n', ME_prod_load.message);
    return;
end

% Extract necessary production components
% Deriving raw hourly production for 40Wpp base panel (before eff/loss from that script)
panel_name_base = '40Wpp'; % Raw profiles are based on this
valid_panel_name_base = matlab.lang.makeValidName(panel_name_base);

if ~isfield(prod_data_loaded.all_results, valid_panel_name_base)
    fprintf('ERROR: Base panel %s not found in loaded production data.\n', panel_name_base);
    return;
end

[optimal_eff_value_from_factors, optimal_eff_idx] = max(prod_data_loaded.effectiveness_factors);
optimal_eff_scenario_name = prod_data_loaded.effectiveness_scenario_names{optimal_eff_idx};
optimal_eff_name_struct = matlab.lang.makeValidName(optimal_eff_scenario_name);

if ~isfield(prod_data_loaded.all_results.(valid_panel_name_base), optimal_eff_name_struct)
    fprintf('ERROR: Optimal effectiveness scenario (%s) not found for base panel %s.\n', optimal_eff_scenario_name, panel_name_base);
    return;
end

soiling_loss_factor = prod_data_loaded.soiling_loss_factor;
general_loss_factor = prod_data_loaded.general_loss_factor;
combined_loss_multiplier_original_script = 1 - (soiling_loss_factor + general_loss_factor);

if combined_loss_multiplier_original_script <= 1e-6 || optimal_eff_value_from_factors <= 1e-6
    fprintf('ERROR: Original loss multiplier or optimal effectiveness factor is too small, cannot derive raw production.\n');
    return;
end

% This is the seasonally averaged hourly power [W] from the 40Wpp CSV, before specific effectiveness and losses
raw_hourly_prod_WINTER_base40Wpp = (prod_data_loaded.all_results.(valid_panel_name_base).(optimal_eff_name_struct).Winter / ...
                                   combined_loss_multiplier_original_script) / optimal_eff_value_from_factors;
raw_hourly_prod_WINTER_base40Wpp(isnan(raw_hourly_prod_WINTER_base40Wpp)) = 0;

raw_hourly_prod_SUMMER_base40Wpp = (prod_data_loaded.all_results.(valid_panel_name_base).(optimal_eff_name_struct).Summer / ...
                                   combined_loss_multiplier_original_script) / optimal_eff_value_from_factors;
raw_hourly_prod_SUMMER_base40Wpp(isnan(raw_hourly_prod_SUMMER_base40Wpp)) = 0;

% Determine effectiveness factor to apply for "generated energy"
if strcmp(effectiveness_type_to_use, 'average')
    eff_to_apply = mean(prod_data_loaded.effectiveness_factors);
    fprintf('Using AVERAGE effectiveness factor for generation: %.3f\n', eff_to_apply);
else % optimal
    eff_to_apply = optimal_eff_value_from_factors;
    fprintf('Using OPTIMAL effectiveness factor for generation: %.3f\n', eff_to_apply);
end
% Loss multiplier to apply for actual generation calculation
actual_system_loss_multiplier = 1 - (soiling_loss_factor + general_loss_factor); % Same as combined_loss_multiplier_original_script

%% --- 2. Load Consumption Data (Per-System ID) ---
fprintf('\nLoading per-system consumption data...\n');
try
    winter_cons_mat = load("mean_consumption_SHS_all_systems_winter_with_ci.mat", "per_system_id_hourly_winter", "max_system_id_winter");
    summer_cons_mat = load("mean_consumption_SHS_all_systems_summer_with_ci.mat", "per_system_id_hourly_summer", "max_system_id_summer");
    fprintf('Loaded per-system consumption data from MAT files.\n');
catch ME_cons_load
    fprintf('ERROR: Could not load per-system consumption MAT files.\n');
    fprintf('Message: %s\nEnsure Result_Data.m has been run successfully.\n', ME_cons_load.message);
    return;
end

%% --- 3. Initialize Results Storage ---
num_systems = length(systems_to_analyze);
system_names = arrayfun(@(x) sprintf('System %d (%dWpp)', x, panel_wattages_wpp(find(systems_to_analyze==x,1))), systems_to_analyze, 'UniformOutput', false);

seasonal_generated_Wh = zeros(num_systems, 2); % Col 1: Winter, Col 2: Summer
seasonal_consumed_Wh_original = zeros(num_systems, 2);
seasonal_consumed_Wh_corrected = zeros(num_systems, 2);

%% --- 4. Calculate Daily and Seasonal Energies per System ---
fprintf('\nCalculating daily and seasonal energies...\n');

for i = 1:num_systems
    sys_id = systems_to_analyze(i);
    sys_wpp = panel_wattages_wpp(i);
    production_scaling_factor = sys_wpp / base_panel_wattage_for_raw_profile;
    fprintf('--- Processing %s ---\n', system_names{i});

    % --- WINTER ---
    % Production
    actual_hourly_prod_sys_winter_W = raw_hourly_prod_WINTER_base40Wpp * production_scaling_factor * eff_to_apply * actual_system_loss_multiplier;
    daily_prod_sys_winter_Wh = sum(actual_hourly_prod_sys_winter_W); % Sum of hourly Watts = daily Wh
    
    % Consumption
    hourly_cons_sys_winter_W = zeros(24,1);
    if sys_id <= winter_cons_mat.max_system_id_winter && size(winter_cons_mat.per_system_id_hourly_winter,2) >= sys_id
        hourly_cons_sys_winter_W = winter_cons_mat.per_system_id_hourly_winter(:, sys_id);
    else
        fprintf('Warning: Winter consumption data for System ID %d not available. Assuming zero consumption.\n', sys_id);
    end
    daily_cons_sys_winter_Wh_original = sum(hourly_cons_sys_winter_W);
    
    % Corrected Consumption (Winter)
    if daily_prod_sys_winter_Wh > daily_cons_sys_winter_Wh_original
        corrected_daily_cons_sys_winter_Wh = daily_cons_sys_winter_Wh_original;
    else
        corrected_daily_cons_sys_winter_Wh = daily_prod_sys_winter_Wh;
    end
    
    seasonal_generated_Wh(i, 1) = daily_prod_sys_winter_Wh * num_winter_days;
    seasonal_consumed_Wh_original(i, 1) = daily_cons_sys_winter_Wh_original * num_winter_days;
    seasonal_consumed_Wh_corrected(i, 1) = corrected_daily_cons_sys_winter_Wh * num_winter_days;

    % --- SUMMER ---
    % Production
    actual_hourly_prod_sys_summer_W = raw_hourly_prod_SUMMER_base40Wpp * production_scaling_factor * eff_to_apply * actual_system_loss_multiplier;
    daily_prod_sys_summer_Wh = sum(actual_hourly_prod_sys_summer_W);
    
    % Consumption
    hourly_cons_sys_summer_W = zeros(24,1);
    if sys_id <= summer_cons_mat.max_system_id_summer && size(summer_cons_mat.per_system_id_hourly_summer,2) >= sys_id
        hourly_cons_sys_summer_W = summer_cons_mat.per_system_id_hourly_summer(:, sys_id);
    else
        fprintf('Warning: Summer consumption data for System ID %d not available. Assuming zero consumption.\n', sys_id);
    end
    daily_cons_sys_summer_Wh_original = sum(hourly_cons_sys_summer_W);
    
    % Corrected Consumption (Summer)
    if daily_prod_sys_summer_Wh > daily_cons_sys_summer_Wh_original
        corrected_daily_cons_sys_summer_Wh = daily_cons_sys_summer_Wh_original;
    else
        corrected_daily_cons_sys_summer_Wh = daily_prod_sys_summer_Wh;
    end
    
    seasonal_generated_Wh(i, 2) = daily_prod_sys_summer_Wh * num_summer_days;
    seasonal_consumed_Wh_original(i, 2) = daily_cons_sys_summer_Wh_original * num_summer_days;
    seasonal_consumed_Wh_corrected(i, 2) = corrected_daily_cons_sys_summer_Wh * num_summer_days;
end

%% --- 5. Calculate Yearly Totals ---
yearly_generated_Wh = sum(seasonal_generated_Wh, 2); % Sum across columns (seasons)
yearly_consumed_Wh_corrected = sum(seasonal_consumed_Wh_corrected, 2);

%% --- 6. Display Results ---
fprintf('\n\n--- Seasonal and Yearly Energy Summary (Wh) ---\n');

% Create a table for display
SystemName = system_names';
WinterGen_Wh = seasonal_generated_Wh(:,1);
SummerGen_Wh = seasonal_generated_Wh(:,2);
YearlyGen_Wh = yearly_generated_Wh;
WinterCons_Wh = seasonal_consumed_Wh_corrected(:,1);
SummerCons_Wh = seasonal_consumed_Wh_corrected(:,2);
YearlyCons_Wh = yearly_consumed_Wh_corrected;

results_table = table(SystemName, WinterGen_Wh, SummerGen_Wh, YearlyGen_Wh, WinterCons_Wh, SummerCons_Wh, YearlyCons_Wh);

disp(results_table);

fprintf('\nNotes:\n');
fprintf('- "Generated" energy is calculated using %s effectiveness factor (%.3f) and system losses.\n', effectiveness_type_to_use, eff_to_apply);
fprintf('- "Consumed" energy is based on the rule: if Gen > Cons_orig, Cons = Cons_orig; else Cons = Gen.\n');
fprintf('- Winter: %d days, Summer: %d days.\n', num_winter_days, num_summer_days);

% Store results in workspace variables if needed for further use
CalculatedEnergyResults = struct();
CalculatedEnergyResults.table = results_table;
CalculatedEnergyResults.seasonal_generated_Wh = seasonal_generated_Wh;
CalculatedEnergyResults.seasonal_consumed_Wh_corrected = seasonal_consumed_Wh_corrected;
CalculatedEnergyResults.yearly_generated_Wh = yearly_generated_Wh;
CalculatedEnergyResults.yearly_consumed_Wh_corrected = yearly_consumed_Wh_corrected;
CalculatedEnergyResults.info.effectiveness_type_used = effectiveness_type_to_use;
CalculatedEnergyResults.info.effectiveness_factor_applied = eff_to_apply;
CalculatedEnergyResults.info.loss_soiling = soiling_loss_factor;
CalculatedEnergyResults.info.loss_general = general_loss_factor;
CalculatedEnergyResults.info.num_winter_days = num_winter_days;
CalculatedEnergyResults.info.num_summer_days = num_summer_days;

fprintf('\nCalculation complete. Results are in the table above and in the "CalculatedEnergyResults" struct.\n');