# Leeds accessibility method comparison

This repository contains the code and processed data used for my MSc
dissertation. The study compares three public transport accessibility measures
across 488 LSOAs in Leeds:

1. DfT Business Transport Connectivity Metric;
2. a PTAL-inspired bus supply measure;
3. bus cumulative employment accessibility.

## Repository contents

- `scripts/`: R scripts in running order;
- `data/processed/`: processed analytical inputs;
- `results/tables/`: main results and sensitivity checks;
- `results/figures/`: figures used in the dissertation;
- `data/README.md`: data sources and preparation notes.

## Running the analysis

Open `leeds-accessibility-method-comparison.Rproj` in RStudio and run the
numbered scripts in order.

Script 03 requires Java 21, `r5r`, West Yorkshire OpenStreetMap data and the
ITM Yorkshire GTFS timetable. These large third-party files are not included.
Precomputed cumulative accessibility results are provided, so the comparison
and equity analysis can be reproduced from script 04.

Software versions are recorded in `environment/session-info.txt`.
