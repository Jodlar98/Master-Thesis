% Ensure the 'Results' folder exists
if ~exist('Results', 'dir')
   mkdir('Results');
   fprintf('Created folder: Results\n');
end

% Define the filename for your saved data
output_filename = fullfile('Results', 'sim_300System_Winter_withLoss.mat');

% Save the relevant plotting data variables
save(output_filename, 'time_in_hours', 'charge_data_matrix', 'soc_data', 'prod_cons_data_matrix');

fprintf('Plotted data saved to: %s\n', output_filename);