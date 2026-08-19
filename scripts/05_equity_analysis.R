library(data.table)

input_dir <- file.path("data", "processed")
result_dir <- file.path("results", "tables")
dir.create(result_dir, recursive = TRUE, showWarnings = FALSE)

analysis <- fread(file.path(
  result_dir,
  "leeds_three_method_analysis_with_gaps.csv"
))

need_source <- fread(file.path(
  input_dir,
  "leeds_origins_existing_inputs_repaired.csv"
))

social_need <- need_source[, .(
  LSOA21CD,
  no_car_household_pct = census2021_no_car_household_pct,
  imd_score,
  imd_decile
)]

equity <- merge(analysis, social_need, by = "LSOA21CD", all.x = TRUE)

if (nrow(equity) != 488L || uniqueN(equity$LSOA21CD) != 488L || anyNA(equity)) {
  stop("The merged equity-analysis table failed validation.")
}

no_car_q75 <- as.numeric(quantile(
  equity$no_car_household_pct,
  probs = 0.75,
  type = 7
))

equity[, `:=`(
  high_no_car = no_car_household_pct >= no_car_q75,
  high_deprivation = imd_decile <= 3,
  deprivation_level = 11 - imd_decile
)]

equity[, high_social_transport_need := high_no_car & high_deprivation]

if (sum(equity$high_social_transport_need) != 99L) {
  stop("The primary high-need definition did not identify 99 LSOAs.")
}

equity[, `:=`(
  low_dft_accessibility = dft_business_percentile < 25,
  low_ptal_accessibility = ptal_inspired_percentile < 25,
  low_cumulative_accessibility = cumulative_45min_percentile < 25
)]

equity[, low_accessibility_method_count :=
  as.integer(low_dft_accessibility) +
    as.integer(low_ptal_accessibility) +
    as.integer(low_cumulative_accessibility)]

equity[, low_accessibility_methods := fcase(
  low_dft_accessibility & low_ptal_accessibility & low_cumulative_accessibility,
  "All three",
  low_dft_accessibility & low_ptal_accessibility,
  "DfT + PTAL",
  low_dft_accessibility & low_cumulative_accessibility,
  "DfT + Cumulative",
  low_ptal_accessibility & low_cumulative_accessibility,
  "PTAL + Cumulative",
  low_dft_accessibility,
  "DfT only",
  low_ptal_accessibility,
  "PTAL only",
  low_cumulative_accessibility,
  "Cumulative only",
  default = "None"
)]

need_correlations <- data.table(
  need_measure = c("No-car household percentage", "Deprivation level"),
  dft_business_rho = round(c(
    cor(equity$no_car_household_pct, equity$dft_business_raw, method = "spearman"),
    cor(equity$deprivation_level, equity$dft_business_raw, method = "spearman")
  ), 3),
  ptal_inspired_rho = round(c(
    cor(equity$no_car_household_pct, equity$ptal_inspired_raw, method = "spearman"),
    cor(equity$deprivation_level, equity$ptal_inspired_raw, method = "spearman")
  ), 3),
  cumulative_45min_rho = round(c(
    cor(equity$no_car_household_pct, equity$cumulative_45min_raw, method = "spearman"),
    cor(equity$deprivation_level, equity$cumulative_45min_raw, method = "spearman")
  ), 3)
)

group_summary <- equity[, .(
  number_of_lsoas = .N,
  dft_business_median = median(dft_business_percentile),
  ptal_inspired_median = median(ptal_inspired_percentile),
  cumulative_45min_median = median(cumulative_45min_percentile),
  dft_business_mean = mean(dft_business_percentile),
  ptal_inspired_mean = mean(ptal_inspired_percentile),
  cumulative_45min_mean = mean(cumulative_45min_percentile)
), by = high_social_transport_need]

gap_summary <- equity[high_social_transport_need == TRUE, .(
  high_need_lsoas = .N,
  low_dft = sum(low_dft_accessibility),
  low_ptal = sum(low_ptal_accessibility),
  low_cumulative = sum(low_cumulative_accessibility),
  low_under_any_method = sum(low_accessibility_method_count > 0L),
  low_under_all_methods = sum(low_accessibility_method_count == 3L)
)]

