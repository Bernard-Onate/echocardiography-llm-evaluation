# =============================================================================
# Statistical Analysis Script
# LLM Echocardiography Report Evaluation Study
# R version 4.5.3 (2026-03-11)
# =============================================================================

# --- 0. INSTALL AND LOAD PACKAGES --------------------------------------------
# Run this line once, then comment it out
# install.packages(c("irr", "rstatix", "ggplot2", "dplyr", "tidyr", "cowplot",
#                    "knitr", "kableExtra"))

library(irr)          # Inter-rater reliability (kappa, ICC)
library(rstatix)      # Cramér's V, effect sizes
library(ggplot2)      # Plotting
library(dplyr)        # Data manipulation
library(tidyr)        # Data reshaping
library(cowplot)      # Combining plots (Fig 8)
library(knitr)        # Table formatting
library(kableExtra)   # Styled tables (Table 10)


# --- 1. LOAD DATA ------------------------------------------------------------
# Load the pre-unblinded long-format CSV (generated from Python unblinding step)
# Columns: record_id, rater_id, report_num, model, accuracy,
#          recommendation, total, comments, best_model, complexity

data <- read.csv("data_unblinded.csv", stringsAsFactors = FALSE)

# Quick sanity check
cat("=== Data overview ===\n")
cat("Rows:", nrow(data), "\n")
cat("Cases:", length(unique(data$record_id)), "\n")
cat("Models:", paste(unique(data$model), collapse = ", "), "\n")
cat("Raters:", paste(sort(unique(data$rater_id)), collapse = ", "), "\n\n")


# =============================================================================
# SECTION 4.1 — INTER-RATER RELIABILITY
# =============================================================================

# --- 4.1.1 Cohen's Kappa for Best Overall (categorical) ----------------------
cat("=== Cohen's Kappa: Best Overall ===\n")

best_wide <- data %>%
  distinct(record_id, rater_id, best_model) %>%
  pivot_wider(names_from  = rater_id,
              values_from = best_model,
              names_prefix = "rater_")

kappa_result <- kappa2(best_wide[, c("rater_1", "rater_2")])
print(kappa_result)
# kappa < 0.20 = slight | 0.21-0.40 = fair | 0.41-0.60 = moderate
# 0.61-0.80 = substantial | > 0.80 = almost perfect


# --- 4.1.2 ICC for Accuracy scores per model ---------------------------------
cat("\n=== ICC: Accuracy (per model) ===\n")

for (m in c("ChatGPT", "Gemini", "EchoGPT")) {
  cat("\n--", m, "--\n")
  acc_wide <- data %>%
    filter(model == m) %>%
    select(record_id, rater_id, accuracy) %>%
    pivot_wider(names_from  = rater_id,
                values_from = accuracy,
                names_prefix = "rater_")
  print(icc(acc_wide[, c("rater_1", "rater_2")],
            model = "twoway", type = "agreement", unit = "single"))
}


# --- ICC for Recommendation scores per model ---------------------------------
cat("\n=== ICC: Recommendations (per model) ===\n")

for (m in c("ChatGPT", "Gemini", "EchoGPT")) {
  cat("\n--", m, "--\n")
  rec_wide <- data %>%
    filter(model == m) %>%
    select(record_id, rater_id, recommendation) %>%
    pivot_wider(names_from  = rater_id,
                values_from = recommendation,
                names_prefix = "rater_")
  print(icc(rec_wide[, c("rater_1", "rater_2")],
            model = "twoway", type = "agreement", unit = "single"))
}
# ICC < 0.50 = poor | 0.50-0.75 = moderate | 0.75-0.90 = good | > 0.90 = excellent


# =============================================================================
# SECTION 4.2.1 — NORMALITY TESTING (Shapiro-Wilk)
# =============================================================================
cat("\n=== Shapiro-Wilk Normality Tests ===\n")

for (m in c("ChatGPT", "Gemini", "EchoGPT")) {
  acc <- data %>% filter(model == m) %>% pull(accuracy)
  rec <- data %>% filter(model == m) %>% pull(recommendation)
  cat("\n--", m, "Accuracy --\n");       print(shapiro.test(acc))
  cat("\n--", m, "Recommendations --\n"); print(shapiro.test(rec))
}
# p < 0.05 = non-normal -> confirms use of non-parametric tests


