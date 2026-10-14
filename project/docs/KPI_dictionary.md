# KPI Dictionary & Methodology

**Source:** UCI Diabetes 130-US Hospitals (101,766 encounters raw). **Analytic population:** 99,340 encounters after cleaning rules below. All logic lives in `sql/02_clean_and_views.sql`.

## Cleaning rules (applied in `v_encounters_clean`)
| Rule | Rows affected | Reason |
|---|---|---|
| Drop gender = Unknown/Invalid | 3 | Not analysable by gender |
| Drop discharge to Expired / Hospice (codes 11, 13, 14, 19, 20, 21) | 2,423 raw | Patient cannot be readmitted; including them understates the rate |
| Race `?` → Unknown; specialty `?` → Unknown | 2,273 / 49,949 | Keep rows, make missingness visible |
| Admission type/source codes meaning "Not Available / NULL / Not Mapped" → Unknown | 10,396 / 7,067 | Same |
| `weight` not used | 98,569 missing (96.9%) | Too sparse |
| Primary diagnosis ICD-9 grouped (Strack et al. 2014 groups) | all | 700+ codes unusable raw |

## KPI definitions
| KPI | Definition | Calculation | Notes |
|---|---|---|---|
| Encounters | Inpatient encounters in analytic population | `COUNT(*)` | One row per encounter, not per patient |
| Patients | Distinct patients | `COUNT(DISTINCT patient_nbr)` | Patients can have multiple encounters |
| **30-day readmission rate** | Share of encounters followed by readmission within 30 days | `AVG(readmit_30d)` where `readmit_30d = (readmitted='<30')` | Headline KPI: **11.39%** |
| Any-readmission rate | Readmitted at any time (<30 or >30 days) | `AVG(readmit_any)` | 47.13%; includes late readmissions, less actionable |
| Average length of stay | Mean days in hospital | `AVG(time_in_hospital)` | 4.38 days; range 1–14 in source |
| Prior inpatient visits | Inpatient visits in the year before the encounter | `number_inpatient` | Banded 0 / 1 / 2 / 3+ |
| Risk score | Predicted probability of 30-day readmission | Gradient boosting, out-of-fold | See model section |
| Risk tier | High = top 15% of scores; Medium = 50th–85th percentile; Low = bottom 50% | Quantile cutoffs 0.166 / 0.099 | Chosen so High tier is a realistic outreach list |
| High-tier capture rate | Share of all 30-day readmissions that fall in the High tier | `readmissions in High tier ÷ all readmissions` | 29.9% |
| Lift | Tier rate ÷ overall rate | | High tier ≈ 2.0× |

## Model methodology
- **Target:** `readmit_30d`. **Features:** utilisation counts, length of stay, procedures/medications/diagnoses counts, age group, race, gender, admission type and source, discharge group, specialty, A1C, insulin, medication change, diabetes medication, primary diagnosis group.
- **Validation:** 5-fold **GroupKFold by `patient_nbr`**, so the same patient never appears in both training and test folds. Every encounter's score is out-of-fold.
- **Performance:** gradient boosting ROC-AUC **0.665**, PR-AUC 0.214 (base rate 0.114); logistic regression baseline 0.655. This is in line with published work on this dataset: modest signal, useful for ranking, **not** for individual prediction.
- **Top drivers (permutation importance):** prior inpatient visits, discharge destination, then smaller effects (specialty, emergency visits, diagnosis group).

## Assumptions and limitations
1. Data covers 1999–2008; coding and practice have changed.
2. Associations are not causal: e.g. higher readmission after post-acute discharge probably reflects sicker patients, not worse facilities.
3. Small segments (Trauma Center n=18, Newborn n=10, ages 0–10 n=160) are unreliable and should be suppressed or flagged in Tableau.
4. Readmission is detected only within this hospital network's records.
5. Admission-type, admission-source and discharge-code labels were transcribed from the UCI `IDs_mapping` reference; verify against the original file before publishing.
