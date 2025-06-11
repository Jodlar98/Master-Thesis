%% Definitions
maxpowerusb = 5;
maxpowerlight = 2;
maxpowertube = 4;
pusb = maxpowerusb/3;
pfixed = maxpowerlight/3;
ptube = maxpowertube/3;
fixedlights_idx = 1; 
tubelights_idx = 2;  
power_idx = 3;       
usb_idx = 4;         
system_id_idx = 5; % System ID is the 5th element

%% Result data
fprintf('Loading raw consumption data from Excel files...\n');
% (Your existing code for loading data_winter and data_summer, and determining numExcelSystemColumns...)
% Load Winter Data
data_winter = readtable("Results\Winter_data.xlsx");
system_cols_winter = startsWith(data_winter.Properties.VariableNames, 'System');
if any(system_cols_winter)
    numExcelSystemColumns_winter = sum(system_cols_winter); % Number of SystemX columns in Excel
else
    numExcelSystemColumns_winter = 19; % Fallback
    fprintf('Warning: Could not dynamically determine number of SystemX columns for Winter. Using default: %d\n', numExcelSystemColumns_winter);
end
fprintf('Number of SystemX Excel columns for Winter: %d\n', numExcelSystemColumns_winter);

% Load Summer Data
data_summer = readtable("Results\Summer_data.xlsx");
system_cols_summer = startsWith(data_summer.Properties.VariableNames, 'System');
if any(system_cols_summer)
    numExcelSystemColumns_summer = sum(system_cols_summer);
else
    numExcelSystemColumns_summer = 19; % Fallback
    fprintf('Warning: Could not dynamically determine number of SystemX columns for Summer. Using default: %d\n', numExcelSystemColumns_summer);
end
fprintf('Number of SystemX Excel columns for Summer: %d\n', numExcelSystemColumns_summer);


%% Process Winter Data - Collect All Readings
% (Your existing code for processing winter data into raw_per_system_id_data_winter and aggregated data...)
fprintf('Processing Winter consumption data...\n');
current_systems_winter_aggregated = []; 
hours_winter_aggregated = [];         
raw_per_system_id_data_winter = [];   

for m = 1:height(data_winter) 
    for n = 1:numExcelSystemColumns_winter 
        excel_system_col_name = ['System' num2str(n)];
        if ~ismember(excel_system_col_name, data_winter.Properties.VariableNames)
            continue; 
        end
        system_values_str = data_winter.(excel_system_col_name){m};
        if iscell(system_values_str), system_values_str = system_values_str{1}; end
        if ~ischar(system_values_str) && ~isstring(system_values_str), continue; end
        
        system_values = str2double(strsplit(system_values_str, ','));
        current_val = 0;
        actual_system_id = NaN;
        if length(system_values) >= system_id_idx 
            actual_system_id = system_values(system_id_idx);
            if ~isnan(actual_system_id) && ... 
               ~isnan(system_values(power_idx)) && system_values(power_idx) ~= 0 && ...
               length(system_values) >= usb_idx && ... 
               ~isnan(system_values(fixedlights_idx)) && ...
               ~isnan(system_values(tubelights_idx)) && ...
               ~isnan(system_values(usb_idx))
                current_val = (system_values(fixedlights_idx) * pfixed + ...
                               system_values(tubelights_idx) * ptube + ...
                               pusb * system_values(usb_idx)) * system_values(power_idx);
            end
        end
        current_systems_winter_aggregated = [current_systems_winter_aggregated; current_val];
        hours_winter_aggregated = [hours_winter_aggregated; data_winter.Hour(m)];
        if ~isnan(actual_system_id)
            entry.hour = data_winter.Hour(m);
            entry.system_id = actual_system_id;
            entry.current = current_val;
            raw_per_system_id_data_winter = [raw_per_system_id_data_winter; entry];
        end
    end
end

