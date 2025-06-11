%% Charging/Discharging Parameters & Battery Setup
vCell = 12.8; % Cell voltage
Kp   = 100; % Proportional gain CV controller
Ki   = 10;  % Integral gain CV controller
Kaw  = 1;   % Antiwindup gain CV controller
Ts   = 1;   % Sample time (s)
Wh_system1 = 80;    % Battery capacity in Watt-hours
Wh_system2 = 58;    % Battery capacity in Watt-hours
Wh_system3 = 29;    % Battery capacity in Watt-hours

initialSOC = 0.6; % Initial State of Charge
AH_system1 = Wh_system1/vCell;    % Battery capacity in Ampere-hours
AH_system2 = Wh_system2/vCell;    % Battery capacity in Ampere-hours
AH_system3 = Wh_system3/vCell;    % Battery capacity in Ampere-hours
fprintf('Simulink input data script started.\n');

%% --- SOLAR PRODUCTION DATA ---
% (This section remains the same - assuming it's correct from previous steps)
fprintf('Loading and processing solar production data...\n');
data_source_file = fullfile('scenario_outputs_seasonal_effectiveness', 'all_panels_seasonal_effectiveness_data.mat');
try
    load(data_source_file, ...
         'all_results', 'effectiveness_factors', 'effectiveness_scenario_names', ...
         'soiling_loss_factor', 'general_loss_factor', 'panel_configs');
    fprintf('Successfully loaded production data from %s\n', data_source_file);
catch ME_prod % Changed variable name for catch
    fprintf('ERROR: Could not load production data from %s.\n', data_source_file);
    fprintf('Ensure SlopesNSeasonal_analyze.m has run. Error: %s\n', ME_prod.message);
    return; 
end
sim_soiling_loss_factor = soiling_loss_factor;
sim_general_loss_factor = general_loss_factor;
if isempty(effectiveness_factors)
    sim_optimal_effectiveness_factor = 1.0; sim_avg_effectiveness_factor = 0.85; 
else
    sim_optimal_effectiveness_factor = max(effectiveness_factors); sim_avg_effectiveness_factor = mean(effectiveness_factors);
end
fprintf('Production Factors: Soiling=%.2f, General=%.2f, OptimalEff=%.3f, AvgEff=%.3f\n', sim_soiling_loss_factor, sim_general_loss_factor, sim_optimal_effectiveness_factor, sim_avg_effectiveness_factor);
panel_name_to_use = '40Wpp'; 
valid_panel_name = matlab.lang.makeValidName(panel_name_to_use);
if ~isfield(all_results, valid_panel_name), fprintf('ERROR: Panel "%s" not found for production.\n', panel_name_to_use); return; end
[opt_eff_val_from_factors, opt_eff_idx] = max(effectiveness_factors);
if isempty(opt_eff_idx), fprintf('ERROR: No optimal effectiveness index for production.\n'); return; end
optimal_eff_scenario_name_from_list = effectiveness_scenario_names{opt_eff_idx};
optimal_eff_name_struct = matlab.lang.makeValidName(optimal_eff_scenario_name_from_list);
if ~isfield(all_results.(valid_panel_name), optimal_eff_name_struct), fprintf('ERROR: Optimal scenario "%s" not found for panel "%s".\n', optimal_eff_scenario_name_from_list, panel_name_to_use); return; end
combined_loss_multiplier_in_all_results = 1 - (soiling_loss_factor + general_loss_factor);
if combined_loss_multiplier_in_all_results <= 1e-6, fprintf('ERROR: Original production combined_loss_multiplier is too small.\n'); return; end
if opt_eff_val_from_factors <= 1e-6, fprintf('ERROR: Optimal production effectiveness factor is too small.\n'); return; end
prod_optimal_eff_winter_inc_losses = all_results.(valid_panel_name).(optimal_eff_name_struct).Winter;
raw_hourly_prod_winter = (prod_optimal_eff_winter_inc_losses / combined_loss_multiplier_in_all_results) / opt_eff_val_from_factors;
raw_hourly_prod_winter(isnan(raw_hourly_prod_winter)) = 0; 
prod_optimal_eff_summer_inc_losses = all_results.(valid_panel_name).(optimal_eff_name_struct).Summer;
raw_hourly_prod_summer = (prod_optimal_eff_summer_inc_losses / combined_loss_multiplier_in_all_results) / opt_eff_val_from_factors;
raw_hourly_prod_summer(isnan(raw_hourly_prod_summer)) = 0; 
fprintf('Raw hourly production profiles for %s (Winter, Summer) extracted.\n', panel_name_to_use);
num_days = 14; hours_per_day = 24; seconds_per_hour = 3600; total_hours = num_days * hours_per_day;
extended_time_simulink = (0:seconds_per_hour:(total_hours - 1) * seconds_per_hour)';
hourly_prod_data_w = raw_hourly_prod_winter(:); repeated_prod_daily_w = repmat(hourly_prod_data_w', num_days, 1); 
repeated_prod_vector_w = reshape(repeated_prod_daily_w', [], 1); 
simProd_WINTER_raw = [extended_time_simulink, repeated_prod_vector_w];
fprintf('simProd_WINTER_raw (%.0f-day raw production) created.\n', num_days);
hourly_prod_data_s = raw_hourly_prod_summer(:); repeated_prod_daily_s = repmat(hourly_prod_data_s', num_days, 1); 
repeated_prod_vector_s = reshape(repeated_prod_daily_s', [], 1); 
simProd_SUMMER_raw = [extended_time_simulink, repeated_prod_vector_s];
fprintf('simProd_SUMMER_raw (%.0f-day raw production) created.\n', num_days);

%% --- SHS CONSUMPTION DATA (Loaded from Processed MAT files from Result_Data.m) ---
fprintf('Loading and processing SHS consumption data from MAT files...\n');

% Initialize output variables
simCons_WINTER_mean = [extended_time_simulink, zeros(length(extended_time_simulink),1)]; 
simCons_SUMMER_mean = [extended_time_simulink, zeros(length(extended_time_simulink),1)]; 

% Define which System IDs you want to load (e.g., systems 1, 2, and 3)
systems_to_extract_ids = [1, 2, 3]; % These are the actual System IDs (e.g., from 5th element)
num_selected_systems = length(systems_to_extract_ids);

% Pre-allocate cell arrays for per-system Simulink data by actual ID
% We use a structure to store these for easier access by name later if needed
simCons_per_system_WINTER = struct();
simCons_per_system_SUMMER = struct();

% --- Load and Process Winter Consumption Data from MAT ---
try
    winter_cons_mat_file = "mean_consumption_SHS_all_systems_winter_with_ci.mat";
    winter_cons_data = load(winter_cons_mat_file);
    fprintf('Loaded Winter consumption data from %s\n', winter_cons_mat_file);

    % Overall Mean Winter Consumption (should be 24x1 from Result_Data.m)
    mean_hourly_winter_cons = winter_cons_data.mean_current_per_hour_winter;
    if isrow(mean_hourly_winter_cons), mean_hourly_winter_cons = mean_hourly_winter_cons'; end
    if length(mean_hourly_winter_cons) ~= 24
        fprintf('Adjusting winter mean consumption profile to 24h.\n');
        temp_profile = zeros(24,1); % Ensure it's 24x1
        % hours_axis_for_table is 0-23. Map to 1-24 indices
        valid_hours_idx = winter_cons_data.hours_axis_for_table + 1; 
        % Ensure indices are within bounds and data length matches
        src_len = length(mean_hourly_winter_cons);
        map_len = length(valid_hours_idx);
        len_to_map = min(src_len, map_len);
        temp_profile(valid_hours_idx(1:len_to_map)) = mean_hourly_winter_cons(1:len_to_map);
        mean_hourly_winter_cons = temp_profile;
    end
    mean_hourly_winter_cons(isnan(mean_hourly_winter_cons)) = 0;
    
    temp_data_w_mean = mean_hourly_winter_cons(:);
    repeated_daily_w_mean = repmat(temp_data_w_mean', num_days, 1);
    simCons_WINTER_mean = [extended_time_simulink, reshape(repeated_daily_w_mean', [], 1)];
    fprintf('simCons_WINTER_mean (overall average) created.\n');

    % Per-System ID Winter Consumption
    if isfield(winter_cons_data, 'per_system_id_hourly_winter') && ...
       isfield(winter_cons_data, 'max_system_id_winter')
        all_systems_winter_profiles = winter_cons_data.per_system_id_hourly_winter; % Should be 24 x max_system_id_winter
        
        for k = 1:num_selected_systems
            sys_id_to_load = systems_to_extract_ids(k);
            var_name_winter = sprintf('simCons_System%d_WINTER', sys_id_to_load);
            if sys_id_to_load <= winter_cons_data.max_system_id_winter && sys_id_to_load > 0 && ...
               size(all_systems_winter_profiles, 2) >= sys_id_to_load % Check column exists
                
                system_k_winter_profile = all_systems_winter_profiles(:, sys_id_to_load);
                system_k_winter_profile(isnan(system_k_winter_profile)) = 0; 
                
                temp_sys_data_w = system_k_winter_profile(:);
                repeated_sys_daily_w = repmat(temp_sys_data_w', num_days, 1);
                simCons_per_system_WINTER.(sprintf('System%d', sys_id_to_load)) = [extended_time_simulink, reshape(repeated_sys_daily_w', [], 1)];
                assignin('base', var_name_winter, simCons_per_system_WINTER.(sprintf('System%d', sys_id_to_load))); % Make it a direct variable
                fprintf('%s created.\n', var_name_winter);
            else
                fprintf('Warning: System ID %d out of bounds for Winter data (max ID: %d). Using zeros for %s.\n', sys_id_to_load, winter_cons_data.max_system_id_winter, var_name_winter);
                assignin('base', var_name_winter, [extended_time_simulink, zeros(length(extended_time_simulink),1)]);
            end
        end
    else
        fprintf('Warning: Per-system ID winter consumption data not found in MAT file. Using zeros for selected systems.\n');
        for k = 1:num_selected_systems
            sys_id_to_load = systems_to_extract_ids(k);
            var_name_winter = sprintf('simCons_System%d_WINTER', sys_id_to_load);
            assignin('base', var_name_winter, [extended_time_simulink, zeros(length(extended_time_simulink),1)]);
        end
    end
catch ME_cons_winter_load
    fprintf('WARNING: Could not load or process Winter consumption MAT file. Using zeros.\n');
    fprintf('Warning message: %s\n', ME_cons_winter_load.message);
    % simCons_WINTER_mean already initialized with zeros
    for k = 1:num_selected_systems
            sys_id_to_load = systems_to_extract_ids(k);
            var_name_winter = sprintf('simCons_System%d_WINTER', sys_id_to_load);
            assignin('base', var_name_winter, [extended_time_simulink, zeros(length(extended_time_simulink),1)]);
    end
end

% --- Load and Process Summer Consumption Data from MAT ---
try
    summer_cons_mat_file = "mean_consumption_SHS_all_systems_summer_with_ci.mat";
    summer_cons_data = load(summer_cons_mat_file);
    fprintf('Loaded Summer consumption data from %s\n', summer_cons_mat_file);

    mean_hourly_summer_cons = summer_cons_data.mean_current_per_hour_summer;
    if isrow(mean_hourly_summer_cons), mean_hourly_summer_cons = mean_hourly_summer_cons'; end
    if length(mean_hourly_summer_cons) ~= 24
        fprintf('Adjusting summer mean consumption profile to 24h.\n');
        temp_profile = zeros(24,1);
        valid_hours_idx = summer_cons_data.hours_axis_for_table + 1;
        src_len = length(mean_hourly_summer_cons);
        map_len = length(valid_hours_idx);
        len_to_map = min(src_len, map_len);
        temp_profile(valid_hours_idx(1:len_to_map)) = mean_hourly_summer_cons(1:len_to_map);
        mean_hourly_summer_cons = temp_profile;
    end
    mean_hourly_summer_cons(isnan(mean_hourly_summer_cons)) = 0;

    temp_data_s_mean = mean_hourly_summer_cons(:);
    repeated_daily_s_mean = repmat(temp_data_s_mean', num_days, 1);
    simCons_SUMMER_mean = [extended_time_simulink, reshape(repeated_daily_s_mean', [], 1)];
    fprintf('simCons_SUMMER_mean (overall average) created.\n');
    
    if isfield(summer_cons_data, 'per_system_id_hourly_summer') && ...
       isfield(summer_cons_data, 'max_system_id_summer')
        all_systems_summer_profiles = summer_cons_data.per_system_id_hourly_summer;

        for k = 1:num_selected_systems
            sys_id_to_load = systems_to_extract_ids(k);
            var_name_summer = sprintf('simCons_System%d_SUMMER', sys_id_to_load);
            if sys_id_to_load <= summer_cons_data.max_system_id_summer && sys_id_to_load > 0 && ...
               size(all_systems_summer_profiles, 2) >= sys_id_to_load
                
                system_k_summer_profile = all_systems_summer_profiles(:, sys_id_to_load);
                system_k_summer_profile(isnan(system_k_summer_profile)) = 0;

                temp_sys_data_s = system_k_summer_profile(:);
                repeated_sys_daily_s = repmat(temp_sys_data_s', num_days, 1);
                simCons_per_system_SUMMER.(sprintf('System%d', sys_id_to_load)) = [extended_time_simulink, reshape(repeated_sys_daily_s', [], 1)];
                assignin('base', var_name_summer, simCons_per_system_SUMMER.(sprintf('System%d', sys_id_to_load)));
                fprintf('%s created.\n', var_name_summer);
            else
                fprintf('Warning: System ID %d out of bounds for Summer data (max ID: %d). Using zeros for %s.\n', sys_id_to_load, summer_cons_data.max_system_id_summer, var_name_summer);
                 assignin('base', var_name_summer, [extended_time_simulink, zeros(length(extended_time_simulink),1)]);
            end
        end
    else
        fprintf('Warning: Per-system ID summer consumption data not found in MAT file. Using zeros for selected systems.\n');
        for k = 1:num_selected_systems
            sys_id_to_load = systems_to_extract_ids(k);
            var_name_summer = sprintf('simCons_System%d_SUMMER', sys_id_to_load);
            assignin('base', var_name_summer, [extended_time_simulink, zeros(length(extended_time_simulink),1)]);
        end
    end
catch ME_cons_summer_load
    fprintf('WARNING: Could not load or process Summer consumption MAT file. Using zeros.\n');
    fprintf('Warning message: %s\n', ME_cons_summer_load.message);
    % simCons_SUMMER_mean already initialized with zeros
    for k = 1:num_selected_systems
            sys_id_to_load = systems_to_extract_ids(k);
            var_name_summer = sprintf('simCons_System%d_SUMMER', sys_id_to_load);
            assignin('base', var_name_summer, [extended_time_simulink, zeros(length(extended_time_simulink),1)]);
    end
end

%% --- FINAL SUMMARY ---
fprintf('Simulink input data script finished.\n');
fprintf('The following variables are prepared for Simulink:\n');
fprintf('- simProd_WINTER_raw (Raw Production Winter, %dx%d)\n', size(simProd_WINTER_raw,1), size(simProd_WINTER_raw,2));
fprintf('- simProd_SUMMER_raw (Raw Production Summer, %dx%d)\n', size(simProd_SUMMER_raw,1), size(simProd_SUMMER_raw,2));
fprintf('- simCons_WINTER_mean (Mean SHS Consumption Winter, %dx%d)\n', size(simCons_WINTER_mean,1), size(simCons_WINTER_mean,2));
fprintf('- simCons_SUMMER_mean (Mean SHS Consumption Summer, %dx%d)\n', size(simCons_SUMMER_mean,1), size(simCons_SUMMER_mean,2));

for k=1:num_selected_systems
    sys_id_to_load = systems_to_extract_ids(k);
    var_name_w = sprintf('simCons_System%d_WINTER', sys_id_to_load);
    var_name_s = sprintf('simCons_System%d_SUMMER', sys_id_to_load);
    if evalin('base', sprintf('exist(''%s'', ''var'')', var_name_w)) % Check if var exists in base workspace
        data_w = evalin('base', var_name_w);
        fprintf('- %s (System %d Consumption Winter, %dx%d)\n', var_name_w, sys_id_to_load, size(data_w,1), size(data_w,2));
    end
    if evalin('base', sprintf('exist(''%s'', ''var'')', var_name_s))
        data_s = evalin('base', var_name_s);
        fprintf('- %s (System %d Consumption Summer, %dx%d)\n', var_name_s, sys_id_to_load, size(data_s,1), size(data_s,2));
    end
end

fprintf('- sim_soiling_loss_factor, sim_general_loss_factor, sim_optimal_effectiveness_factor, sim_avg_effectiveness_factor (Scalars)\n');
fprintf('- vCell, Kp, Ki, Kaw, Ts, Wh, initialSOC, AH (Parameters)\n');

% Clean up (optional)
% ...