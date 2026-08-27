# Comparative Evaluation of Large Language Models in Echocardiography Report Interpretation

## A Multi-AI Performance Analysis

**Master's Thesis — Artificial Intelligence for Health**  
**Institution:** Stockholm University  
**Author:** Bernard Onate Öberg
**Year:** 2026  

---

## Overview

This repository contains the analysis code, unblinded dataset, complexity scores, 
and visualisations produced as part of a master's thesis evaluating and comparing 
the performance of three large language models (LLMs) in generating echocardiography 
reports, formulating cardiovascular diagnoses, and recommending appropriate clinical 
actions based on structured echocardiographic measurements and baseline clinical data.

---

## Models Evaluated

| Model | Type | Architecture |
|---|---|---|
| ChatGPT-4o | General-purpose frontier | GPT-4o (OpenAI) |
| Gemini 3 Flash | General-purpose frontier | Gemini (Google) |
| EchoGPT | Domain-specific | Llama-2 + QLoRA fine-tuning |

---

## Study Design

- **Design:** Retrospective observational evaluation
- **Cases:** 60 curated echocardiographic cases representing a spectrum of clinical complexity
- **Reports generated:** 180 (60 cases × 3 models)
- **Evaluation:** Two independent expert sonographers, double-masked protocol
- **Scoring framework:** Adapted from Syryca et al. (2025)
  - Accuracy of findings: 1–5 Likert scale
  - Appropriateness of recommendations: 1–3 Likert scale
  - Total score: 2–8 points
- **Acceptability thresholds:**
  - Fully acceptable: 6–8 points
  - Borderline acceptable: 4–5 points
  - Not acceptable: 2–3 points

---

## Repository Structure

```text
echocardiography-llm-evaluation/
├── data/
│   ├── data_unblinded.csv          # Unblinded evaluation dataset (de-identified)
│   └── complexity_scores.csv       # Case complexity scores and tier classifications
│
├── scripts/
│   └── analysis.R                  # Complete R analysis script
│
├── figures/
│   ├── plot1_accuracy.png          # Accuracy scores by model (boxplot)
│   ├── plot2_recommendations.png   # Recommendation scores by model (boxplot)
│   ├── plot3_acceptability.png     # Report acceptability by model (stacked bar)
│   ├── plot4_best_overall.png      # Best overall preference (bar chart)
│   ├── plot5_heatmap.png           # Pairwise comparison heatmap
│   └── plot6_complexity.png        # Accuracy across complexity tiers (line graph)
│
├── LICENSE
└── README.md


---

## Key Findings

- Both ChatGPT-4o and Gemini 3 Flash significantly outperformed EchoGPT on all 
  primary outcome dimensions (all p < 0.001), contradicting the hypothesis that 
  domain-specific fine-tuning confers clinical superiority
- No significant difference was found between ChatGPT-4o and Gemini 3 Flash on 
  quantitative metrics, yet Gemini 3 Flash was preferred as best overall report 
  in 43.3% of evaluations vs 21.7% for ChatGPT-4o (χ²(2) = 9.257, p = 0.010)
- Both general-purpose models achieved 100% fully acceptable reports; EchoGPT 
  achieved 90%
- No model produced a clinically unacceptable report
- EchoGPT demonstrated a significant performance decline at moderate case complexity 
  (H = 7.435, p = 0.024), while general-purpose models remained stable

---

## How to Run the Analysis

### Requirements

- R version 4.5.3 or later
- RStudio (recommended)

### Required R packages

```r
install.packages(c("irr", "rstatix", "ggplot2", "dplyr", "tidyr", "patchwork"))
```

### Steps

1. Clone or download this repository
2. Open `scripts/analysis.R` in RStudio
3. Set your working directory to the repository root:
```r
   setwd("path/to/echocardiography-llm-evaluation")
```
4. Run the script section by section
   - Section 3.7.1: Inter-rater reliability (Cohen's kappa, ICC)
   - Section 3.7.2: Normality testing and Friedman test
   - Section 3.7.3: Descriptive statistics and Best Overall analysis
   - Section 4.5: Exploratory complexity analysis

---

## Data Description

### data_unblinded.csv

| Column | Description |
|---|---|
| record_id | Case identifier (1–60) |
| rater_id | Rater identifier (1 or 2) |
| report_num | Report number (1–3, blinded label) |
| model | Unblinded model name (ChatGPT, Gemini, EchoGPT) |
| accuracy | Accuracy score (1–5) |
| recommendation | Recommendation score (1–3) |
| total | Total score (2–8) |
| best_model | Rater's best overall selection (unblinded) |

### complexity_scores.csv

| Column | Description |
|---|---|
| record_id | Case identifier (1–60) |
| complexity_score | Number of parameters outside normal reference ranges (0–8) |
| complexity | Complexity tier (Simple / Moderate / Complex) |
| abn_lvef | LVEF abnormal flag (0/1) |
| abn_lvedd | LVEDd abnormal flag (0/1) |
| abn_ivsd | IVSd abnormal flag (0/1) |
| abn_lvpwd | LVPWd abnormal flag (0/1) |
| abn_lavi | LAVI abnormal flag (0/1) |
| abn_ntprobnp | NT-proBNP abnormal flag (0/1) |
| abn_tr_gradient | TR gradient abnormal flag (0/1) |
| abn_ee_ratio | E/E' ratio abnormal flag (0/1) |

---

## Ethical Considerations

All data used in this study were fully de-identified prior to analysis in accordance 
with GDPR (EU 2016/679). No direct or indirect patient identifiers are present in 
any file in this repository. Data were collected and managed using REDCap.

---

## Citation

If you use this code or data in your own research, please cite:
Bernard Onate Öberg (2026). Comparative Evaluation of Large Language Models in
Echocardiography Report Interpretation: A Multi-AI Performance Analysis.
Master's Thesis, Stockholm University. Available at:
https://github.com/Bernard-Onate/echocardiography-llm-evaluation


---

## Reference

Syryca F, Gräßer C, Trenkwalder T, Nicol P. Automated generation of 
echocardiography reports using artificial intelligence: a novel approach to 
streamlining cardiovascular diagnostics. The International Journal of 
Cardiovascular Imaging. 2025;41:967–977. 
https://doi.org/10.1007/s10554-025-03382-1

---

## License

This project is licensed under the Creative Commons Attribution 4.0 International 
License (CC BY 4.0). You are free to share and adapt this work for any purpose, 
provided appropriate credit is given.

See [LICENSE](LICENSE) for full terms.

---

## Contact

Bernard Onate Öberg  
obergbernard@gmail.com 
Stockholm University
