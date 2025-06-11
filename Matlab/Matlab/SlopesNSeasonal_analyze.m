% MATLAB Script for Time Series Power Production Data Analysis
% Includes seasonal analysis (winter/summer) and effectiveness scenarios

% --- Configuration ---
output_folder = 'scenario_outputs_seasonal_effectiveness'; % Folder for saving results
% Define panel configurations: Give each panel a name and specify the CSV file.
panel_configs = {
    struct('name', '40Wpp', 'csv_file', 'Radiation_withSlopes\Optimal_slope_no_loss_40Wpp.csv'), ...
    struct('name', '20Wpp', 'csv_file', 'Radiation_withSlopes\Optimal_slope_no_loss_20Wpp.csv'), ...
    struct('name', '10Wpp', 'csv_file', 'Radiation_withSlopes\Optimal_slope_no_loss_10Wpp.csv')
};

% Define effectiveness factors
try
    load("Radiation_withSlopes\slope_effectiveness.mat", "effekt"); % Loads the 'effekt' variable
    effectiveness_factors = effekt; % Assign to effectiveness_factors. Assumes 'effekt' is a 1D array.
catch ME_load_eff
    fprintf('WARNING: Could not load slope_effectiveness.mat. Using default effectiveness factors.\nError: %s\n', ME_load_eff.message);
    effectiveness_factors = [1.0, 0.95, 0.9, 0.85, 0.8, 0.75, 0.7]; % Default values
end

