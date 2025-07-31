# Disaster Recovery Facility Location Optimization

Exact **P-Median**, **Tabu Search**, and **Simulated Annealing** implementations in MATLAB to choose the best locations for emergency logistics centres across the United States.

---

##  Repository Contents

| File        | Purpose |
|-------------|---------|
| **first_result.csv** | Output of the initial p-median run on the base instance |
| **locations_data.csv** | Original demand points: latitude, longitude, population |
| **locations_data_updated.csv** | Same as above + added West-coast candidate sites |
| **result.csv** | Final solution after meta-heuristic refinement |
| **us_states_real_with_probilities.csv** | Disaster occurrence probabilities by state |
| **updated_geojson_with_probabilities.json** | GeoJSON for map visualisation (probability shading) |
| **p_median_first.m** | Exact p-median solver for the original dataset |
| **p_median_adjusted.m** | Exact p-median solver after adding West-coast sites |
| **tabu_first.m** | Tabu Search on the original instance |
| **tabu_adjusted.m** | Tabu Search on the updated instance |
| **an_first.m** | Simulated Annealing on the original instance |
| **an_adjusted.m** | Simulated Annealing on the updated instance |

---

##  Problem Statement

Select **p = 5** facility locations that minimise the population- and risk-weighted travel distance from every demand point to its assigned centre, while respecting a maximum service radius.  
The data combines:

* **Population demand** – from `locations_data*.csv`  
* **Disaster probabilities** – from `us_states_real_with_probilities.csv`

---
##  Key Results
| Instance    | Method  | Objective (*10**6) |
|-------------|---------|--------------------|
| Base (5 sites) | Exact P-Median | 779.7 |
Updated (5 sites) | Simulated Annealing | 385.4 |

Adding a single West Coast centre reduces the weighted distance by ≈ 50 %.
