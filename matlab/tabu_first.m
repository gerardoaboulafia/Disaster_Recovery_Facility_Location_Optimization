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

% Generar solución inicial aleatoria
openSet = false(J,1);
openSet(randperm(J,F)) = true;
bestSolution = openSet;
bestCost = evaluateSolution(bestSolution, weightedDistances);

currentSolution = bestSolution;
currentCost = bestCost;

tabuListLength = 10; 
tabuList = zeros(0, 2); % Lista tabú inicializada con 0 filas y 2 columnas
maxIterations = 1000;
noImproveCount = 0;
maxNoImprove = 100; % Criterio de parada
iteration = 0;

while iteration < maxIterations && noImproveCount < maxNoImprove
    iteration = iteration + 1;
    % Generar vecindario: 
    idxOpen = find(currentSolution);
    idxClosed = find(~currentSolution);
    
    bestNeighborCost = Inf;
    bestNeighborSolution = [];
    bestMove = []; % (outFacility, inFacility)
    
    for outF = idxOpen'
        for inF = idxClosed'
            move = [outF, inF];
            % Comprobar si el movimiento es tabú
            if ~isempty(tabuList) && ismember(move, tabuList, 'rows')
                continue;
            end
            % Generar solución vecina
            neighborSolution = currentSolution;
            neighborSolution(outF) = false;
            neighborSolution(inF) = true;
            neighborCost = evaluateSolution(neighborSolution, weightedDistances);
            if neighborCost < bestNeighborCost
                bestNeighborCost = neighborCost;
                bestNeighborSolution = neighborSolution;
                bestMove = move;
            end
        end
    end
    
    if isempty(bestNeighborSolution)
        % No se encontró solución vecina no tabú
        break;
    end
    
    % Actualizar solución actual
    currentSolution = bestNeighborSolution;
    currentCost = bestNeighborCost;
    
    % Actualizar lista tabú
    tabuList = [tabuList; bestMove];
    if size(tabuList,1) > tabuListLength
        tabuList(1,:) = []; % Remover el más antiguo
    end
    
    % Actualizar mejor solución
    if currentCost < bestCost
        bestCost = currentCost;
        bestSolution = currentSolution;
        noImproveCount = 0;
    else
        noImproveCount = noImproveCount + 1;
    end
end

% Preparar resultados finales
openFacilities = find(bestSolution);

% Calcular las asignaciones finales y la población servida por cada instalación abierta
[assignedFacilities, populationPerFacility] = assignSites(bestSolution, weightedDistances, M);

% Mostrar resultados en el formato solicitado

disp('Optimal Facility Locations Found:');
for f = 1:length(openFacilities)
    facilityIndex = openFacilities(f);
    latF = facilityData.lat(facilityIndex);
    lonF = facilityData.lon(facilityIndex);
    fprintf('Facility %d: Latitude = %.6f, Longitude = %.6f\n', ...
        facilityIndex, latF, lonF);
end

fprintf('\nObjective Function Value (Total Weighted Distance): %.2f\n', bestCost);

disp('Population Served by Each Opened Facility:');
for f = 1:length(openFacilities)
    facilityIndex = openFacilities(f);
    fprintf('Facility %d: Population Served = %d\n', ...
        facilityIndex, populationPerFacility(facilityIndex));
end

% --- FUNCIÓN AUXILIAR PARA EVALUAR SOLUCIÓN ---
function totalCost = evaluateSolution(openSet, weightedDistances)
    idxOpen = find(openSet);
    I = size(weightedDistances,1);
    distMin = zeros(I,1);
    for i=1:I
        distMin(i) = min(weightedDistances(i, idxOpen));
    end
    totalCost = sum(distMin);
end

% --- FUNCIÓN AUXILIAR PARA ASIGNAR SITIOS Y CALCULAR POBLACIÓN ---
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