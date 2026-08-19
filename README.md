# Comparing public transport accessibility measures in Leeds

This repository contains the reproducible analysis supporting an MSc
dissertation comparing three public transport accessibility measures across
488 Lower-layer Super Output Areas (LSOAs) in Leeds, England.

The three measures are:

1. **DfT Business Transport Connectivity Metric** - an official,
   destination-sensitive composite public transport score;
2. **PTAL-inspired bus supply measure** - an equal-weight index of proximity
   to the core bus network, service frequency and route availability;
3. **Bus cumulative employment accessibility** - the number of workplace jobs
   reachable by walking and bus within 30, 45 and 60 minutes.

The repository is intended to document the analytical workflow and allow the
published statistics and figures to be reproduced. It does not redistribute
the large third-party OpenStreetMap and GTFS network files.

## Research design

The analysis is a quantitative, cross-sectional spatial case study. All three
measures are harmonised to within-Leeds 0-100 percentile rankings before their
relative rankings and spatial patterns are compared.

Social transport need is assessed using:

- the Census 2021 percentage of households without a car or van; and
- the English Indices of Deprivation 2025 IMD decile.

The primary high-need definition identifies LSOAs that are both in IMD deciles
1-3 and in the highest Leeds quartile of no-car households. Low accessibility
is defined as a within-Leeds percentile below 25.

## Repository structure

```text
.
├── scripts/           # R scripts in execution order
├── data/
│   ├── README.md      # data dictionary, provenance and licence notes
│   └── processed/     # processed analytical inputs
├── results/
│   ├── tables/        # reproduced analysis and sensitivity outputs
│   └── figures/       # final dissertation figures
└── environment/       # software versions used for the analysis
```

## Running the analysis

Open the repository as the working directory in RStudio. Run the scripts in
numerical order:

```text
01_validate_inputs.R
02_construct_ptal_inspired.R
03_calculate_cumulative_accessibility.R
04_compare_accessibility_measures.R
05_equity_analysis.R
06_create_figures.R
```

Script `03_calculate_cumulative_accessibility.R` requires the large OSM and
GTFS files described in `data/README.md`. These should be placed locally in:

```text
data/raw/network/
```

That folder is excluded by `.gitignore`. Readers who do not wish to rebuild
the r5r network can use the included precomputed cumulative accessibility
tables and begin with script `04_compare_accessibility_measures.R`.

## Cumulative accessibility scenario

- departure: 15 July 2026 at 08:00, Europe/London;
- modes: walk and bus;
- egress mode: walk;
- departure window: 10 minutes;
- travel-time percentile: 50th percentile;
- maximum walking time: 15 minutes;
- maximum total journey duration: 60 minutes;
- maximum public transport rides: three;
- accessibility thresholds: 30, 45 and 60 minutes;
- primary threshold: 45 minutes.

The resulting indicator is specifically **bus cumulative employment
accessibility**. It should not be interpreted as including rail.

## Main reproducibility checks

- 488 unique Leeds LSOAs in all three main accessibility datasets;
- no duplicate LSOA codes or missing core analytical values;
- 10,050 unique employment destination LSOAs;
- 1,464 cumulative accessibility records (488 origins x three thresholds);
- no violations of the expected 30 <= 45 <= 60 relationship;
- 99 LSOAs under the primary high social transport need definition;
- 15 high-need LSOAs classified as low accessibility by at least one measure.

Twenty-five LSOAs returned identical cumulative results at all three travel
time thresholds, including five with zero accessibility. They were retained
without selectively moving their representative origin points and should be
interpreted cautiously.

## Data sources

Full field-level information is provided in `data/README.md`. Principal sources
are the UK Department for Transport, ONS Census 2021, English Indices of
Deprivation 2025, BRES 2024, the Bus Open Data Service/ITM Yorkshire timetable
feed, OpenStreetMap and ONS 2021 LSOA boundaries.

## Software

The analysis was conducted in R 4.5.1. The r5r network calculation used r5r
2.4.0 and Java 21. Further package and platform details are reported in
`environment/session-info.txt`.

## Reproducibility limitations

- source datasets span 2021-2026 and therefore do not represent a perfectly
  synchronised cross-section;
- each LSOA is represented by one deterministic internal origin point rather
  than a population-weighted origin surface;
- the DfT public transport metric includes multiple public transport modes,
  while the cumulative indicator is bus-only;
- the PTAL-inspired measure is not the official Transport for London PTAL;
- results are area-level, descriptive and associational rather than causal.

## Citation

If using this repository, please cite the accompanying MSc dissertation. Full
bibliographic details can be added here after the dissertation is deposited.

## Licence and third-party material

No licence is granted here for third-party data. Users must comply with the
terms of the original data providers. Source acknowledgements and links are
provided in `data/README.md`. The analysis code is supplied for academic
inspection and reproducibility; a software licence can be added separately if
the author wishes to permit reuse beyond those purposes.