%% Process Summer Data - Collect All Readings
% (Your existing code for processing summer data into raw_per_system_id_data_summer and aggregated data...)
fprintf('Processing Summer consumption data...\n');
current_systems_summer_aggregated = [];
hours_summer_aggregated = [];
raw_per_system_id_data_summer = [];
for m = 1:height(data_summer)
    for n = 1:numExcelSystemColumns_summer
        excel_system_col_name = ['System' num2str(n)];
        if ~ismember(excel_system_col_name, data_summer.Properties.VariableNames)
            continue;
        end
        system_values_str = data_summer.(excel_system_col_name){m};
        if iscell(system_values_str), system_values_str = system_values_str{1}; end
        if ~ischar(system_values_str) && ~isstring(system_values_str), continue; end
        system_values = str2double(strsplit(system_values_str, ','));
        current_val = 0;
        actual_system_id = NaN;
        if length(system_values) >= system_id_idx
            actual_system_id = system_values(system_id_idx);
             if ~isnan(actual_system_id) && ...
               ~isnan(system_values(power_idx)) && system_values(power_idx) ~= 0 && ...
               length(system_values) >= usb_idx && ...
               ~isnan(system_values(fixedlights_idx)) && ...
               ~isnan(system_values(tubelights_idx)) && ...
               ~isnan(system_values(usb_idx))
                current_val = (system_values(fixedlights_idx) * pfixed + ...
                               system_values(tubelights_idx) * ptube + ...
                               pusb * system_values(usb_idx)) * system_values(power_idx);
            end
        end
        current_systems_summer_aggregated = [current_systems_summer_aggregated; current_val];
        hours_summer_aggregated = [hours_summer_aggregated; data_summer.Hour(m)];
        if ~isnan(actual_system_id)
            entry.hour = data_summer.Hour(m);
            entry.system_id = actual_system_id;
            entry.current = current_val;
            raw_per_system_id_data_summer = [raw_per_system_id_data_summer; entry];
        end
    end
end

%% Calculate Mean Current per Actual System ID per Hour
% (Your existing code for per_system_id_hourly_winter and per_system_id_hourly_summer - this is the MEAN for each system)
fprintf('Calculating mean current per actual System ID per hour...\n');
max_system_id_winter = 0;
if ~isempty(raw_per_system_id_data_winter), max_system_id_winter = max([raw_per_system_id_data_winter.system_id]); end
if max_system_id_winter == 0, max_system_id_winter = 3; end 
per_system_id_hourly_winter = zeros(24, max_system_id_winter); 
if ~isempty(raw_per_system_id_data_winter)
    unique_actual_system_ids_winter = unique([raw_per_system_id_data_winter.system_id]);
    for s_id_val = unique_actual_system_ids_winter(:)' 
        if s_id_val > max_system_id_winter || s_id_val <= 0, continue; end 
        for h_val = 0:23 
            system_hour_data_indices = ([raw_per_system_id_data_winter.system_id] == s_id_val) & ([raw_per_system_id_data_winter.hour] == h_val);
            system_hour_current_values = [raw_per_system_id_data_winter(system_hour_data_indices).current];
            if ~isempty(system_hour_current_values)
                per_system_id_hourly_winter(h_val + 1, s_id_val) = mean(system_hour_current_values, 'omitnan');
            end
        end
    end
end
per_system_id_hourly_winter(isnan(per_system_id_hourly_winter)) = 0;