# =============================================================================
# SECTION 4.2.2 — FRIEDMAN TEST
# =============================================================================

# Average scores across the two raters per case per model
data_avg <- data %>%
  group_by(record_id, model) %>%
  summarise(
    accuracy       = mean(accuracy,       na.rm = TRUE),
    recommendation = mean(recommendation, na.rm = TRUE),
    total          = mean(total,          na.rm = TRUE),
    .groups        = "drop"
  )

# Reshape to wide: one row per case, one column per model
acc_wide <- data_avg %>%
  select(record_id, model, accuracy) %>%
  pivot_wider(names_from = model, values_from = accuracy)

rec_wide <- data_avg %>%
  select(record_id, model, recommendation) %>%
  pivot_wider(names_from = model, values_from = recommendation)

cat("\n=== Friedman Test: Accuracy ===\n")
print(friedman.test(as.matrix(acc_wide[, c("ChatGPT", "Gemini", "EchoGPT")])))

cat("\n=== Friedman Test: Recommendations ===\n")
print(friedman.test(as.matrix(rec_wide[, c("ChatGPT", "Gemini", "EchoGPT")])))


# =============================================================================
# SECTION 4.2.3 — POST HOC WILCOXON WITH BONFERRONI
# =============================================================================

cat("\n=== Post Hoc Wilcoxon: Accuracy ===\n")
p1 <- wilcox.test(acc_wide$ChatGPT, acc_wide$Gemini,   paired = TRUE)$p.value
p2 <- wilcox.test(acc_wide$ChatGPT, acc_wide$EchoGPT,  paired = TRUE)$p.value
p3 <- wilcox.test(acc_wide$Gemini,  acc_wide$EchoGPT,  paired = TRUE)$p.value

acc_post_hoc <- data.frame(
  Comparison  = c("ChatGPT vs Gemini", "ChatGPT vs EchoGPT", "Gemini vs EchoGPT"),
  p_raw       = round(c(p1, p2, p3), 4),
  p_bonf      = round(p.adjust(c(p1, p2, p3), method = "bonferroni"), 4),
  significant = p.adjust(c(p1, p2, p3), method = "bonferroni") < 0.05
)
print(acc_post_hoc)

cat("\n=== Post Hoc Wilcoxon: Recommendations ===\n")
p4 <- wilcox.test(rec_wide$ChatGPT, rec_wide$Gemini,   paired = TRUE)$p.value
p5 <- wilcox.test(rec_wide$ChatGPT, rec_wide$EchoGPT,  paired = TRUE)$p.value
p6 <- wilcox.test(rec_wide$Gemini,  rec_wide$EchoGPT,  paired = TRUE)$p.value

rec_post_hoc <- data.frame(
  Comparison  = c("ChatGPT vs Gemini", "ChatGPT vs EchoGPT", "Gemini vs EchoGPT"),
  p_raw       = round(c(p4, p5, p6), 4),
  p_bonf      = round(p.adjust(c(p4, p5, p6), method = "bonferroni"), 4),
  significant = p.adjust(c(p4, p5, p6), method = "bonferroni") < 0.05
)
print(rec_post_hoc)


# =============================================================================
# SECTION 4.3.1 — DESCRIPTIVE STATISTICS
# =============================================================================
cat("\n=== Descriptive Statistics by Model ===\n")

data_avg %>%
  group_by(model) %>%
  summarise(
    acc_median = median(accuracy),
    acc_IQR    = IQR(accuracy),
    acc_mean   = round(mean(accuracy), 2),
    acc_SD     = round(sd(accuracy), 2),
    rec_median = median(recommendation),
    rec_IQR    = IQR(recommendation),
    rec_mean   = round(mean(recommendation), 2),
    rec_SD     = round(sd(recommendation), 2),
    tot_median = median(total),
    tot_IQR    = IQR(total),
    tot_mean   = round(mean(total), 2),
    tot_SD     = round(sd(total), 2)
  ) %>% print()


# =============================================================================
# SECTION 4.3.2 — REPORT ACCEPTABILITY
# =============================================================================
cat("\n=== Report Acceptability by Model ===\n")

