library(data.table)
library(ggplot2)
library(sf)

result_dir <- file.path("results", "tables")
figure_dir <- file.path("results", "figures")
boundary_file <- file.path("data", "processed", "leeds_lsoa_boundaries.geojson")

dir.create(figure_dir, recursive = TRUE, showWarnings = FALSE)

analysis <- fread(file.path(result_dir, "leeds_three_method_analysis_with_gaps.csv"))
equity <- fread(file.path(result_dir, "leeds_three_method_equity_analysis_ready.csv"))

if (!file.exists(boundary_file)) {
  stop("Missing data/processed/leeds_lsoa_boundaries.geojson.")
}

boundaries <- st_read(boundary_file, quiet = TRUE)
boundaries <- boundaries[boundaries$LSOA21CD %in% analysis$LSOA21CD, ]

if (nrow(boundaries) != 488L) {
  stop("The boundary file does not contain exactly 488 Leeds LSOAs.")
}

rho_dft_cumulative <- cor(
  analysis$dft_business_raw,
  analysis$cumulative_45min_raw,
  method = "spearman"
)
rho_dft_ptal <- cor(
  analysis$dft_business_raw,
  analysis$ptal_inspired_raw,
  method = "spearman"
)
rho_ptal_cumulative <- cor(
  analysis$ptal_inspired_raw,
  analysis$cumulative_45min_raw,
  method = "spearman"
)

scatter_data <- rbindlist(list(
  data.table(
    comparison = sprintf("DfT Business vs Cumulative (rho = %.3f)", rho_dft_cumulative),
    x = analysis$dft_business_percentile,
    y = analysis$cumulative_45min_percentile
  ),
  data.table(
    comparison = sprintf("DfT Business vs PTAL-inspired (rho = %.3f)", rho_dft_ptal),
    x = analysis$dft_business_percentile,
    y = analysis$ptal_inspired_percentile
  ),
  data.table(
    comparison = sprintf("PTAL-inspired vs Cumulative (rho = %.3f)", rho_ptal_cumulative),
    x = analysis$ptal_inspired_percentile,
    y = analysis$cumulative_45min_percentile
  )
))

scatterplot <- ggplot(scatter_data, aes(x, y)) +
  geom_abline(slope = 1, intercept = 0, colour = "grey55", linetype = "dashed") +
  geom_point(colour = "#2166AC", alpha = 0.55, size = 1.5) +
  facet_wrap(~comparison, nrow = 1) +
  coord_equal(xlim = c(0, 100), ylim = c(0, 100)) +
  scale_x_continuous(breaks = seq(0, 100, 20)) +
  scale_y_continuous(breaks = seq(0, 100, 20)) +
  labs(
    title = "Comparison of public transport accessibility measures in Leeds",
    subtitle = "Within-Leeds percentile rankings across 488 LSOAs",
    x = "Percentile under first measure",
    y = "Percentile under second measure",
    caption = "Dashed line indicates identical percentile rankings."
  ) +
  theme_minimal(base_size = 11) +
  theme(panel.grid.minor = element_blank(), strip.text = element_text(face = "bold"))

ggsave(
  file.path(figure_dir, "leeds_three_method_percentile_scatterplots.png"),
  scatterplot,
  width = 13,
  height = 4.8,
  dpi = 300,
  bg = "white"
)

map_base <- merge(boundaries, analysis, by = "LSOA21CD", sort = FALSE)
map_base <- st_transform(map_base, 27700)

accessibility_long <- rbind(
  transform(map_base[, c("LSOA21CD", "geometry")],
    measure = "DfT Business", value = map_base$dft_business_percentile),
  transform(map_base[, c("LSOA21CD", "geometry")],
    measure = "PTAL-inspired", value = map_base$ptal_inspired_percentile),
  transform(map_base[, c("LSOA21CD", "geometry")],
    measure = "Cumulative employment (45 min)",
    value = map_base$cumulative_45min_percentile)
)

accessibility_long$measure <- factor(
  accessibility_long$measure,
  levels = c(
    "DfT Business",
    "PTAL-inspired",
    "Cumulative employment (45 min)"
  )
)

accessibility_map <- ggplot(accessibility_long) +
  geom_sf(aes(fill = value), colour = "white", linewidth = 0.08) +
  facet_wrap(~measure, nrow = 1) +
  scale_fill_viridis_c(option = "plasma", limits = c(0, 100), name = "Accessibility\npercentile") +
  labs(
    title = "Public transport accessibility across Leeds",
    subtitle = "Within-Leeds percentile rankings across 488 LSOAs"
  ) +
  theme_void(base_size = 11) +
  theme(strip.text = element_text(face = "bold", size = 12), plot.title = element_text(face = "bold"))

ggsave(
  file.path(figure_dir, "leeds_three_method_accessibility_maps.png"),
  accessibility_map,
  width = 13,
  height = 5.8,
  dpi = 300,
  bg = "white"
)

gap_long <- rbind(
  transform(map_base[, c("LSOA21CD", "geometry")],
    comparison = "DfT Business - PTAL-inspired", value = map_base$gap_dft_minus_ptal),
  transform(map_base[, c("LSOA21CD", "geometry")],
    comparison = "DfT Business - Cumulative", value = map_base$gap_dft_minus_cumulative),
  transform(map_base[, c("LSOA21CD", "geometry")],
    comparison = "PTAL-inspired - Cumulative", value = map_base$gap_ptal_minus_cumulative)
)