max_system_id_summer = 0;
if ~isempty(raw_per_system_id_data_summer), max_system_id_summer = max([raw_per_system_id_data_summer.system_id]); end
if max_system_id_summer == 0, max_system_id_summer = 3; end
per_system_id_hourly_summer = zeros(24, max_system_id_summer);
if ~isempty(raw_per_system_id_data_summer)
    unique_actual_system_ids_summer = unique([raw_per_system_id_data_summer.system_id]);
    for s_id_val = unique_actual_system_ids_summer(:)'
        if s_id_val > max_system_id_summer || s_id_val <= 0, continue; end
        for h_val = 0:23
            system_hour_data_indices = ([raw_per_system_id_data_summer.system_id] == s_id_val) & ([raw_per_system_id_data_summer.hour] == h_val);
            system_hour_current_values = [raw_per_system_id_data_summer(system_hour_data_indices).current];
            if ~isempty(system_hour_current_values)
                per_system_id_hourly_summer(h_val + 1, s_id_val) = mean(system_hour_current_values, 'omitnan');
            end
        end
    end
end
per_system_id_hourly_summer(isnan(per_system_id_hourly_summer)) = 0;

%% Calculate Overall Mean Current, Std Dev, and CI per Hour (Existing Logic - Unchanged)
% (This section remains the same)
fprintf('Calculating overall mean current and CI (based on all readings)...\n');
unique_hours_winter = unique(hours_winter_aggregated);
mean_current_per_hour_winter = zeros(24, 1); 
std_dev_per_hour_winter = zeros(24, 1);
ci_lower_winter = zeros(24, 1);
ci_upper_winter = zeros(24, 1);
confidence_level = 0.95; 
alpha_val = 1 - confidence_level;

for i = 1:length(unique_hours_winter)
    h_val = unique_hours_winter(i); 
    if h_val < 0 || h_val > 23, continue; end 
    current_hour_data_winter = current_systems_winter_aggregated(hours_winter_aggregated == h_val);
    calculated_mean = mean(current_hour_data_winter, 'omitnan');
    mean_current_per_hour_winter(h_val + 1) = calculated_mean;
    std_dev_per_hour_winter(h_val + 1) = std(current_hour_data_winter, 'omitnan');
    n_samples_winter = sum(~isnan(current_hour_data_winter));
    if n_samples_winter > 1 
        t_value_winter = tinv(1 - alpha_val/2, n_samples_winter - 1);
        margin_of_error_winter = t_value_winter * (std_dev_per_hour_winter(h_val + 1) / sqrt(n_samples_winter));
        ci_lower_winter(h_val + 1) = calculated_mean - margin_of_error_winter;
        ci_upper_winter(h_val + 1) = calculated_mean + margin_of_error_winter;
    else 
        ci_lower_winter(h_val + 1) = calculated_mean;
        ci_upper_winter(h_val + 1) = calculated_mean;
    end
end
mean_current_per_hour_winter(isnan(mean_current_per_hour_winter)) = 0;
ci_lower_winter(isnan(ci_lower_winter)) = mean_current_per_hour_winter(isnan(ci_lower_winter)); 
ci_upper_winter(isnan(ci_upper_winter)) = mean_current_per_hour_winter(isnan(ci_upper_winter));

unique_hours_summer = unique(hours_summer_aggregated);
mean_current_per_hour_summer = zeros(24, 1);
std_dev_per_hour_summer = zeros(24, 1);
ci_lower_summer = zeros(24, 1);
ci_upper_summer = zeros(24, 1);
for i = 1:length(unique_hours_summer)
    h_val = unique_hours_summer(i);
    if h_val < 0 || h_val > 23, continue; end
    current_hour_data_summer = current_systems_summer_aggregated(hours_summer_aggregated == h_val);
    calculated_mean = mean(current_hour_data_summer, 'omitnan');
    mean_current_per_hour_summer(h_val + 1) = calculated_mean;
    std_dev_per_hour_summer(h_val + 1) = std(current_hour_data_summer, 'omitnan');
    n_samples_summer = sum(~isnan(current_hour_data_summer));
    if n_samples_summer > 1
        t_value_summer = tinv(1 - alpha_val/2, n_samples_summer - 1);
        margin_of_error_summer = t_value_summer * (std_dev_per_hour_summer(h_val + 1) / sqrt(n_samples_summer));
        ci_lower_summer(h_val + 1) = calculated_mean - margin_of_error_summer;
        ci_upper_summer(h_val + 1) = calculated_mean + margin_of_error_summer;
    else
        ci_lower_summer(h_val + 1) = calculated_mean;
        ci_upper_summer(h_val + 1) = calculated_mean;
    end
