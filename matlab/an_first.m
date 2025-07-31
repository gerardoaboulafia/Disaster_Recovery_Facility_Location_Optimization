% Cargar datos
stateData = readtable('us_states_real_with_probabilities.csv');
facilityData = readtable('locations_data.csv');

I = height(stateData); % Número de sitios
J = height(facilityData); % Número de facilidades candidatas
M = stateData.population;
B = stateData.probability;
F = 5; % Número de instalaciones a abrir
stateCoords = [stateData.lat, stateData.lon];
facilityCoords = [facilityData.lat, facilityData.lon];
D = pdist2(stateCoords, facilityCoords); % Matriz de distancias
weightedDistances = (M .* B) .* D; % Ponderación: M_i * B_i * d_ij

%% Parámetros de Simulated Annealing
maxIterations = 1000;  % Número máximo de iteraciones total
T = 1e5;               % Temperatura inicial (ajustar según el problema)
alpha = 0.95;          % Factor de enfriamiento (0<alpha<1)
maxNoImprove = 200;    % Criterio adicional de parada por estancamiento
noImproveCount = 0;

%% Solución inicial
% Generar solución inicial aleatoria
openSet = false(J,1);
openSet(randperm(J,F)) = true;
currentSolution = openSet;
currentCost = evaluateSolution(currentSolution, weightedDistances);
bestSolution = currentSolution;
bestCost = currentCost;

%% Bucle principal de Simulated Annealing
for iter = 1:maxIterations
    % Generar una solución vecina intercambiando una instalación abierta por una cerrada
    openFacilities = find(currentSolution);
    closedFacilities = find(~currentSolution);

    outF = openFacilities(randi(length(openFacilities)));
    inF = closedFacilities(randi(length(closedFacilities)));

    neighborSolution = currentSolution;
    neighborSolution(outF) = false;
    neighborSolution(inF) = true;
    neighborCost = evaluateSolution(neighborSolution, weightedDistances);

    delta = neighborCost - currentCost;

    if delta < 0
        % La solución vecina es mejor, aceptarla directamente
        currentSolution = neighborSolution;
        currentCost = neighborCost;
        if currentCost < bestCost
            bestCost = currentCost;
            bestSolution = currentSolution;
            noImproveCount = 0;
        else
            noImproveCount = noImproveCount + 1;
        end
    else
        % La solución vecina es peor, aceptarla con probabilidad exp(-delta/T)
        if rand() < exp(-delta / T)
            currentSolution = neighborSolution;
            currentCost = neighborCost;
        end
        noImproveCount = noImproveCount + 1;
    end

    % Enfriar la temperatura
    T = T * alpha;

    % Criterio de parada por falta de mejoría
    if noImproveCount > maxNoImprove
        break;
    end
end

%% Resultados finales
openFacilities = find(bestSolution);

disp('Optimal Facility Locations Found:');
for f = 1:length(openFacilities)
    facilityIndex = openFacilities(f);
    latF = facilityData.lat(facilityIndex);
    lonF = facilityData.lon(facilityIndex);
    fprintf('Facility %d: Latitude = %.6f, Longitude = %.6f\n', ...
        facilityIndex, latF, lonF);
end

fprintf('\nObjective Function Value (Total Weighted Distance): %.2f\n', bestCost);

% Calcular asignaciones y población servida por cada instalación abierta
[assignedFacilities, populationPerFacility] = assignSites(bestSolution, weightedDistances, M);

disp('Population Served by Each Opened Facility:');
for f = 1:length(openFacilities)
    facilityIndex = openFacilities(f);
    fprintf('Facility %d: Population Served = %d\n', ...
        facilityIndex, populationPerFacility(facilityIndex));
end

%% Funciones Auxiliares

function totalCost = evaluateSolution(openSet, weightedDistances)
    idxOpen = find(openSet);
    I = size(weightedDistances,1);
    distMin = zeros(I,1);
    for i=1:I
        distMin(i) = min(weightedDistances(i, idxOpen));
    end
    totalCost = sum(distMin);
end

function [assignedFacilities, populationPerFacility] = assignSites(openSet, weightedDistances, M)
    idxOpen = find(openSet);
    I = size(weightedDistances,1);
    assignedFacilities = zeros(I,1);
    for i=1:I
        [~, bestFIdx] = min(weightedDistances(i, idxOpen));
        assignedFacilities(i) = idxOpen(bestFIdx);
    end
    % Calcular población total asignada a cada facility
    populationPerFacility = zeros(size(openSet));
    for i=1:I
        facilityAssigned = assignedFacilities(i);
        populationPerFacility(facilityAssigned) = populationPerFacility(facilityAssigned) + M(i);
    end
end