gap_long$comparison <- factor(
  gap_long$comparison,
  levels = c(
    "DfT Business - PTAL-inspired",
    "DfT Business - Cumulative",
    "PTAL-inspired - Cumulative"
  )
)

gap_limit <- max(abs(gap_long$value), na.rm = TRUE)

gap_map <- ggplot(gap_long) +
  geom_sf(aes(fill = value), colour = "white", linewidth = 0.08) +
  facet_wrap(~comparison, nrow = 1) +
  scale_fill_gradient2(
    low = "#2166AC",
    mid = "white",
    high = "#B2182B",
    midpoint = 0,
    limits = c(-gap_limit, gap_limit),
    name = "Percentile\ndifference"
  ) +
  labs(
    title = "Spatial disagreement between accessibility measures",
    subtitle = "Positive values indicate a higher ranking under the first measure"
  ) +
  theme_void(base_size = 11) +
  theme(strip.text = element_text(face = "bold"), plot.title = element_text(face = "bold"))

ggsave(
  file.path(figure_dir, "leeds_three_method_percentile_gap_maps.png"),
  gap_map,
  width = 13,
  height = 5.8,
  dpi = 300,
  bg = "white"
)

boxplot_data <- melt(
  equity,
  id.vars = c("LSOA21CD", "high_social_transport_need"),
  measure.vars = c(
    "dft_business_percentile",
    "ptal_inspired_percentile",
    "cumulative_45min_percentile"
  ),
  variable.name = "measure",
  value.name = "percentile"
)

boxplot_data[, need_group := factor(
  ifelse(high_social_transport_need, "High need\n(n = 99)", "Other LSOAs\n(n = 389)"),
  levels = c("Other LSOAs\n(n = 389)", "High need\n(n = 99)")
)]

boxplot_data[, measure := factor(
  measure,
  levels = c(
    "dft_business_percentile",
    "ptal_inspired_percentile",
    "cumulative_45min_percentile"
  ),
  labels = c("DfT Business", "PTAL-inspired", "Cumulative employment\n(45 min)")
)]

boxplot <- ggplot(boxplot_data, aes(need_group, percentile, fill = need_group)) +
  geom_boxplot(width = 0.58, outlier.alpha = 0.35, outlier.size = 1) +
  facet_wrap(~measure, nrow = 1) +
  scale_fill_manual(values = c("#BDBDBD", "#0072B2"), guide = "none") +
  scale_y_continuous(limits = c(0, 100), breaks = seq(0, 100, 20)) +
  labs(
    title = "Accessibility percentiles by social transport need group",
    x = NULL,
    y = "Within-Leeds accessibility percentile",
    caption = "High need: IMD deciles 1-3 and the highest quartile of no-car households."
  ) +
  theme_minimal(base_size = 11) +
  theme(panel.grid.minor = element_blank(), strip.text = element_text(face = "bold"))

ggsave(
  file.path(figure_dir, "leeds_high_need_group_boxplots.png"),
  boxplot,
  width = 10,
  height = 4.8,
  dpi = 300,
  bg = "white"
)

equity_map <- merge(
  boundaries,
  equity[, .(
    LSOA21CD,
    high_social_transport_need,
    low_accessibility_methods,
    low_accessibility_method_count
  )],
  by = "LSOA21CD",
  sort = FALSE
)
equity_map <- st_transform(equity_map, 27700)

equity_map$map_category <- "Other LSOAs"
equity_map$map_category[
  equity_map$high_social_transport_need & equity_map$low_accessibility_method_count == 0
] <- "High need, no identified low access"
equity_map$map_category[
  equity_map$high_social_transport_need & equity_map$low_accessibility_method_count > 0
] <- equity_map$low_accessibility_methods[
  equity_map$high_social_transport_need & equity_map$low_accessibility_method_count > 0
]

equity_map$map_category <- factor(
  equity_map$map_category,
  levels = c(
    "Other LSOAs",
    "High need, no identified low access",
    "PTAL only",
    "Cumulative only",
    "DfT + Cumulative",
    "PTAL + Cumulative"
  ),
  labels = c(
    "Other LSOAs (n = 389)",
    "High need, no identified low access (n = 84)",
    "PTAL only (n = 12)",
    "Cumulative only (n = 1)",
    "DfT + Cumulative (n = 1)",
    "PTAL + Cumulative (n = 1)"
  )
)

category_colours <- c(
  "Other LSOAs (n = 389)" = "#E5E5E5",
  "High need, no identified low access (n = 84)" = "#FDE725",
  "PTAL only (n = 12)" = "#CC79A7",
  "Cumulative only (n = 1)" = "#0072B2",
  "DfT + Cumulative (n = 1)" = "#D55E00",
  "PTAL + Cumulative (n = 1)" = "#009E73"
)

equity_gap_map <- ggplot(equity_map) +
  geom_sf(aes(fill = map_category), colour = "white", linewidth = 0.12) +
  scale_fill_manual(values = category_colours, name = NULL) +
  labs(
    title = "High social transport need and accessibility gaps in Leeds",
    subtitle = "High need: IMD deciles 1-3 and highest quartile of no-car households; low accessibility: lowest Leeds quartile"
  ) +
  theme_void(base_size = 11) +
  theme(plot.title = element_text(face = "bold"), legend.position = "bottom")

ggsave(
  file.path(figure_dir, "leeds_high_need_accessibility_gap_map.png"),
  equity_gap_map,
  width = 9,
  height = 7.5,
  dpi = 300,
  bg = "white"
)

message("Saved five dissertation figures.")