end
mean_current_per_hour_summer(isnan(mean_current_per_hour_summer)) = 0;
ci_lower_summer(isnan(ci_lower_summer)) = mean_current_per_hour_summer(isnan(ci_lower_summer));
ci_upper_summer(isnan(ci_upper_summer)) = mean_current_per_hour_summer(isnan(ci_upper_summer));


%% NEW: Calculate Std Dev and CI for Individual System IDs
fprintf('Calculating CI for individual System IDs...\n');
% Determine which system IDs to process for individual plots (e.g., 1, 2, 3 or all available up to max_system_id)
% For this example, we'll calculate for all systems up to max_system_id_winter/summer
% and then you can choose which ones to plot.

% --- Winter: Std Dev and CI for each System ID ---
std_dev_per_system_id_hourly_winter = zeros(24, max_system_id_winter);
ci_lower_per_system_id_hourly_winter = zeros(24, max_system_id_winter);
ci_upper_per_system_id_hourly_winter = zeros(24, max_system_id_winter);

if ~isempty(raw_per_system_id_data_winter)
    unique_s_ids_w = unique([raw_per_system_id_data_winter.system_id]);
    for s_id_val = unique_s_ids_w(:)'
        if s_id_val > max_system_id_winter || s_id_val <= 0, continue; end
        for h_val = 0:23
            hourly_data_for_system = [raw_per_system_id_data_winter(([raw_per_system_id_data_winter.system_id] == s_id_val) & ([raw_per_system_id_data_winter.hour] == h_val)).current];
            hourly_data_for_system = hourly_data_for_system(~isnan(hourly_data_for_system)); % Clean NaNs from current values
            
            n_samples = length(hourly_data_for_system);
            current_mean_for_sys_hour = per_system_id_hourly_winter(h_val + 1, s_id_val); % Already calculated mean
            
            if n_samples > 0
                std_dev_per_system_id_hourly_winter(h_val + 1, s_id_val) = std(hourly_data_for_system, 'omitnan');
            else
                std_dev_per_system_id_hourly_winter(h_val + 1, s_id_val) = 0; % Or NaN
            end

            if n_samples > 1
                t_value = tinv(1 - alpha_val/2, n_samples - 1);
                margin_of_error = t_value * (std_dev_per_system_id_hourly_winter(h_val + 1, s_id_val) / sqrt(n_samples));
                ci_lower_per_system_id_hourly_winter(h_val + 1, s_id_val) = current_mean_for_sys_hour - margin_of_error;
                ci_upper_per_system_id_hourly_winter(h_val + 1, s_id_val) = current_mean_for_sys_hour + margin_of_error;
            else % For n_samples <= 1, CI is typically the mean itself or undefined.
                ci_lower_per_system_id_hourly_winter(h_val + 1, s_id_val) = current_mean_for_sys_hour;
                ci_upper_per_system_id_hourly_winter(h_val + 1, s_id_val) = current_mean_for_sys_hour;
            end
        end
    end
end
% Ensure no NaNs in CIs, default to the mean if calculation failed or n_samples too small
nan_idx_ci_w_lower = isnan(ci_lower_per_system_id_hourly_winter);
ci_lower_per_system_id_hourly_winter(nan_idx_ci_w_lower) = per_system_id_hourly_winter(nan_idx_ci_w_lower);
nan_idx_ci_w_upper = isnan(ci_upper_per_system_id_hourly_winter);
ci_upper_per_system_id_hourly_winter(nan_idx_ci_w_upper) = per_system_id_hourly_winter(nan_idx_ci_w_upper);