data_avg <- data_avg %>%
  mutate(category = case_when(
    total >= 6 ~ "Fully acceptable",
    total >= 4 ~ "Borderline acceptable",
    TRUE       ~ "Not acceptable"
  ))

data_avg %>%
  group_by(model, category) %>%
  summarise(n = n(), .groups = "drop") %>%
  group_by(model) %>%
  mutate(pct = round(100 * n / sum(n), 1)) %>%
  arrange(model, desc(pct)) %>%
  print()


# =============================================================================
# SECTION 4.4 — BEST OVERALL PREFERENCE
# =============================================================================

best_votes <- data %>%
  distinct(record_id, rater_id, best_model)

cat("\n=== Best Overall: All Response Categories (n=120 votes) ===\n")
best_votes %>%
  count(best_model) %>%
  mutate(pct = round(100 * n / sum(n), 1)) %>%
  arrange(desc(n)) %>%
  print()

# Model-specific votes only (exclude "All are equal" and "None are acceptable")
model_votes <- best_votes %>%
  filter(!best_model %in% c("All are equal", "None are acceptable"))

cat("\n=== Best Overall: Model-specific votes only ===\n")
model_votes %>%
  count(best_model) %>%
  mutate(pct = round(100 * n / sum(n), 1)) %>%
  arrange(desc(n)) %>%
  print()

# --- Chi-square goodness-of-fit ---------------------------------------------
cat("\n=== Chi-Square: Best Overall Preference ===\n")

votes <- c(
  ChatGPT = sum(model_votes$best_model == "ChatGPT"),
  Gemini  = sum(model_votes$best_model == "Gemini"),
  EchoGPT = sum(model_votes$best_model == "EchoGPT")
)
print(votes)
chisq_result <- chisq.test(votes, p = c(1/3, 1/3, 1/3))
print(chisq_result)

# --- Cramér's V --------------------------------------------------------------
cat("\n=== Cramér's V ===\n")
chi2      <- chisq_result$statistic
n_votes   <- sum(votes)
k         <- 3
cramers_v <- sqrt(chi2 / (n_votes * (k - 1)))
cat("Cramér's V =", round(cramers_v, 3), "\n")
cat("Interpretation (k=3): 0.10=small, 0.30=medium, 0.50=large\n")


# =============================================================================
# SECTION 4.5 — EXPLORATORY COMPLEXITY ANALYSIS
# =============================================================================

# Assumes a 'complexity' column in the CSV: "Simple", "Moderate", "Complex"
data_avg <- data_avg %>%
  left_join(
    data %>% distinct(record_id, complexity),
    by = "record_id"
  ) %>%
  mutate(complexity = factor(complexity, levels = c("Simple", "Moderate", "Complex")))


# --- Descriptive stats by model and complexity tier -------------------------
cat("\n=== Descriptive Statistics by Model x Complexity ===\n")

complexity_desc <- data_avg %>%
  group_by(complexity, model) %>%
  summarise(
    n        = n(),
    acc_mean = round(mean(accuracy), 2),
    acc_SE   = round(sd(accuracy) / sqrt(n()), 2),
    rec_mean = round(mean(recommendation), 2),
    rec_SE   = round(sd(recommendation) / sqrt(n()), 2),
    tot_mean = round(mean(total), 2),
    tot_SE   = round(sd(total) / sqrt(n()), 2),
    .groups  = "drop"
  )
print(complexity_desc)


# --- Kruskal-Wallis per model across complexity tiers -----------------------
cat("\n=== Kruskal-Wallis: Accuracy by Complexity (per model) ===\n")

for (m in c("ChatGPT", "Gemini", "EchoGPT")) {
  cat("\n--", m, "--\n")
  df <- data_avg %>% filter(model == m)
  print(kruskal.test(accuracy ~ complexity, data = df))
}

cat("\n=== Kruskal-Wallis: Recommendations by Complexity (per model) ===\n")

for (m in c("ChatGPT", "Gemini", "EchoGPT")) {
  cat("\n--", m, "--\n")
  df <- data_avg %>% filter(model == m)
  print(kruskal.test(recommendation ~ complexity, data = df))
}


