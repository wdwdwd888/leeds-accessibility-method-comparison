library(data.table)

input_dir <- file.path("data", "processed")
result_dir <- file.path("results", "tables")
dir.create(result_dir, recursive = TRUE, showWarnings = FALSE)

dft <- fread(file.path(
  input_dir,
  "dft_tcm_leeds_public_transport_self_filtered.csv"
))

ptal <- fread(file.path(result_dir, "leeds_ptal_inspired_score.csv"))
cumulative <- fread(file.path(
  result_dir,
  "leeds_bus_cumulative_accessibility_lsoa.csv"
))

if (!all(c(nrow(dft), nrow(ptal), nrow(cumulative)) == 488L)) {
  stop("One or more accessibility inputs do not contain 488 Leeds LSOAs.")
}

dft_analysis <- dft[, .(
  LSOA21CD,
  LSOA21NM,
  dft_business_raw = `Business (public transport)`,
  dft_overall_raw = `Overall (public transport)`
)]

ptal_analysis <- ptal[, .(
  LSOA21CD,
  ptal_inspired_raw = ptal_inspired_score
)]

cumulative_analysis <- cumulative[, .(
  LSOA21CD,
  cumulative_30min_raw = jobs_accessible_30min_bus,
  cumulative_45min_raw = jobs_accessible_45min_bus,
  cumulative_60min_raw = jobs_accessible_60min_bus
)]

analysis <- merge(dft_analysis, ptal_analysis, by = "LSOA21CD", all = FALSE)
analysis <- merge(analysis, cumulative_analysis, by = "LSOA21CD", all = FALSE)

if (nrow(analysis) != 488L || uniqueN(analysis$LSOA21CD) != 488L || anyNA(analysis)) {
  stop("The merged accessibility table failed validation.")
}

percentile_0_100 <- function(x) {
  100 * (frank(x, ties.method = "average") - 1) / (length(x) - 1)
}

analysis[, `:=`(
  dft_business_percentile = percentile_0_100(dft_business_raw),
  ptal_inspired_percentile = percentile_0_100(ptal_inspired_raw),
  cumulative_45min_percentile = percentile_0_100(cumulative_45min_raw),
  dft_overall_percentile = percentile_0_100(dft_overall_raw),
  cumulative_30min_percentile = percentile_0_100(cumulative_30min_raw),
  cumulative_60min_percentile = percentile_0_100(cumulative_60min_raw)
)]

analysis[, `:=`(
  gap_dft_minus_ptal = dft_business_percentile - ptal_inspired_percentile,
  gap_dft_minus_cumulative =
    dft_business_percentile - cumulative_45min_percentile,
  gap_ptal_minus_cumulative =
    ptal_inspired_percentile - cumulative_45min_percentile
)]

analysis[, three_method_range :=
  pmax(
    dft_business_percentile,
    ptal_inspired_percentile,
    cumulative_45min_percentile
  ) - pmin(
    dft_business_percentile,
    ptal_inspired_percentile,
    cumulative_45min_percentile
  )]

correlation_matrix <- cor(
  analysis[, .(
    DfT_Business = dft_business_raw,
    PTAL_inspired = ptal_inspired_raw,
    Cumulative_45min = cumulative_45min_raw
  )],
  method = "spearman"
)

print(round(correlation_matrix, 3))

threshold_sensitivity <- data.table(
  cumulative_threshold_minutes = c(30L, 45L, 60L),
  dft_business_rho = round(c(
    cor(analysis$dft_business_raw, analysis$cumulative_30min_raw, method = "spearman"),
    cor(analysis$dft_business_raw, analysis$cumulative_45min_raw, method = "spearman"),
    cor(analysis$dft_business_raw, analysis$cumulative_60min_raw, method = "spearman")
  ), 3),
  ptal_inspired_rho = round(c(
    cor(analysis$ptal_inspired_raw, analysis$cumulative_30min_raw, method = "spearman"),
    cor(analysis$ptal_inspired_raw, analysis$cumulative_45min_raw, method = "spearman"),
    cor(analysis$ptal_inspired_raw, analysis$cumulative_60min_raw, method = "spearman")
  ), 3)
)

top20 <- analysis[
  order(-three_method_range),
  .(
    LSOA21CD,
    LSOA21NM,
    dft_business_percentile,
    ptal_inspired_percentile,
    cumulative_45min_percentile,
    gap_dft_minus_ptal,
    gap_dft_minus_cumulative,
    gap_ptal_minus_cumulative,
    three_method_range
  )
][1:20]

fwrite(analysis, file.path(result_dir, "leeds_three_method_analysis_ready.csv"))
fwrite(analysis, file.path(result_dir, "leeds_three_method_analysis_with_gaps.csv"))
fwrite(top20, file.path(result_dir, "leeds_three_method_disagreement_top20.csv"))
fwrite(
  threshold_sensitivity,
  file.path(result_dir, "leeds_cumulative_threshold_sensitivity.csv")
)

message("Saved cross-method analysis and sensitivity tables.")