% --- Summer: Std Dev and CI for each System ID ---
std_dev_per_system_id_hourly_summer = zeros(24, max_system_id_summer);
ci_lower_per_system_id_hourly_summer = zeros(24, max_system_id_summer);
ci_upper_per_system_id_hourly_summer = zeros(24, max_system_id_summer);

if ~isempty(raw_per_system_id_data_summer)
    unique_s_ids_s = unique([raw_per_system_id_data_summer.system_id]);
    for s_id_val = unique_s_ids_s(:)'
        if s_id_val > max_system_id_summer || s_id_val <= 0, continue; end
        for h_val = 0:23
            hourly_data_for_system = [raw_per_system_id_data_summer(([raw_per_system_id_data_summer.system_id] == s_id_val) & ([raw_per_system_id_data_summer.hour] == h_val)).current];
            hourly_data_for_system = hourly_data_for_system(~isnan(hourly_data_for_system));

            n_samples = length(hourly_data_for_system);
            current_mean_for_sys_hour = per_system_id_hourly_summer(h_val + 1, s_id_val); % Already calculated mean

            if n_samples > 0
                std_dev_per_system_id_hourly_summer(h_val + 1, s_id_val) = std(hourly_data_for_system, 'omitnan');
            else
                std_dev_per_system_id_hourly_summer(h_val + 1, s_id_val) = 0; % Or NaN
            end
            
            if n_samples > 1
                t_value = tinv(1 - alpha_val/2, n_samples - 1);
                margin_of_error = t_value * (std_dev_per_system_id_hourly_summer(h_val + 1, s_id_val) / sqrt(n_samples));
                ci_lower_per_system_id_hourly_summer(h_val + 1, s_id_val) = current_mean_for_sys_hour - margin_of_error;
                ci_upper_per_system_id_hourly_summer(h_val + 1, s_id_val) = current_mean_for_sys_hour + margin_of_error;
            else
                ci_lower_per_system_id_hourly_summer(h_val + 1, s_id_val) = current_mean_for_sys_hour;
                ci_upper_per_system_id_hourly_summer(h_val + 1, s_id_val) = current_mean_for_sys_hour;
            end
        end
    end
end
nan_idx_ci_s_lower = isnan(ci_lower_per_system_id_hourly_summer);
ci_lower_per_system_id_hourly_summer(nan_idx_ci_s_lower) = per_system_id_hourly_summer(nan_idx_ci_s_lower);
nan_idx_ci_s_upper = isnan(ci_upper_per_system_id_hourly_summer);
ci_upper_per_system_id_hourly_summer(nan_idx_ci_s_upper) = per_system_id_hourly_summer(nan_idx_ci_s_upper);


%% Apply FIR Filter (Optional - to overall mean)
% (This section remains the same)
fprintf('Applying FIR filter to overall mean consumption...\n');
window_size = 2; 
fir_filter = ones(window_size, 1) / window_size;
filtered_mean_current_per_hour_winter = filter(fir_filter, 1, mean_current_per_hour_winter);
if ~isempty(mean_current_per_hour_winter) && length(filtered_mean_current_per_hour_winter) >=1 
    filtered_mean_current_per_hour_winter(1) = mean_current_per_hour_winter(1); 
end
filtered_mean_current_per_hour_summer = filter(fir_filter, 1, mean_current_per_hour_summer);
if ~isempty(mean_current_per_hour_summer) && length(filtered_mean_current_per_hour_summer) >=1 
   filtered_mean_current_per_hour_summer(1) = mean_current_per_hour_summer(1); 
end


%% Save Processed Data
% (Modify to include new per-system CI data if you want to save them, 
%  otherwise, they are just used for plotting below.
%  For now, per_system_id_hourly_winter/summer (means) are already saved).
%  If you want to save these CIs, add them to the save command for the mat files.
%  Example: "std_dev_per_system_id_hourly_winter", "ci_lower_per_system_id_hourly_winter", etc.
fprintf('Saving processed consumption data to MAT files (including per-System ID data)...\n');
hours_axis_for_table = (0:23)';

