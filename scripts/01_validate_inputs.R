library(data.table)

input_dir <- file.path("data", "processed")

required_files <- c(
  "dft_tcm_leeds_public_transport_self_filtered.csv",
  "employment_destinations_r5r_wgs84.csv",
  "leeds_origins_existing_inputs_repaired.csv",
  "leeds_origins_r5r_wgs84.csv"
)

input_paths <- file.path(input_dir, required_files)

if (!all(file.exists(input_paths))) {
  stop(
    "Missing required processed input(s): ",
    paste(required_files[!file.exists(input_paths)], collapse = ", ")
  )
}

dft <- fread(input_paths[1])
destinations <- fread(input_paths[2])
origin_inputs <- fread(input_paths[3])
origins <- fread(input_paths[4])

checks <- data.table(
  dataset = c("DfT", "Employment destinations", "Origin inputs", "r5r origins"),
  rows = c(nrow(dft), nrow(destinations), nrow(origin_inputs), nrow(origins)),
  unique_ids = c(
    uniqueN(dft$LSOA21CD),
    uniqueN(destinations$id),
    uniqueN(origin_inputs$LSOA21CD),
    uniqueN(origins$id)
  )
)

print(checks)

expected_rows <- c(488L, 10050L, 488L, 488L)

if (!identical(checks$rows, expected_rows)) {
  stop("Unexpected row count in one or more processed inputs.")
}

if (!identical(checks$rows, checks$unique_ids)) {
  stop("Duplicate area identifiers found in one or more processed inputs.")
}

core_columns <- list(
  DfT = c("LSOA21CD", "Business (public transport)"),
  destinations = c("id", "name", "lon", "lat", "jobs"),
  origin_inputs = c(
    "LSOA21CD",
    "LSOA21NM",
    "imd_decile",
    "census2021_no_car_household_pct",
    "nearest_any_core_bus_network_m",
    "calls_per_active_stop_per_hour_core_06_22",
    "unique_lines_core_06_22"
  ),
  origins = c("id", "name", "lat", "lon")
)

datasets <- list(
  DfT = dft,
  destinations = destinations,
  origin_inputs = origin_inputs,
  origins = origins
)

for (dataset_name in names(datasets)) {
  missing_columns <- setdiff(core_columns[[dataset_name]], names(datasets[[dataset_name]]))
  if (length(missing_columns) > 0L) {
    stop(dataset_name, " is missing column(s): ", paste(missing_columns, collapse = ", "))
  }

  required <- core_columns[[dataset_name]]
  missing_values <- colSums(is.na(datasets[[dataset_name]][, ..required]))
  if (any(missing_values > 0L)) {
    stop(dataset_name, " contains missing values in required columns.")
  }
}

if (any(destinations$jobs < 0)) {
  stop("Employment opportunities contain negative values.")
}

message("All processed-input checks passed.")
