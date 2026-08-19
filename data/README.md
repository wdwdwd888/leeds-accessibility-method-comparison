# Data documentation

## Processed files included in this repository

| File | Rows | Purpose |
|---|---:|---|
| `dft_tcm_leeds_public_transport_self_filtered.csv` | 488 | Seven published DfT public transport connectivity scores for Leeds LSOAs |
| `leeds_origins_existing_inputs_repaired.csv` | 488 | PTAL-inspired components, Census no-car percentage and IMD fields |
| `leeds_origins_r5r_wgs84.csv` | 488 | Deterministic LSOA representative points used as r5r origins |
| `employment_destinations_r5r_wgs84.csv` | 10,050 | BRES workplace employment opportunities and destination coordinates |
| `leeds_lsoa_boundaries.geojson` | 488 | Leeds 2021 LSOA boundaries used for mapping |

The two fields `reachable_graph_snap_offset_any_m` and
`reachable_graph_snap_offset_hf_m` in
`leeds_origins_existing_inputs_repaired.csv` are populated only for the nine
walking-network cases that required repair. Blank values in those audit fields
are therefore expected and are not missing values in the core analysis.

## Source data

### DfT Transport Connectivity Metric

- period used: Q4 2024;
- geography: 2021 LSOA;
- primary field: `Business (public transport)`;
- source: https://www.gov.uk/government/publications/transport-connectivity-metric

The repository contains the Leeds subset of the published national workbook.
The DfT workbook provides final connectivity scores but not the full underlying
origin-destination travel-time matrix.

### Census 2021 car availability

- variable: percentage of households with no car or van;
- geography: 2021 LSOA;
- source: https://www.ons.gov.uk/datasets/RM008/editions/2021/versions/1

### English Indices of Deprivation 2025

- fields used: IMD score and IMD decile;
- geography: 2021 LSOA;
- source: https://www.gov.uk/government/statistics/english-indices-of-deprivation-2025

IMD is a relative area-level measure and should not be interpreted as an
individual measure of poverty.

### BRES workplace employment 2024

- variable: total workplace employment;
- geography: 2021 LSOA;
- dataset: BRES open access;
- source: https://www.nomisweb.co.uk/datasets/newbres6pub

The destination set contains 10,050 LSOAs within 100 km of at least one Leeds
origin. Destinations are not restricted to the Leeds administrative boundary,
allowing neighbouring labour markets such as Bradford and Wakefield to be
represented.

### Bus timetable data

- feed: ITM Yorkshire GTFS;
- feed date used: 15 July 2026;
- source information: https://data.bus-data.dft.gov.uk/timetable/download/

The GTFS ZIP is not redistributed because it is a large third-party network
input. To rebuild the r5r network, place the original ZIP in
`data/raw/network/`.

### OpenStreetMap road network

- extract: West Yorkshire;
- extract date used: 6 August 2026;
- provider: Geofabrik;
- source: https://download.geofabrik.de/europe/united-kingdom/england/west-yorkshire.html

The `.osm.pbf` file and generated r5r network files are not redistributed.
OpenStreetMap data are available under the Open Database Licence and require
OpenStreetMap attribution.

### 2021 LSOA boundaries

- geography: Lower-layer Super Output Areas, December 2021;
- source: ONS Open Geography Portal;
- general geography documentation:
  https://www.ons.gov.uk/methodology/geography/ukgeographies/censusgeographies/census2021geographies

The included GeoJSON was filtered by the 488 LSOA codes in the final Leeds
analysis table. No Sheffield geometries are included.

## Large local-only inputs

The following files are required only when rebuilding cumulative accessibility
from scratch and are deliberately excluded from GitHub:

```text
data/raw/network/west-yorkshire-*.osm.pbf
data/raw/network/itm_yorkshire_gtfs_*.zip
data/raw/network/network.dat
data/raw/network/*.mapdb*
```

Users who do not rebuild the network can reproduce the cross-method,
statistical, equity and figure analyses from the processed and precomputed
tables included in this repository.

## Attribution and reuse

The inclusion of processed analytical inputs does not replace the licences or
terms of the original providers. Users should consult and cite the original
sources. In particular, OpenStreetMap-derived material requires attribution to
OpenStreetMap contributors.
