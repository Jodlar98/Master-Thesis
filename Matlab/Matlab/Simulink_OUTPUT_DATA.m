% --- Plotting Simulink Results from 'yout' Dataset ---

% Ensure 'tout' (time vector in seconds) and 'yout' (Simulink.SimulationData.Dataset) 
% are in your MATLAB workspace from the Simulink simulation.

% --- 0. Initial Checks ---
if ~exist('tout', 'var') || ~exist('yout', 'var')
    error('Please ensure ''tout'' and ''yout'' (Simulink.SimulationData.Dataset) are in the workspace.');
end
if ~isa(yout, 'Simulink.SimulationData.Dataset')
    error('''yout'' is not a Simulink.SimulationData.Dataset object.');
end

fprintf('Number of signals/elements in yout: %d\n', yout.numElements);
signalNames = yout.getElementNames();
if ~isempty(signalNames) && ~all(cellfun('isempty', signalNames))
    disp('Signal names available in yout:');
    for k_idx = 1:length(signalNames) 
        fprintf('  Element %d: %s\n', k_idx, signalNames{k_idx});
    end
else
    disp('Signals in yout do not have explicit names. Access them by index (e.g., yout{1}, yout{2}, etc.).');
end

% --- 1. Convert Global Time Vector to Hours ---
time_in_hours = tout / 3600;

% --- 2. Figure 1: Charge Plot (3 signals from the 'Charge' element) ---
try
    % Access the 'Charge' signal group (Element 3)
    charge_signal_group_obj = yout.get('Charge'); % Or yout{3}
    charge_data_matrix = charge_signal_group_obj.Values.Data;

    if size(charge_data_matrix, 2) < 3
        error('The ''Charge'' signal data does not have at least 3 columns for plotting.');
    end
    
    figure(1); 
    clf; 
    hold on; 
    plot(time_in_hours, charge_data_matrix(:,1), 'LineWidth', 1.5, 'DisplayName', 'Combined charge');
    plot(time_in_hours, charge_data_matrix(:,2), 'LineWidth', 1.5, 'DisplayName', 'Source');
    plot(time_in_hours, charge_data_matrix(:,3), 'LineWidth', 1.5, 'DisplayName', 'Drain');
    hold off;
    
    title('Battery Charge and Discharge');
    xlabel('Time (hours)');
    ylabel('Ampere'); % *** Customize this label ***
    legend('show', 'Location', 'best');
    grid on;
    
    if ~isempty(time_in_hours)
        xlim([0, max(time_in_hours)]);
        if max(time_in_hours) > 48 
            tick_interval_hours_fig1 = 24; 
            xticks(0:tick_interval_hours_fig1:max(time_in_hours));
        end
    end
    
catch ME_fig1
    fprintf('Error processing or plotting data for Figure 1 (Charge Plot):\n%s\n', ME_fig1.message);
    disp('Please check the structure of the ''Charge'' signal in ''yout''.');
end

% --- 3. Figure 2: SoC and Production/Consumption Plot ---
try
    % Access 'State of Charge' (Element 1)
    soc_obj = yout.get('State of Charge'); % Or yout{1}
    soc_data = soc_obj.Values.Data;
    
    % Access 'ProductionConsumption' (Element 2)
    prod_cons_obj = yout.get('ProductionConsumption'); % Or yout{2}
    prod_cons_data_matrix = prod_cons_obj.Values.Data;

    % Check if 'ProductionConsumption' has at least two columns
    if size(prod_cons_data_matrix, 2) < 2
        error('The ''ProductionConsumption'' signal data does not have at least 2 columns (for production and consumption).');
    end

    figure(2); 
    clf; 
    
    % Subplot 1: State of Charge
    subplot(2,1,1); 
    plot(time_in_hours, soc_data, 'LineWidth', 1.5, 'Color', [0.8500 0.3250 0.0980]); % Orange-ish
    title('State of Charge');
    xlabel('Time (hours)');
    ylabel('SoC'); 
    grid on;
    if ~isempty(time_in_hours)
        xlim([0, max(time_in_hours)]);
        if max(time_in_hours) > 48
             xticks(0:24:max(time_in_hours)); 
        end
    end
    ylim([0 1.05]); 

    % Subplot 2: Production and Consumption
    subplot(2,1,2); 
    hold on; % Allow multiple lines on this subplot's axes
    % *** IMPORTANT: Verify which column is Production and which is Consumption ***
    % Assuming column 1 is Production and column 2 is Consumption. Adjust if necessary.
    plot(time_in_hours, prod_cons_data_matrix(:,1), 'LineWidth', 1.5, 'DisplayName', 'Consumption', 'Color', [0.4660 0.6740 0.1880]); % Green-ish
    plot(time_in_hours, prod_cons_data_matrix(:,2), 'LineWidth', 1.5, 'DisplayName', 'Production', 'Color', [0.6350 0.0780 0.1840]); % Red-ish
    hold off;
    
    title('Production and Consumption');
    xlabel('Time (hours)');
    ylabel('Energy [Wh]'); % *** Customize this label based on units ***
    legend('show', 'Location', 'best');
    grid on;
    if ~isempty(time_in_hours)
        xlim([0, max(time_in_hours)]);
         if max(time_in_hours) > 48
             xticks(0:24:max(time_in_hours)); 
        end
    end
    
catch ME_fig2
    fprintf('Error processing or plotting data for Figure 2 (SoC & Prod/Cons Plot):\n%s\n', ME_fig2.message);
    disp('Please check the signal names/indices for SoC and ProductionConsumption, and the structure of ProductionConsumption.');
end

fprintf('Plotting script finished. Check generated figures.\n');