% Generate unique scenario names, this handles duplicate effectiveness_factors correctly
% by including the index 'i' in the name.
effectiveness_scenario_names = arrayfun(@(x,i) sprintf('EffScen%d_%.2f', i, x), effectiveness_factors, (1:length(effectiveness_factors))', 'UniformOutput', false);

% Define loss factors
soiling_loss_factor = 0.1; 
general_loss_factor = 0.14; 
combined_loss_multiplier = 1 - (soiling_loss_factor + general_loss_factor);
if combined_loss_multiplier < 0
    warning('Combined loss factors exceed 100%! Setting to 0.');
    combined_loss_multiplier = 0;
end

% Window size for movmean 
smoothing_window_size = 1; 

% Define months for seasons
winter_months = [10, 11, 12, 1, 2, 3]; % October to March
summer_months = [4, 5, 6, 7, 8, 9];   % April to September

% --- Initialization ---
if ~exist(output_folder, 'dir')
   mkdir(output_folder);
end
all_results = struct(); 
fprintf('Starting processing of panels and effectiveness scenarios...\n');

% --- Main loop for processing panel configurations ---
for p_idx = 1:length(panel_configs)
    panel_name = panel_configs{p_idx}.name;
    current_csv_file = panel_configs{p_idx}.csv_file;
    valid_panel_name = matlab.lang.makeValidName(panel_name);
    fprintf('Processing panel: %s (from file: %s)\n', panel_name, current_csv_file);
    
    try
        opts = detectImportOptions(current_csv_file);
        opts.VariableNamingRule = 'preserve';
        opts.EmptyLineRule = 'skip';
        time_var_idx = find(strcmp(opts.VariableNames, 'time'));
        if ~isempty(time_var_idx)
            opts = setvartype(opts, 'time', 'string');
        end
        T_panel_data = readtable(current_csv_file, opts);
    catch ME
        fprintf('WARNING: Could not read CSV file "%s" for panel "%s". Panel skipped.\nError message: %s\n', ...
                current_csv_file, panel_name, ME.message);
        continue;
    end
    
    if ~ismember('time', T_panel_data.Properties.VariableNames) || ~ismember('P', T_panel_data.Properties.VariableNames)
        fprintf('WARNING: CSV file "%s" for panel "%s" is missing "time" or "P" column. Panel skipped.\n', ...
                current_csv_file, panel_name);
        continue;
    end

    % Convert 'time' column to datetime objects, parse as UTC, then convert to CET/CEST
    try
        if isstring(T_panel_data.time) || iscell(T_panel_data.time)
            % Parse time as UTC
            T_panel_data.time = datetime(T_panel_data.time, 'InputFormat', 'yyyyMMdd:HHmm', 'TimeZone', 'UTC');
        elseif isdatetime(T_panel_data.time)
            if isempty(T_panel_data.time.TimeZone)
                fprintf('INFO: Time column for panel %s was datetime but without TimeZone. Assuming UTC.\n', panel_name);
                T_panel_data.time.TimeZone = 'UTC'; % Assume UTC if naive
            elseif ~strcmp(T_panel_data.time.TimeZone, 'UTC')
                fprintf('INFO: Time column for panel %s was datetime in zone %s. Converting to UTC.\n', panel_name, T_panel_data.time.TimeZone);
                T_panel_data.time.TimeZone = 'UTC'; % Convert to UTC
            end
        else
             error('Time column is not in a recognizable cell/string format for conversion or already datetime.');
        end
        
        % Convert from UTC to 'Europe/Tirane' (CET/CEST equivalent for Albania)
        T_panel_data.time.TimeZone = 'Europe/Tirane'; 
    catch ME
        fprintf('WARNING: Could not convert "time" column in file "%s" for panel "%s". \nMake sure format is yyyyMMDD:HHmm (UTC). Panel skipped.\nError message: %s\n', ...
                current_csv_file, panel_name, ME.message);
        continue;
    end

    if ~isnumeric(T_panel_data.P)
        try
            if iscell(T_panel_data.P) % Handle if P is cell array of strings
                 T_panel_data.P = cellfun(@str2double, T_panel_data.P);
            elseif isstring(T_panel_data.P) % Handle if P is string array
                 T_panel_data.P = str2double(T_panel_data.P);
            end
        catch ME_P
             fprintf('WARNING: "P" column in file "%s" for panel "%s" is not numeric and could not be converted. Panel skipped.\nError message: %s\n', ...
                current_csv_file, panel_name, ME_P.message);
            continue;
        end
    end    
    T_panel_data(isnan(T_panel_data.P) | isnat(T_panel_data.time), :) = [];
    if isempty(T_panel_data)
        fprintf('INFO: No valid data remaining for panel %s after removing NaN/NaT. Skipping.\n', panel_name);
        continue;
    end

    % --- Loop through effectiveness scenarios ---
    for eff_idx = 1:length(effectiveness_factors)
        current_eff_factor = effectiveness_factors(eff_idx);
        % current_eff_name will be unique due to 'EffScen%d' part
        current_eff_name = matlab.lang.makeValidName(effectiveness_scenario_names{eff_idx});
        fprintf('  Processing for effectiveness scenario: %s (Factor: %.2f)\n', effectiveness_scenario_names{eff_idx}, current_eff_factor);
        P_adjusted = T_panel_data.P * current_eff_factor * combined_loss_multiplier;
        
        % Seasonal average calculation (now using CET/CEST times from 'Europe/Tirane')
        % Winter
        winter_data_indices = ismember(month(T_panel_data.time), winter_months);
        T_winter = table(T_panel_data.time(winter_data_indices), P_adjusted(winter_data_indices), ...
                         'VariableNames', {'time', 'P_eff'});        
        mean_hourly_winter = NaN(24, 1);
        if ~isempty(T_winter)
            for h = 0:23 % Hours 0-23 LOCAL TIME
                hour_specific_data_winter = T_winter.P_eff(hour(T_winter.time) == h);
                if ~isempty(hour_specific_data_winter)
                    mean_hourly_winter(h+1) = mean(hour_specific_data_winter, 'omitnan');
                end
            end
            if smoothing_window_size > 1 && smoothing_window_size <= 24
                mean_hourly_winter = movmean(mean_hourly_winter, smoothing_window_size, 'omitnan', 'Endpoints','shrink');
            end
        end
        all_results.(valid_panel_name).(current_eff_name).Winter = mean_hourly_winter;
        
        % Summer
        summer_data_indices = ismember(month(T_panel_data.time), summer_months);
        T_summer = table(T_panel_data.time(summer_data_indices), P_adjusted(summer_data_indices), ...
                         'VariableNames', {'time', 'P_eff'});
        mean_hourly_summer = NaN(24, 1);
        if ~isempty(T_summer)
            for h = 0:23 % Hours 0-23 LOCAL TIME
                hour_specific_data_summer = T_summer.P_eff(hour(T_summer.time) == h);
                if ~isempty(hour_specific_data_summer)
                    mean_hourly_summer(h+1) = mean(hour_specific_data_summer, 'omitnan');
                end
            end
            if smoothing_window_size > 1 && smoothing_window_size <= 24
                mean_hourly_summer = movmean(mean_hourly_summer, smoothing_window_size, 'omitnan', 'Endpoints','shrink');
            end
        end
        all_results.(valid_panel_name).(current_eff_name).Summer = mean_hourly_summer;
    end 
    fprintf('Finished processing for panel: %s\n', panel_name);
end 

% --- Save combined results ---
if ~isempty(fieldnames(all_results))
    combined_save_filename_mat = fullfile(output_folder, 'all_panels_seasonal_effectiveness_data.mat');
    save(combined_save_filename_mat, 'all_results', 'effectiveness_factors', 'effectiveness_scenario_names', 'soiling_loss_factor', 'general_loss_factor', 'panel_configs');
    fprintf('Saved combined data to %s\n', combined_save_filename_mat);
else
    fprintf('No panels or scenarios processed. No data file saved.\n');
end

% --- Plotting ---
fprintf('Generating plots...\n');
hours_of_day_full = (0:23)'; % Full 24 hours for data indexing
panel_colors = lines(length(panel_configs)); 

% Winter plot
fig_winter = figure('Name', 'Average Hourly Production - Winter (Local Time)', 'Position', [100, 100, 600, 400]);
hold on;
legend_handles_winter = gobjects(length(panel_configs), 1); 
legend_texts_winter = cell(length(panel_configs), 1);
valid_legend_entry_count_winter = 0;

for p_idx = 1:length(panel_configs)
    panel_name = panel_configs{p_idx}.name;
    valid_panel_name = matlab.lang.makeValidName(panel_name);

    if isfield(all_results, valid_panel_name)
        panel_hourly_data_winter_all_scenarios = []; 

        % This loop collects data from all scenarios, identified by their unique names
        for eff_idx = 1:length(effectiveness_factors) 
            current_eff_name_struct = matlab.lang.makeValidName(effectiveness_scenario_names{eff_idx});
            if isfield(all_results.(valid_panel_name), current_eff_name_struct) && ...
               isfield(all_results.(valid_panel_name).(current_eff_name_struct), 'Winter')
                
                winter_data_scenario = all_results.(valid_panel_name).(current_eff_name_struct).Winter; 
                if ~all(isnan(winter_data_scenario))
                    panel_hourly_data_winter_all_scenarios = [panel_hourly_data_winter_all_scenarios, winter_data_scenario(:)];
                end
            end
        end

        if ~isempty(panel_hourly_data_winter_all_scenarios) && size(panel_hourly_data_winter_all_scenarios,1) == 24
            min_prod_winter = min(panel_hourly_data_winter_all_scenarios, [], 2, 'omitnan'); 
            max_prod_winter = max(panel_hourly_data_winter_all_scenarios, [], 2, 'omitnan'); 
            avg_prod_winter = mean(panel_hourly_data_winter_all_scenarios, 2, 'omitnan');   

            nan_hours = isnan(min_prod_winter) | isnan(max_prod_winter) | isnan(avg_prod_winter);
            current_hours_of_day_plot = hours_of_day_full(~nan_hours); 
            current_min_prod = min_prod_winter(~nan_hours);
            current_max_prod = max_prod_winter(~nan_hours);
            current_avg_prod = avg_prod_winter(~nan_hours);

            if ~isempty(current_hours_of_day_plot)
                fill([current_hours_of_day_plot; flipud(current_hours_of_day_plot)], [current_max_prod; flipud(current_min_prod)], panel_colors(p_idx, :), ...
                     'FaceAlpha', 0.3, 'EdgeColor', 'none', 'HandleVisibility', 'off'); 
                
                h_avg_line = plot(current_hours_of_day_plot, current_avg_prod, ...
                                  'Color', panel_colors(p_idx, :), ...
                                  'LineWidth', 2.0, ... 
                                  'DisplayName', sprintf('%s Average', panel_name));
                
                valid_legend_entry_count_winter = valid_legend_entry_count_winter + 1;
                legend_handles_winter(valid_legend_entry_count_winter) = h_avg_line;
                legend_texts_winter{valid_legend_entry_count_winter} = sprintf('%s Average', panel_name);
            end
        end
    end
end

title('Average Hourly Production - Winter (Oct-Mar, Local Time)');
xlabel('Hour of Day (Local Time)');
ylabel('Average Produced Power [W]');
if valid_legend_entry_count_winter > 0
    legend(legend_handles_winter(1:valid_legend_entry_count_winter), legend_texts_winter(1:valid_legend_entry_count_winter), 'Location', 'northwest', 'FontSize', 8);
end
grid on;
xlim([5.5 20.5]); 
xticks(6:2:20); 
ylim([0, 20])
ylim_curr = ylim;
if ylim_curr(1) < 0 && ylim_curr(2) > 0 
    ylim([0, ylim_curr(2)]);
elseif ylim_curr(2) == 0 
    ylim([0, 1]);
end
hold off;
plot_filename_winter_png = fullfile(output_folder, 'plot_avg_hourly_prod_WINTER_LocalTime.png'); 
try
    saveas(fig_winter, plot_filename_winter_png);
    fprintf('Saved winter plot to %s\n', plot_filename_winter_png);
catch ME_save
    fprintf('Warning: Could not save winter plot %s. Error: %s\n', plot_filename_winter_png, ME_save.message);
end

% Summer plot
fig_summer = figure('Name', 'Average Hourly Production - Summer (Local Time)', 'Position', [150, 150, 600, 400]);
hold on;
legend_handles_summer = gobjects(length(panel_configs), 1);
legend_texts_summer = cell(length(panel_configs), 1);
valid_legend_entry_count_summer = 0;

for p_idx = 1:length(panel_configs)
    panel_name = panel_configs{p_idx}.name;
    valid_panel_name = matlab.lang.makeValidName(panel_name);

    if isfield(all_results, valid_panel_name)
        panel_hourly_data_summer_all_scenarios = []; 

        for eff_idx = 1:length(effectiveness_factors)
            current_eff_name_struct = matlab.lang.makeValidName(effectiveness_scenario_names{eff_idx});
             if isfield(all_results.(valid_panel_name), current_eff_name_struct) && ...
               isfield(all_results.(valid_panel_name).(current_eff_name_struct), 'Summer')
                summer_data_scenario = all_results.(valid_panel_name).(current_eff_name_struct).Summer;
                if ~all(isnan(summer_data_scenario))
                    panel_hourly_data_summer_all_scenarios = [panel_hourly_data_summer_all_scenarios, summer_data_scenario(:)];
                end
            end
        end

        if ~isempty(panel_hourly_data_summer_all_scenarios) && size(panel_hourly_data_summer_all_scenarios,1) == 24
            min_prod_summer = min(panel_hourly_data_summer_all_scenarios, [], 2, 'omitnan');
            max_prod_summer = max(panel_hourly_data_summer_all_scenarios, [], 2, 'omitnan');
            avg_prod_summer = mean(panel_hourly_data_summer_all_scenarios, 2, 'omitnan');

            nan_hours = isnan(min_prod_summer) | isnan(max_prod_summer) | isnan(avg_prod_summer);
            current_hours_of_day_plot = hours_of_day_full(~nan_hours); 
            current_min_prod = min_prod_summer(~nan_hours);
            current_max_prod = max_prod_summer(~nan_hours);
            current_avg_prod = avg_prod_summer(~nan_hours);
            
            if ~isempty(current_hours_of_day_plot)
                fill([current_hours_of_day_plot; flipud(current_hours_of_day_plot)], [current_max_prod; flipud(current_min_prod)], panel_colors(p_idx, :), ...
                     'FaceAlpha', 0.3, 'EdgeColor', 'none', 'HandleVisibility', 'off');
                
                h_avg_line = plot(current_hours_of_day_plot, current_avg_prod, ...
                                  'Color', panel_colors(p_idx, :), ...
                                  'LineWidth', 2.0, ...
                                  'DisplayName', sprintf('%s Average', panel_name));
                
                valid_legend_entry_count_summer = valid_legend_entry_count_summer + 1;
                legend_handles_summer(valid_legend_entry_count_summer) = h_avg_line;
                legend_texts_summer{valid_legend_entry_count_summer} = sprintf('%s Average', panel_name);
            end
        end
    end
end

title('Average Hourly Production - Summer (Apr-Sep, Local Time)');
xlabel('Hour of Day (Local Time)');
ylabel('Average Produced Power [W]');
if valid_legend_entry_count_summer > 0
    legend(legend_handles_summer(1:valid_legend_entry_count_summer), legend_texts_summer(1:valid_legend_entry_count_summer), 'Location', 'northwest', 'FontSize', 8);
end
grid on;
xlim([5.5 20.5]); 
xticks(6:2:20); 
ylim([0, 20])
ylim_curr = ylim;
if ylim_curr(1) < 0 && ylim_curr(2) > 0
    ylim([0, ylim_curr(2)]);
elseif ylim_curr(2) == 0
    ylim([0, 1]);
end
hold off;
plot_filename_summer_png = fullfile(output_folder, 'plot_avg_hourly_prod_SUMMER_LocalTime.png'); 
try
    saveas(fig_summer, plot_filename_summer_png);
    fprintf('Saved summer plot to %s\n', plot_filename_summer_png);
catch ME_save
    fprintf('Warning: Could not save summer plot %s. Error: %s\n', plot_filename_summer_png, ME_save.message);
end

fprintf('Processing and plotting completed. Results are saved in the folder "%s".\n', output_folder);