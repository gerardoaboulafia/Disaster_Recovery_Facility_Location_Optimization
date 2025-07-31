% Load Data
locations_data = readtable('locations_data.csv');
disaster_data = readtable('us_states_real_with_probabilities.csv');

% Parameters
I = height(disaster_data); % Number of disaster sites
J = height(locations_data); % Number of candidate facility locations

% Extract data from tables
M = disaster_data.population; % Population at each site (M_i)
B = disaster_data.probability; % Disaster probability at each site (B_i)
F = 5; % Number of facilities to open (adjust as needed)
Q = ones(I, 1); % Coverage requirement for each site (Q_i)
d = pdist2([disaster_data.lat, disaster_data.lon], ...
           [locations_data.lat, locations_data.lon]); % Distance matrix

% Decision Variables
% x_j: Binary for facility locations
% z_ij: Binary for site-facility assignments

% Define optimization variables
x = optimvar('x', J, 'Type', 'integer', 'LowerBound', 0, 'UpperBound', 1);
z = optimvar('z', I, J, 'Type', 'integer', 'LowerBound', 0, 'UpperBound', 1);

% Objective Function: Minimize weighted distances
objective = sum(sum((M .* B) .* d .* z));
prob = optimproblem('Objective', objective, 'ObjectiveSense', 'minimize');

% Constraints
% 1. Open exactly F facilities
prob.Constraints.totalFacilities = sum(x) == F;

% 2. Coverage: Each site must be assigned to at least Q_i facilities
for i = 1:I
    prob.Constraints.(['coverSite_' num2str(i)]) = sum(z(i, :)) >= Q(i);
end

% 3. Assign sites only to open facilities
for i = 1:I
    for j = 1:J
        prob.Constraints.(['assign_' num2str(i) '_' num2str(j)]) = z(i, j) <= x(j);
    end
end

% Solve the problem
options = optimoptions('intlinprog', 'Display', 'iter');
[solution, fval, exitflag, output] = solve(prob, 'Options', options);

% Results
disp('Optimal Facility Locations (x):');
disp(solution.x);

disp('Site Assignments (z):');
disp(solution.z);

disp('Objective Function Value:');
disp(fval);

% Display Optimal Facility Locations
optimal_facilities = find(solution.x == 1); % Indices of opened facilities
disp('Optimal Facility Locations Found:');

% Extract latitudes and longitudes of optimal facilities
latitudes = locations_data.lat(optimal_facilities);
longitudes = locations_data.lon(optimal_facilities);

% Display the results
for i = 1:length(optimal_facilities)
    fprintf('Facility %d: Latitude = %.6f, Longitude = %.6f\n', ...
        optimal_facilities(i), latitudes(i), longitudes(i));
end

% Display Objective Function Value
fprintf('\nObjective Function Value (Total Weighted Distance): %.2f\n', fval);

% Calculate Population Served Per Facility
population_served = zeros(J, 1); % Initialize population served array

for j = 1:J
    population_served(j) = sum(M .* solution.z(:, j)); % Sum populations assigned to facility j
end

% Display Results for Opened Facilities
disp('Population Served by Each Opened Facility:');
for j = 1:J
    if solution.x(j) == 1
        fprintf('Facility %d: Population Served = %.0f\n', j, population_served(j));
    end
end