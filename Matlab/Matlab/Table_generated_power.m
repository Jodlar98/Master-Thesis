% MATLAB Skript for å beregne total daglig produksjon per måned for flere scenarioer

% --- Konfigurasjon ---
% Mappen der den kombinerte .mat-filen fra forrige skript ble lagret
input_output_folder = 'scenario_outputs_from_csv'; 

% Navn på den kombinerte .mat-filen som inneholder all scenario-data
combined_data_file = 'all_scenarios_mean_hourly_data.mat';

% Definer scenario-navnene som skal prosesseres (disse ble brukt i forrige skript)
scenario_names_to_process = {'40Wpp', '20Wpp', '10Wpp'};

% Månedsnavn for tabellen
months_norwegian = {'Januar', 'Februar', 'Mars', 'April', 'Mai', 'Juni', ...
                    'Juli', 'August', 'September', 'Oktober', 'November', 'Desember'}';

% --- Last inn forhåndsbearbeidet data ---
combined_mat_filepath = fullfile(input_output_folder, combined_data_file);

if ~exist(combined_mat_filepath, 'file')
    error('Filen "%s" ble ikke funnet. Kjør det forrige skriptet først for å generere denne filen.', combined_mat_filepath);
end

fprintf('Laster inn data fra "%s"...\n', combined_mat_filepath);
load(combined_mat_filepath, 'all_scenarios_results'); % Laster inn strukturen 'all_scenarios_results'

% --- Initialiser struktur for å lagre alle nye resultattabeller ---
all_total_production_tables = struct();

fprintf('Starter beregning av total daglig produksjon per måned for hvert scenario...\n');

% --- Iterer gjennom hvert scenario ---
for i = 1:length(scenario_names_to_process)
    current_scenario_name = scenario_names_to_process{i};
    
    % Lag det gyldige feltnavnet som ble brukt til å lagre data i 'all_scenarios_results'
    % (f.eks. '40Wpp' blir til 'x40Wpp')
    valid_field_name = matlab.lang.makeValidName(current_scenario_name);
    
    fprintf('\nProsessering av scenario: %s\n', current_scenario_name);
    
    % Sjekk om data for dette scenarioet finnes i den lastede strukturen
    if ~isfield(all_scenarios_results, valid_field_name)
        fprintf('ADVARSEL: Fant ikke data for scenario "%s" (feltnavn "%s") i den lastede filen. Hopper over dette scenarioet.\n', ...
                current_scenario_name, valid_field_name);
        continue;
    end
    
    % Hent 'mean_hourlyProd_data' for gjeldende scenario
    % Dette er en celle-array med 12 elementer, hvor hvert element er [24x1] dobbel vektor
    current_mean_hourly_data = all_scenarios_results.(valid_field_name);
    
    % Initialiser array for å lagre total produksjon for hver måned for dette scenarioet
    total_production_Wh_typical_day = zeros(12, 1);
    
    % Loop gjennom hver måned og beregn total produksjon for en typisk dag
    for m = 1:12
        if ~isempty(current_mean_hourly_data{m})
            % Summer de gjennomsnittlige timeverdiene for måned m.
            % Resultatet er total Wh for en typisk dag i den måneden.
            % sum() vil gi NaN hvis noen av timeverdiene er NaN. Dette er vanligvis ønsket atferd.
            total_production_Wh_typical_day(m) = sum(current_mean_hourly_data{m});
        else
            fprintf('ADVARSEL: Manglende data for måned %d i scenario %s. Setter totalproduksjon til NaN.\n', m, current_scenario_name);
            total_production_Wh_typical_day(m) = NaN;
        end
    end
    
    % Lag en tabell for resultatene for dette scenarioet
    % Bruker de norske månedsnavnene definert tidligere
    results_table = table(months_norwegian, total_production_Wh_typical_day, ...
                          'VariableNames', {'Maaned', 'TotalProduksjon_Wh_TypiskDag'});
    
    % Vis tabellen
    disp(results_table);
    
    % Lagre resultattabellen for dette scenarioet til en .mat-fil
    output_mat_filename_individual = fullfile(input_output_folder, ['total_production_results_', current_scenario_name, '.mat']);
    save(output_mat_filename_individual, 'results_table');
    fprintf('Resultattabell for %s lagret til: %s\n', current_scenario_name, output_mat_filename_individual);
    
    % Lagre tabellen i den samlede strukturen (bruk det gyldige feltnavnet)
    all_total_production_tables.(valid_field_name) = results_table;
end

% --- Lagre den samlede strukturen med alle resultattabeller ---
if ~isempty(fieldnames(all_total_production_tables))
    combined_output_mat_filename = fullfile(input_output_folder, 'all_scenarios_total_daily_production_results.mat');
    save(combined_output_mat_filename, 'all_total_production_tables');
    fprintf('\nSamlet resultattabell for alle scenarioer lagret til: %s\n', combined_output_mat_filename);
else
    fprintf('\nIngen scenarioer ble prosessert vellykket. Ingen samlet resultatfil ble lagret.\n');
end

fprintf('\nProsessering fullført.\n');