# Leeds accessibility method comparison

This repository contains the code and processed data used for my MSc
dissertation. The study compares public transport accessibility across 488
LSOAs in Leeds using three methods:

1. DfT Business Transport Connectivity Metric;
2. a PTAL-inspired bus supply measure;
3. bus cumulative employment accessibility within 30, 45 and 60 minutes.

## Repository contents

- `scripts/` contains the R scripts in running order.
- `data/processed/` contains the processed inputs used in the analysis.
- `results/tables/` contains the main results and sensitivity checks.
- `results/figures/` contains the figures used in the dissertation.
- `environment/` records the main software versions.

## Running the analysis

The scripts are numbered in the order in which they should be run:

```text
01_validate_inputs.R
02_construct_ptal_inspired.R
03_calculate_cumulative_accessibility.R
04_compare_accessibility_measures.R
05_equity_analysis.R
06_create_figures.R
```

The cumulative accessibility calculation requires Java 21, `r5r`, West
Yorkshire OpenStreetMap data and the ITM Yorkshire GTFS timetable. The OSM and
GTFS files are not included because of their file size. The precomputed
cumulative results are included, so the comparison analysis can also be
reproduced starting from script 04.

The main cumulative accessibility scenario uses walking and bus travel, a
departure time of 08:00 on 15 July 2026, and travel-time thresholds of 30, 45
and 60 minutes.

## Data sources

The analysis uses:

- DfT Transport Connectivity Metric;
- Census 2021 car availability;
- English Indices of Deprivation 2025;
- BRES workplace employment 2024;
- ITM Yorkshire GTFS;
- OpenStreetMap;
- ONS 2021 LSOA boundaries.

More information and source links are available in `data/README.md`.

## Notes

The datasets cover different years between 2021 and 2026. The cumulative
measure represents walking and bus travel and does not include rail. One
representative origin point is used for each LSOA.

Twenty-five LSOAs returned the same cumulative accessibility value at all
three time thresholds, including five with zero accessibility. These areas
were retained in the analysis.

This repository accompanies my MSc dissertation.