gap_lsoas <- equity[
  high_social_transport_need == TRUE & low_accessibility_method_count > 0L,
  .(
    LSOA21CD,
    LSOA21NM,
    no_car_household_pct,
    imd_decile,
    dft_business_percentile,
    ptal_inspired_percentile,
    cumulative_45min_percentile,
    low_dft_accessibility,
    low_ptal_accessibility,
    low_cumulative_accessibility,
    low_accessibility_method_count,
    low_accessibility_methods,
    lowest_accessibility_percentile = pmin(
      dft_business_percentile,
      ptal_inspired_percentile,
      cumulative_45min_percentile
    )
  )
]

setorder(gap_lsoas, -low_accessibility_method_count, lowest_accessibility_percentile)

compare_groups <- function(variable, label) {
  high <- equity[high_social_transport_need == TRUE][[variable]]
  other <- equity[high_social_transport_need == FALSE][[variable]]
  test <- wilcox.test(high, other, exact = FALSE, conf.int = TRUE)
  u <- unname(test$statistic)

  data.table(
    accessibility_measure = label,
    high_need_n = length(high),
    other_n = length(other),
    high_need_median = median(high),
    other_median = median(other),
    median_difference = median(high) - median(other),
    mann_whitney_u = u,
    p_value = test$p.value,
    rank_biserial_effect = 2 * u / (length(high) * length(other)) - 1,
    hodges_lehmann_difference = unname(test$estimate),
    confidence_interval_low = test$conf.int[1],
    confidence_interval_high = test$conf.int[2]
  )
}

group_tests <- rbindlist(list(
  compare_groups("dft_business_percentile", "DfT Business"),
  compare_groups("ptal_inspired_percentile", "PTAL-inspired"),
  compare_groups("cumulative_45min_percentile", "Cumulative employment (45 min)")
))

need_settings <- data.table(
  need_definition = c("Strict", "Main", "Broad"),
  maximum_imd_decile = c(2L, 3L, 4L),
  no_car_quantile = c(0.80, 0.75, 0.70)
)

equity_sensitivity <- rbindlist(lapply(seq_len(nrow(need_settings)), function(i) {
  setting <- need_settings[i]
  no_car_threshold <- as.numeric(quantile(
    equity$no_car_household_pct,
    probs = setting$no_car_quantile,
    type = 7
  ))
  high_need <- equity$imd_decile <= setting$maximum_imd_decile &
    equity$no_car_household_pct >= no_car_threshold

  rbindlist(lapply(c(20, 25, 30), function(cutoff) {
    low_dft <- equity$dft_business_percentile < cutoff
    low_ptal <- equity$ptal_inspired_percentile < cutoff
    low_cumulative <- equity$cumulative_45min_percentile < cutoff
    data.table(
      need_definition = setting$need_definition,
      maximum_imd_decile = setting$maximum_imd_decile,
      no_car_top_percentage = 100 * (1 - setting$no_car_quantile),
      no_car_threshold = no_car_threshold,
      low_accessibility_cutoff = cutoff,
      high_need_lsoas = sum(high_need),
      low_dft = sum(high_need & low_dft),
      low_ptal = sum(high_need & low_ptal),
      low_cumulative = sum(high_need & low_cumulative),
      low_under_any_method = sum(high_need & (low_dft | low_ptal | low_cumulative)),
      low_under_all_methods = sum(high_need & low_dft & low_ptal & low_cumulative)
    )
  }))
}))

fwrite(equity, file.path(result_dir, "leeds_three_method_equity_analysis_ready.csv"))
fwrite(need_correlations, file.path(result_dir, "leeds_need_accessibility_correlations.csv"))
fwrite(group_summary, file.path(result_dir, "leeds_high_need_group_summary.csv"))
fwrite(group_tests, file.path(result_dir, "leeds_high_need_group_tests_effect_sizes.csv"))
fwrite(gap_summary, file.path(result_dir, "leeds_high_need_low_access_summary.csv"))
fwrite(gap_lsoas, file.path(result_dir, "leeds_high_need_low_accessibility_lsoas.csv"))
fwrite(equity_sensitivity, file.path(result_dir, "leeds_equity_threshold_sensitivity.csv"))

print(need_correlations)
print(gap_summary)
message("Saved equity-analysis outputs.")
