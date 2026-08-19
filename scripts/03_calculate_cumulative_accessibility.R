options(java.parameters = "-Xmx12G")

if (Sys.info()[["sysname"]] == "Darwin") {
  java_home <- system("/usr/libexec/java_home -v 21", intern = TRUE)
  Sys.setenv(JAVA_HOME = java_home)
}

library(r5r)
library(data.table)

# Place the OSM PBF and GTFS ZIP in data/raw/network before running.
# data/raw is intentionally excluded from GitHub because these are large,
# third-party files. See data/README.md for source information.
network_dir <- file.path("data", "raw", "network")

origins_file <- file.path(
  "data",
  "processed",
  "leeds_origins_r5r_wgs84.csv"
)

destinations_file <- file.path(
  "data",
  "processed",
  "employment_destinations_r5r_wgs84.csv"
)

output_dir <- file.path("results", "tables")
dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)

if (!dir.exists(network_dir)) {
  stop("Missing data/raw/network. See data/README.md for required OSM and GTFS inputs.")
}

if (!all(file.exists(c(origins_file, destinations_file)))) {
  stop("Missing processed origin or destination input.")
}

origins <- fread(origins_file)
destinations <- fread(destinations_file)

if (nrow(origins) != 488L || uniqueN(origins$id) != 488L || anyNA(origins)) {
  stop("The origin input failed validation.")
}

if (
  nrow(destinations) != 10050L ||
  uniqueN(destinations$id) != 10050L ||
  anyNA(destinations)
) {
  stop("The employment-destination input failed validation.")
}

r5r_network <- build_network(data_path = network_dir, verbose = TRUE)
on.exit(stop_r5(r5r_network), add = TRUE)

origin_snap_qa <- find_snap(
  r5r_network = r5r_network,
  points = origins,
  radius = 1600,
  mode = "WALK"
)

if (nrow(origin_snap_qa) != 488L || any(!origin_snap_qa$found)) {
  stop("One or more origins could not be snapped to the walking network.")
}

fwrite(
  origin_snap_qa,
  file.path(output_dir, "leeds_origin_snap_qa.csv")
)

departure_datetime <- as.POSIXct(
  "2026-07-15 08:00:00",
  format = "%Y-%m-%d %H:%M:%S",
  tz = "Europe/London"
)

accessibility_results <- accessibility(
  r5r_network = r5r_network,
  origins = origins,
  destinations = destinations,
  opportunities_colnames = "jobs",
  mode = c("WALK", "BUS"),
  mode_egress = "WALK",
  departure_datetime = departure_datetime,
  time_window = 10L,
  percentiles = 50L,
  decay_function = "step",
  cutoffs = c(30, 45, 60),
  max_walk_time = 15,
  max_trip_duration = 60,
  max_rides = 3,
  n_threads = 8,
  verbose = FALSE,
  progress = TRUE
)

expected_rows <- nrow(origins) * 3L
if (nrow(accessibility_results) != expected_rows || anyNA(accessibility_results)) {
  stop("Unexpected dimensions or missing values in cumulative accessibility output.")
}

accessibility_wide <- dcast(
  accessibility_results,
  id ~ cutoff,
  value.var = "accessibility"
)

setnames(
  accessibility_wide,
  old = c("30", "45", "60"),
  new = c(
    "jobs_accessible_30min_bus",
    "jobs_accessible_45min_bus",
    "jobs_accessible_60min_bus"
  )
)

accessibility_wide <- merge(
  origins[, .(id, name)],
  accessibility_wide,
  by = "id",
  all.x = TRUE
)

setnames(
  accessibility_wide,
  old = c("id", "name"),
  new = c("LSOA21CD", "LSOA21NM")
)

violations <- accessibility_wide[
  jobs_accessible_30min_bus > jobs_accessible_45min_bus |
    jobs_accessible_45min_bus > jobs_accessible_60min_bus
]

if (nrow(violations) > 0L) {
  stop("Cumulative accessibility violates the expected 30 <= 45 <= 60 relationship.")
}

long_output_file <- file.path(
  output_dir,
  "leeds_bus_cumulative_accessibility_long.csv"
)

wide_output_file <- file.path(
  output_dir,
  "leeds_bus_cumulative_accessibility_lsoa.csv"
)

fwrite(accessibility_results, long_output_file)
fwrite(accessibility_wide, wide_output_file)

print(summary(accessibility_wide[, .(
  jobs_accessible_30min_bus,
  jobs_accessible_45min_bus,
  jobs_accessible_60min_bus
)]))

message("Saved: ", long_output_file)
message("Saved: ", wide_output_file)