mean_current_data_winter_table = table(hours_axis_for_table, mean_current_per_hour_winter, ci_lower_winter, ci_upper_winter, filtered_mean_current_per_hour_winter, 'VariableNames', {'Hour', 'Mean_Current_Winter', 'CI_Lower_Winter', 'CI_Upper_Winter', 'Filtered_Mean_Current_Winter'});
writetable(mean_current_data_winter_table, 'mean_current_per_hour_winter_with_ci.csv');
save("mean_consumption_SHS_all_systems_winter_with_ci.mat", ...
     "hours_axis_for_table", "mean_current_per_hour_winter", "ci_lower_winter", "ci_upper_winter", ...
     "std_dev_per_hour_winter", "filtered_mean_current_per_hour_winter", "confidence_level", ... % Added std_dev overall
     "per_system_id_hourly_winter", "max_system_id_winter", ...
     "std_dev_per_system_id_hourly_winter", "ci_lower_per_system_id_hourly_winter", "ci_upper_per_system_id_hourly_winter", '-mat');

mean_current_data_summer_table = table(hours_axis_for_table, mean_current_per_hour_summer, ci_lower_summer, ci_upper_summer, filtered_mean_current_per_hour_summer, 'VariableNames', {'Hour', 'Mean_Current_Summer', 'CI_Lower_Summer', 'CI_Upper_Summer', 'Filtered_Mean_Current_Summer'});
writetable(mean_current_data_summer_table, 'mean_current_per_hour_summer_with_ci.csv');
save("mean_consumption_SHS_all_systems_summer_with_ci.mat", ...
     "hours_axis_for_table", "mean_current_per_hour_summer", "ci_lower_summer", "ci_upper_summer", ...
     "std_dev_per_hour_summer", "filtered_mean_current_per_hour_summer", "confidence_level", ... % Added std_dev overall
     "per_system_id_hourly_summer", "max_system_id_summer", ...
     "std_dev_per_system_id_hourly_summer", "ci_lower_per_system_id_hourly_summer", "ci_upper_per_system_id_hourly_summer", '-mat');


%% Plot Mean Current per Hour with Confidence Intervals (Overall Average)
% (This plotting section for overall average remains the same)
fprintf('Plotting overall mean consumption...\n');
fig_overall = figure('Name', 'Overall Mean Consumption with CI'); % Added Name
set(fig_overall, 'Position', [100, 100, 1000, 750]); 
hold on;
fill([hours_axis_for_table; flipud(hours_axis_for_table)], [ci_lower_winter; flipud(ci_upper_winter)], 'b', ...
    'FaceAlpha', 0.15, 'EdgeColor', 'none', 'DisplayName', [num2str(confidence_level*100), '% CI Winter (Overall)']);
plot(hours_axis_for_table, mean_current_per_hour_winter, '-o', 'Color', [0 0.4470 0.7410], ...
    'MarkerFaceColor', [0 0.4470 0.7410], 'DisplayName', 'Mean Power Winter (Overall)');
fill([hours_axis_for_table; flipud(hours_axis_for_table)], [ci_lower_summer; flipud(ci_upper_summer)], 'r', ...
    'FaceAlpha', 0.15, 'EdgeColor', 'none', 'DisplayName', [num2str(confidence_level*100), '% CI Summer (Overall)']);
plot(hours_axis_for_table, mean_current_per_hour_summer, '-s', 'Color', [0.8500 0.3250 0.0980], ...
    'MarkerFaceColor', [0.8500 0.3250 0.0980], 'DisplayName', 'Mean Power Summer (Overall)');
title(['Overall Mean Consumption per Hour (with ', num2str(confidence_level*100), '% CI)']);
xlabel('Hour of the Day'); ylabel('Power [W]'); 
xticks(0:2:23); xlim([-0.5 23.5]); 
legend('show', 'Location', 'best'); grid on; box on; hold off;