# =============================================================================
# FIGURES
# =============================================================================

model_colors <- c("ChatGPT" = "#4472C4", "Gemini" = "#70AD47", "EchoGPT" = "#C0504D")
model_shapes <- c("ChatGPT" = 21,        "Gemini" = 22,        "EchoGPT" = 24)


# --- Plot 6: Accuracy Scores Across Case Complexity -------------------------

plot6_data <- data_avg %>%
  group_by(complexity, model) %>%
  summarise(
    mean_acc = mean(accuracy),
    se_acc   = sd(accuracy) / sqrt(n()),
    .groups  = "drop"
  ) %>%
  mutate(model = factor(model, levels = c("ChatGPT", "EchoGPT", "Gemini")))

plot6 <- ggplot(plot6_data, aes(x = complexity, y = mean_acc,
                                 color = model, group = model)) +
  geom_line(linewidth = 0.8) +
  geom_point(size = 3) +
  geom_errorbar(aes(ymin = mean_acc - se_acc, ymax = mean_acc + se_acc),
                width = 0.1, linewidth = 0.7) +
  scale_color_manual(values = c("ChatGPT" = "#4472C4",
                                 "EchoGPT" = "#ED7D31",
                                 "Gemini"  = "#70AD47")) +
  scale_y_continuous(limits = c(3.8, 5.1), breaks = seq(3.8, 5.0, 0.2)) +
  labs(
    title    = "Accuracy Scores Across Case Complexity",
    subtitle = "Error bars represent \u00b1 1 standard error",
    x        = "Case Complexity",
    y        = "Mean Accuracy Score (1-5)",
    color    = "Model"
  ) +
  theme_minimal(base_size = 13) +
  theme(
    panel.grid.major.x = element_blank(),
    panel.grid.minor   = element_blank(),
    plot.title         = element_text(face = "bold", size = 15),
    plot.subtitle      = element_text(size = 11),
    legend.position    = "right"
  )

print(plot6)
ggsave("plot6_complexity.png", plot6, width = 8, height = 6, dpi = 300)
cat("\nPlot 6 saved as plot6_complexity.png\n")


# --- Fig 8: Total Score and Accuracy Score Across Complexity (side-by-side) -

plot8_data <- data_avg %>%
  group_by(complexity, model) %>%
  summarise(
    mean_total = mean(total),
    se_total   = sd(total) / sqrt(n()),
    mean_acc   = mean(accuracy),
    se_acc     = sd(accuracy) / sqrt(n()),
    .groups    = "drop"
  ) %>%
  mutate(
    model      = factor(model, levels = c("ChatGPT", "Gemini", "EchoGPT")),
    complexity = factor(complexity, levels = c("Simple", "Moderate", "Complex")),
    x_label    = recode(complexity,
                        "Simple"   = "Simple\n(n = 32)",
                        "Moderate" = "Moderate\n(n = 17)",
                        "Complex"  = "Complex\n(n = 11)")
  )

# Panel A: Total Score
p_total <- ggplot(plot8_data, aes(x = x_label, y = mean_total,
                                   color = model, group = model, shape = model)) +
  geom_line(linewidth = 0.9) +
  geom_point(size = 3.5, fill = "white", stroke = 1.5) +
  geom_errorbar(aes(ymin = mean_total - se_total, ymax = mean_total + se_total),
                width = 0.12, linewidth = 0.7) +
  scale_color_manual(values = model_colors) +
  scale_shape_manual(values = model_shapes) +
  scale_y_continuous(limits = c(5.5, 8.8), breaks = seq(5.5, 8.5, 0.5)) +
  labs(x = "Case Complexity", y = "Mean Total Score") +
  theme_minimal(base_size = 12) +
  theme(
    panel.grid.major.x = element_blank(),
    panel.grid.minor   = element_blank(),
    panel.grid.major.y = element_line(linetype = "dashed", color = "grey80"),
    legend.position    = "none",
    axis.title.x       = element_text(margin = margin(t = 8)),
    axis.text.x        = element_text(face = "bold")
  )

