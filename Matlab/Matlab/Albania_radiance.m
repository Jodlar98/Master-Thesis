% JSON data as a string
jsonData = '{"inputs": {"location": {"latitude": 42.059, "longitude": 19.514, "elevation": 11.0}, "meteo_data": {"radiation_db": "PVGIS-SARAH3", "meteo_db": "ERA5", "year_min": 2005, "year_max": 2023, "use_horizon": true, "horizon_db": "DEM-calculated"}, "plane": {"fixed": {"slope": {"value": 35.0, "optimal": false}, "azimuth": {"value": 0.0, "optimal": false}}}, "time_format": "local"}, "outputs": {"daily_profile": [{"month": 4, "time": "00:00", "G(i)": 0.0, "Gb(i)": 0.0, "Gd(i)": 0.0}, {"month": 4, "time": "01:00", "G(i)": 0.0, "Gb(i)": 0.0, "Gd(i)": 0.0}, {"month": 4, "time": "02:00", "G(i)": 0.0, "Gb(i)": 0.0, "Gd(i)": 0.0}, {"month": 4, "time": "03:00", "G(i)": 0.0, "Gb(i)": 0.0, "Gd(i)": 0.0}, {"month": 4, "time": "04:00", "G(i)": 0.0, "Gb(i)": 0.0, "Gd(i)": 0.0}, {"month": 4, "time": "05:00", "G(i)": 3.08, "Gb(i)": 0.0, "Gd(i)": 3.02}, {"month": 4, "time": "06:00", "G(i)": 81.23, "Gb(i)": 24.99, "Gd(i)": 54.47}, {"month": 4, "time": "07:00", "G(i)": 232.34, "Gb(i)": 115.74, "Gd(i)": 112.36}, {"month": 4, "time": "08:00", "G(i)": 406.36, "Gb(i)": 232.66, "Gd(i)": 166.81}, {"month": 4, "time": "09:00", "G(i)": 564.34, "Gb(i)": 347.14, "Gd(i)": 207.99}, {"month": 4, "time": "10:00", "G(i)": 681.66, "Gb(i)": 436.96, "Gd(i)": 233.79}, {"month": 4, "time": "11:00", "G(i)": 731.4, "Gb(i)": 475.75, "Gd(i)": 244.05}, {"month": 4, "time": "12:00", "G(i)": 737.58, "Gb(i)": 482.78, "Gd(i)": 243.11}, {"month": 4, "time": "13:00", "G(i)": 676.67, "Gb(i)": 437.16, "Gd(i)": 228.71}, {"month": 4, "time": "14:00", "G(i)": 579.29, "Gb(i)": 363.54, "Gd(i)": 206.34}, {"month": 4, "time": "15:00", "G(i)": 419.21, "Gb(i)": 240.54, "Gd(i)": 171.6}, {"month": 4, "time": "16:00", "G(i)": 260.31, "Gb(i)": 132.87, "Gd(i)": 122.74}, {"month": 4, "time": "17:00", "G(i)": 104.49, "Gb(i)": 36.83, "Gd(i)": 65.42}, {"month": 4, "time": "18:00", "G(i)": 5.22, "Gb(i)": 0.0, "Gd(i)": 5.11}, {"month": 4, "time": "19:00", "G(i)": 0.0, "Gb(i)": 0.0, "Gd(i)": 0.0}, {"month": 4, "time": "20:00", "G(i)": 0.0, "Gb(i)": 0.0, "Gd(i)": 0.0}, {"month": 4, "time": "21:00", "G(i)": 0.0, "Gb(i)": 0.0, "Gd(i)": 0.0}, {"month": 4, "time": "22:00", "G(i)": 0.0, "Gb(i)": 0.0, "Gd(i)": 0.0}, {"month": 4, "time": "23:00", "G(i)": 0.0, "Gb(i)": 0.0, "Gd(i)": 0.0}]}, "meta": {"inputs": {"location": {"description": "Selected location", "variables": {"latitude": {"description": "Latitude", "units": "decimal degree"}, "longitude": {"description": "Longitude", "units": "decimal degree"}, "elevation": {"description": "Elevation", "units": "m"}}}, "meteo_data": {"description": "Sources of meteorological data", "variables": {"radiation_db": {"description": "Solar radiation database"}, "meteo_db": {"description": "Database used for meteorological variables other than solar radiation"}, "year_min": {"description": "First year of the calculations"}, "year_max": {"description": "Last year of the calculations"}, "use_horizon": {"description": "Include horizon shadows"}, "horizon_db": {"description": "Source of horizon data"}}}, "plane": {"description": "plane", "fields": {"slope": {"description": "Inclination angle from the horizontal plane", "units": "degree"}, "azimuth": {"description": "Orientation (azimuth) angle of the (fixed) PV system (0 = S, 90 = W, -90 = E)", "units": "degree"}}}, "time_format": [{"description": "Local or UTC"}]}, "outputs": {"daily_profile": {"type": "time series", "timestamp": "hourly", "variables": {"G(i)": {"description": " Global irradiance on a fixed plane", "units": "W/m2"}, "Gb(i)": {"description": "Direct irradiance on a fixed plane", "units": "W/m2"}, "Gd(i)": {"description": "Diffuse irradiance on a fixed plane", "units": "W/m2"}}}}}}';

% Parse JSON data
data = jsondecode(jsonData);

% Extract time and irradiance data
daily_profile = data.outputs.daily_profile;
time = {daily_profile.time};
G_i = [daily_profile.("G_i_")];
Gb_i = [daily_profile.("Gb_i_")];
Gd_i = [daily_profile.("Gd_i_")];

% Convert time strings to datetime
time = datetime(time, 'InputFormat', 'HH:mm');

% Plot the data
figure;
hold on;
plot(time, G_i, 'DisplayName', 'Global Irradiance (G(i))');
plot(time, Gb_i, 'DisplayName', 'Direct Irradiance (Gb(i))');
plot(time, Gd_i, 'DisplayName', 'Diffuse Irradiance (Gd(i))');
hold off;

% Customize the plot
xlabel('Time of Day');
ylabel('Irradiance (W/m^2)');
title('Daily Irradiance Profile for April');
legend;
grid on;