%% NEW: Plot Mean Consumption with CI for Specific Systems
fprintf('Plotting mean consumption with CI for individual systems...\n');
systems_to_plot = [1, 2, 3]; % Define which system IDs you want to generate plots for

for sys_plot_idx = 1:length(systems_to_plot)
    current_system_id = systems_to_plot(sys_plot_idx);
    
    % Check if data exists for this system ID
    if current_system_id > max_system_id_winter && current_system_id > max_system_id_summer
        fprintf('No data found for System %d. Skipping plot.\n', current_system_id);
        continue;
    end
    
    fig_sys = figure('Name', sprintf('Mean Consumption for System %d with CI', current_system_id));
    set(fig_sys, 'Position', [100 + sys_plot_idx*50, 100 + sys_plot_idx*50, 1000, 250]); % Offset figures
    hold on;

    % --- Winter Data for current_system_id ---
    if current_system_id <= max_system_id_winter
        mean_sys_w = per_system_id_hourly_winter(:, current_system_id);
        ci_low_sys_w = ci_lower_per_system_id_hourly_winter(:, current_system_id);
        ci_up_sys_w = ci_upper_per_system_id_hourly_winter(:, current_system_id);
        
        fill([hours_axis_for_table; flipud(hours_axis_for_table)], [ci_low_sys_w; flipud(ci_up_sys_w)], 'b', ...
            'FaceAlpha', 0.15, 'EdgeColor', 'none', 'DisplayName', [num2str(confidence_level*100), sprintf('%% CI Winter')]);
        plot(hours_axis_for_table, mean_sys_w, '-o', 'Color', [0 0.4470 0.7410], ...
            'MarkerFaceColor', [0 0.4470 0.7410], 'DisplayName', sprintf('Mean Power Winter'));
    else
        plot(NaN,NaN,'DisplayName',sprintf('Winter Data N/A (Sys %d)', current_system_id)); % Placeholder for legend
    end
    
    % --- Summer Data for current_system_id ---
    if current_system_id <= max_system_id_summer
        mean_sys_s = per_system_id_hourly_summer(:, current_system_id);
        ci_low_sys_s = ci_lower_per_system_id_hourly_summer(:, current_system_id);
        ci_up_sys_s = ci_upper_per_system_id_hourly_summer(:, current_system_id);

        fill([hours_axis_for_table; flipud(hours_axis_for_table)], [ci_low_sys_s; flipud(ci_up_sys_s)], 'r', ...
            'FaceAlpha', 0.15, 'EdgeColor', 'none', 'DisplayName', [num2str(confidence_level*100), sprintf('%% CI Summer')]);
        plot(hours_axis_for_table, mean_sys_s, '-s', 'Color', [0.8500 0.3250 0.0980], ...
            'MarkerFaceColor', [0.8500 0.3250 0.0980], 'DisplayName', sprintf('Mean Power Summer'));
    else
         plot(NaN,NaN,'DisplayName',sprintf('Summer Data N/A (Sys %d)', current_system_id)); % Placeholder for legend
    end
    
    title(sprintf('Mean Consumption for System %d (with %s%% CI)', current_system_id, num2str(confidence_level*100)));
    xlabel('Hour of the Day');
    ylabel('Power [W]'); 
    xticks(0:2:23); 
    xlim([-0.5 23.5]); 
    legend('show', 'Location', 'best');
    grid on;
    box on; 
    hold off;
end

disp('Consumption data analysis complete. Check figures and saved MAT/CSV files.');
disp('MAT files now include per-System ID means, std_devs, and CIs.');

% Optional: Clean up large intermediate variables
clear raw_per_system_id_data_winter raw_per_system_id_data_summer current_systems_winter_aggregated hours_winter_aggregated;
clear current_systems_summer_aggregated hours_summer_aggregated;