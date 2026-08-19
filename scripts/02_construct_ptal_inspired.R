library(data.table)

input_file <- file.path(
  "data",
  "processed",
  "leeds_origins_existing_inputs_repaired.csv"
)

output_dir <- file.path("results", "tables")
dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)

ptal_data <- fread(input_file)

required_columns <- c(
  "LSOA21CD",
  "LSOA21NM",
  "nearest_any_core_bus_network_m",
  "calls_per_active_stop_per_hour_core_06_22",
  "unique_lines_core_06_22"
)

if (!all(required_columns %in% names(ptal_data))) {
  stop("The PTAL-inspired input is missing one or more required columns.")
}

if (anyNA(ptal_data[, ..required_columns])) {
  stop("The PTAL-inspired input contains missing values in required columns.")
}

percentile_0_100 <- function(x) {
  100 * (frank(x, ties.method = "average") - 1) / (length(x) - 1)
}

ptal_data[, walking_access_percentile :=
  percentile_0_100(-nearest_any_core_bus_network_m)]

ptal_data[, service_frequency_percentile :=
  percentile_0_100(calls_per_active_stop_per_hour_core_06_22)]

ptal_data[, route_availability_percentile :=
  percentile_0_100(unique_lines_core_06_22)]

ptal_data[, ptal_inspired_score := rowMeans(.SD), .SDcols = c(
  "walking_access_percentile",
  "service_frequency_percentile",
  "route_availability_percentile"
)]

ptal_output <- ptal_data[, .(
  LSOA21CD,
  LSOA21NM,
  nearest_any_core_bus_network_m,
  calls_per_active_stop_per_hour_core_06_22,
  unique_lines_core_06_22,
  walking_access_percentile,
  service_frequency_percentile,
  route_availability_percentile,
  ptal_inspired_score
)]

if (nrow(ptal_output) != 488L || uniqueN(ptal_output$LSOA21CD) != 488L) {
  stop("Unexpected number of Leeds LSOAs in the PTAL-inspired output.")
}

if (anyNA(ptal_output)) {
  stop("Missing values found in the PTAL-inspired output.")
}

output_file <- file.path(output_dir, "leeds_ptal_inspired_score.csv")
fwrite(ptal_output, output_file)

print(summary(ptal_output$ptal_inspired_score))
message("Saved: ", output_file)