# Panel B: Accuracy Score
p_acc <- ggplot(plot8_data, aes(x = x_label, y = mean_acc,
                                 color = model, group = model, shape = model)) +
  geom_line(linewidth = 0.9) +
  geom_point(size = 3.5, fill = "white", stroke = 1.5) +
  geom_errorbar(aes(ymin = mean_acc - se_acc, ymax = mean_acc + se_acc),
                width = 0.12, linewidth = 0.7) +
  scale_color_manual(values = model_colors) +
  scale_shape_manual(values = model_shapes) +
  scale_y_continuous(limits = c(3.5, 5.5), breaks = seq(3.5, 5.5, 0.25)) +
  labs(x = "Case Complexity", y = "Mean Accuracy Score") +
  theme_minimal(base_size = 12) +
  theme(
    panel.grid.major.x = element_blank(),
    panel.grid.minor   = element_blank(),
    panel.grid.major.y = element_line(linetype = "dashed", color = "grey80"),
    legend.position    = "none",
    axis.title.x       = element_text(margin = margin(t = 8)),
    axis.text.x        = element_text(face = "bold")
  )

# Shared legend
legend_plot <- ggplot(plot8_data, aes(x = x_label, y = mean_total,
                                       color = model, shape = model)) +
  geom_point(size = 3) +
  scale_color_manual(values = model_colors, name = NULL) +
  scale_shape_manual(values = model_shapes, name = NULL) +
  theme_minimal() +
  theme(legend.position  = "bottom",
        legend.direction = "horizontal",
        legend.text      = element_text(size = 11))

shared_legend <- cowplot::get_legend(legend_plot)

caption <- ggdraw() +
  draw_label("Mean \u00b1 SE across complexity tiers per model",
             fontface = "italic", size = 10, color = "grey40")

top_row <- plot_grid(p_total, p_acc, ncol = 2, align = "h")
plot8   <- plot_grid(top_row, shared_legend, caption,
                     ncol = 1, rel_heights = c(1, 0.08, 0.06))

print(plot8)
ggsave("fig8.png", plot8, width = 12, height = 6, dpi = 300)
cat("\nFig 8 saved as fig8.png\n")


# =============================================================================
# TABLE 10 — DESCRIPTIVE STATISTICS BY COMPLEXITY AND MODEL
# =============================================================================

table10_data <- data_avg %>%
  group_by(complexity, model) %>%
  summarise(
    N          = n(),
    tot_median = median(total),
    tot_IQR    = IQR(total),
    acc_median = median(accuracy),
    acc_IQR    = IQR(accuracy),
    rec_median = median(recommendation),
    rec_IQR    = IQR(recommendation),
    .groups    = "drop"
  ) %>%
  mutate(
    `Total Score Median (IQR)`    = paste0(tot_median, " (", tot_IQR, ")"),
    `Accuracy Score Median (IQR)` = paste0(acc_median, " (", acc_IQR, ")"),
    `Rec Score Median (IQR)`      = paste0(rec_median, " (", rec_IQR, ")")
  ) %>%
  select(complexity, model, N,
         `Total Score Median (IQR)`,
         `Accuracy Score Median (IQR)`,
         `Rec Score Median (IQR)`) %>%
  mutate(complexity = factor(complexity, levels = c("Simple", "Moderate", "Complex"))) %>%
  arrange(complexity, model)

table10_data %>%
  kbl(
    col.names = c("Complexity", "Model", "N",
                  "Total Score Median (IQR)",
                  "Accuracy Score Median (IQR)",
                  "Rec Score Median (IQR)"),
    align     = c("l", "l", "c", "l", "l", "l"),
    booktabs  = TRUE
  ) %>%
  kable_styling(full_width = TRUE, bootstrap_options = c("striped", "bordered")) %>%
  pack_rows("Simple",   1, 3, background = "#dce6f1") %>%
  pack_rows("Moderate", 4, 6, background = "#dce6f1") %>%
  pack_rows("Complex",  7, 9, background = "#dce6f1") %>%
  row_spec(c(1, 4, 7), background = "#dce6f1") %>%
  row_spec(c(2, 5, 8), background = "#fce4d6") %>%
  row_spec(c(3, 6, 9), background = "#e2efda") %>%
  column_spec(1, bold = TRUE, color = "white", background = "#1f2d3d")
