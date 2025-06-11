% MATLAB Skript for Analyse av Timeserie Kraftproduksjonsdata fra Flere CSV-filer
% --- Konfigurasjon ---
output_folder = 'scenario_outputs_from_csv'; % Mappe for lagring av resultater
% Definer scenarioene: Gi hvert scenario et navn og spesifiser CSV-filen.
scenarios_config = {
    struct('name', '40Wpp', 'csv_file', '40Wpp_2023.csv'), ... 
    struct('name', '20Wpp', 'csv_file', '20WPP_2023.csv'), ... 
    struct('name', '10Wpp', 'csv_file', '10WPP_2023.csv')     
};
% Vindusstørrelse for movmean (1 betyr ingen utjevning)
smoothing_window_size = 1;
% --- Initialisering ---
% Opprett mappe for utdatafiler hvis den ikke finnes
if ~exist(output_folder, 'dir')
   mkdir(output_folder);
end
all_scenarios_results = struct(); % Struktur for å lagre alle bearbeidede data
% --- Hovedløkke for prosessering av scenarioer ---
fprintf('Starter prosessering av scenarioer fra separate CSV-filer...\n');
for s_idx = 1:length(scenarios_config)
    scenario_name = scenarios_config{s_idx}.name; % F.eks. '40Wpp'
    current_csv_file = scenarios_config{s_idx}.csv_file;
    
    fprintf('Prosessering av scenario: %s (fra fil: %s)\n', scenario_name, current_csv_file);
    
    % Les data fra den spesifikke CSV-filen for dette scenarioet
    try
        opts = detectImportOptions(current_csv_file);
        opts.VariableNamingRule = 'preserve'; 
        opts.EmptyLineRule = 'skip';
        T_current_scenario = readtable(current_csv_file, opts);
    catch ME
        fprintf('ADVARSEL: Kunne ikke lese CSV-filen "%s" for scenario "%s". Scenarioet hoppes over.\nFeilmelding: %s\n', ...
                current_csv_file, scenario_name, ME.message);
        continue; 
    end
    % Sjekk for nødvendige kolonner
    if ~ismember('time', T_current_scenario.Properties.VariableNames)
        fprintf('ADVARSEL: CSV-filen "%s" for scenario "%s" mangler "time"-kolonnen. Scenarioet hoppes over.\n', ...
                current_csv_file, scenario_name);
        continue;
    end
    if ~ismember('P', T_current_scenario.Properties.VariableNames)
        fprintf('ADVARSEL: CSV-filen "%s" for scenario "%s" mangler "P"-kolonnen. Scenarioet hoppes over.\n', ...
                current_csv_file, scenario_name);
        continue;
    end
    % Konverter 'time'-kolonnen til datetime-objekter
    try
        if iscell(T_current_scenario.time) || isstring(T_current_scenario.time)
            T_current_scenario.time = datetime(T_current_scenario.time, 'InputFormat', 'yyyyMMdd:HHmm', 'Format', 'yyyy-MM-dd HH:mm');
        elseif ~isdatetime(T_current_scenario.time)
             error('Time column is not in a recognizable cell/string format for conversion or already datetime.');
        end
    catch ME
        fprintf('ADVARSEL: Kunne ikke konvertere "time"-kolonnen i filen "%s" for scenario "%s". \nSjekk at formatet er 양MMdd:HHmm eller allerede datetime. Scenarioet hoppes over.\nFeilmelding: %s\n', ...
                current_csv_file, scenario_name, ME.message);
        continue;
    end
    
    % Sikre at P-kolonnen er numerisk
    if ~isnumeric(T_current_scenario.P)
        try
            % Hvis P-kolonnen er lest som celler med tall i (f.eks. pga. manglende verdier et sted)
            if iscell(T_current_scenario.P)
                T_current_scenario.P = cellfun(@str2double, T_current_scenario.P);
            else % Anta string
                T_current_scenario.P = str2double(T_current_scenario.P); 
            end
        catch
             fprintf('ADVARSEL: "P"-kolonnen i filen "%s" for scenario "%s" er ikke numerisk og kunne ikke konverteres. Scenarioet hoppes over.\n', ...
                current_csv_file, scenario_name);
            continue;
        end
    end
    mean_hourlyProd_data = cell(12, 1); 
    
    for m = 1:12
        month_data = T_current_scenario(month(T_current_scenario.time) == m, :);
        mean_hourly = NaN(24, 1); 
        
        for h = 0:23
            hour_specific_data = month_data(hour(month_data.time) == h, :);
            
            if ~isempty(hour_specific_data) && ~all(isnan(hour_specific_data.P))
                mean_hourly(h+1) = mean(hour_specific_data.P, 'omitnan');
            end
        end
        
        if smoothing_window_size > 0 && smoothing_window_size <= 24 
            mean_hourly_smoothed = movmean(mean_hourly, smoothing_window_size, 'omitnan');
        else
            mean_hourly_smoothed = mean_hourly; 
        end
        
        mean_hourlyProd_data{m} = mean_hourly_smoothed;
    end
    
    % --- KORREKSJON HER ---
    % Lag et gyldig feltnavn fra scenario_name
    valid_field_name = matlab.lang.makeValidName(scenario_name); 
    % Bruk det gyldige feltnavnet for å lagre data i strukturen
    all_scenarios_results.(valid_field_name) = mean_hourlyProd_data; 
    % ---------------------
    
    save_filename_mat = fullfile(output_folder, ['mean_hourlyProd_data_', scenario_name, '.mat']);
    save(save_filename_mat, 'mean_hourlyProd_data');
    fprintf('Lagret data til %s\n', save_filename_mat);
    
    fig = figure('Name', ['Gjennomsnittlig timeproduksjon - ', scenario_name], 'Visible', 'off');
    set(fig, 'Position', [100, 100, 800, 400]);
    
    hold on;
    colors = lines(12); 
    winter_months = [12, 1, 2, 11, 10, 3]; 
    
    for m_idx = 1:12 
        month_name_str = datestr(datetime(2023, m_idx, 1), 'mmm'); 
        if ~isempty(mean_hourlyProd_data{m_idx}) && any(~isnan(mean_hourlyProd_data{m_idx}))
            hours_of_day = 0:23;
            if ismember(m_idx, winter_months)
                plot(hours_of_day, mean_hourlyProd_data{m_idx}, 'Color', colors(m_idx, :), 'LineStyle', '--', 'DisplayName', month_name_str);
            else
                plot(hours_of_day, mean_hourlyProd_data{m_idx}, 'Color', colors(m_idx, :), 'LineStyle', '-', 'DisplayName', month_name_str);
            end
        else
            fprintf('Info: Ingen gyldige data å plotte for måned %d (%s) i scenario %s.\n', m_idx, month_name_str, scenario_name);
        end
    end
    
    title_str = sprintf('Gjennomsnittlig timeproduksjon per måned (%s)', scenario_name);
    title(title_str);
    xlabel('Time på dagen (0-23)');
    ylabel('Produsert effekt [W]');
    legend('show', 'Location', 'northeast');
    grid on;
    xlim([2 20]); 
    
    hold off;
    plot_filename_png = fullfile(output_folder, ['plot_mean_hourlyProd_', scenario_name, '.png']);
    try
        saveas(fig, plot_filename_png);
        fprintf('Lagret plott til %s\n', plot_filename_png);
    catch ME_save
        fprintf('Advarsel: Kunne ikke lagre plott %s. Feilmelding: %s\n', plot_filename_png, ME_save.message);
    end
    close(fig); 
    
end
if ~isempty(fieldnames(all_scenarios_results)) 
    combined_save_filename_mat = fullfile(output_folder, 'all_scenarios_mean_hourly_data.mat');
    save(combined_save_filename_mat, 'all_scenarios_results');
    fprintf('Lagret kombinerte data for alle scenarioer til %s\n', combined_save_filename_mat);
else
    fprintf('Ingen scenarioer ble prosessert vellykket. Ingen kombinert datafil ble lagret.\n');
end
fprintf('Prosessering fullført. Resultatene (hvis noen) er lagret i mappen "%s".\n', output_folder);