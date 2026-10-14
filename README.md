# Hospital Readmission Risk & Care Quality Analytics

An end-to-end analytics project on 30-day hospital readmissions for diabetic inpatients: SQL data-quality validation and KPI layer, a patient-grouped readmission-risk model, and an interactive Tableau Public dashboard, supported by stakeholder documentation (requirements brief, KPI dictionary, insights memo).

### 🔗 [**View the Live Dashboard on Tableau Public**](https://public.tableau.com/app/profile/alfiya.mulla1780/viz/HospitalReadmissionRiskCareQualityAnalytics/Dashboard1)

**Stack:** Python · SQL (SQLite) · pandas · scikit-learn · Tableau Public
**Data:** UCI *Diabetes 130-US Hospitals for years 1999–2008* (101,766 encounters, 130 hospitals) · [dataset page](https://archive.ics.uci.edu/dataset/296)

![Analysis preview](docs/dashboard_preview.png)

---

## Business problem

Hospitals are measured and penalised on avoidable 30-day readmissions, but follow-up capacity (calls, home visits, post-acute coordination) is limited. This project answers three questions for quality and operations teams:

1. Where do 30-day readmissions concentrate (age, diagnosis, admission type, discharge destination)?
2. Which patients should be prioritised for follow-up?
3. How much of the problem can a small, targeted outreach list cover?

## Headline results

| Metric | Result |
|---|---|
| Analytic population | 99,340 encounters (from 101,766 raw) |
| 30-day readmission rate | **11.4%** |
| Average length of stay | 4.4 days |
| Readmission by prior inpatient visits | **8.6%** (0 visits) → **26.4%** (3+ visits) |
| Readmission by discharge destination | **9.3%** home · **16.0%** post-acute care · **18.5%** other facility |
| Risk model ROC-AUC (patient-grouped 5-fold CV) | **0.665** (logistic regression baseline 0.655) |
| High-risk tier | Top 15% of encounters → **22.7%** readmission rate (2.0× baseline), captures **29.9%** of all 30-day readmissions |
| Low-risk tier | Bottom 50% of encounters → 6.8% readmission rate |

**Read this with care:** the model ranks groups well enough to prioritise outreach but is **not** accurate enough to judge individual patients. Higher readmission after post-acute discharge most likely reflects sicker patients, not worse facilities.

## Approach

### 1. Data-quality validation (`sql/01_validation.sql`)
Checks for duplicate encounters, missing values, invalid and out-of-range values, unmapped admission/discharge codes, and discharges that cannot lead to readmission. Results are saved to `docs/data_quality_checks.csv`.

- No duplicate encounters; no invalid age buckets, readmission labels or length-of-stay values
- `weight` is 96.9% missing, so it is not used
- `?` placeholders in race, specialty and payer code are recoded to **Unknown**, not dropped
- 2,423 expired/hospice discharges are removed from the denominator because those patients cannot be readmitted
- 3 rows with invalid gender are dropped

### 2. SQL KPI layer (`sql/02_clean_and_views.sql`)
Dimension tables for admission type, admission source and discharge disposition, a cleaned analytic view (`v_encounters_clean`), and eight KPI views: overall KPIs, and splits by age, diagnosis, admission type, discharge destination, prior inpatient visits, A1C × medication change, and risk tier. Primary diagnoses are grouped from ICD-9 codes using the Strack et al. (2014) categories.

### 3. Readmission-risk model (`src/run_pipeline.py`)
- Gradient boosting classifier predicting readmission within 30 days, with a logistic regression baseline
- **GroupKFold by patient** so the same patient never appears in both training and test folds, which prevents leakage; every encounter receives an out-of-fold score
- Risk tiers: **High** = top 15% of scores, **Medium** = 50th–85th percentile, **Low** = bottom 50%
- Strongest drivers by permutation importance: prior inpatient visits and discharge destination

### 4. Dashboard (Tableau Public)
Built on `tableau_exports/encounters_scored.csv`. It covers the executive KPI view, drill-downs by age, diagnosis, admission type, discharge destination and prior visits, and risk-tier segments. Calculated fields and sheet specifications are in `docs/tableau_build_guide.md`.

## Key insights and recommended actions

| # | Finding | Recommended action |
|---|---|---|
| 1 | Readmission triples from 8.6% to 26.4% as prior inpatient visits rise from 0 to 3+ | Enrol patients with 2+ prior inpatient visits in a transitional-care programme (72-hour follow-up call, medication review, appointment booked before discharge) |
| 2 | Post-acute and other-facility discharges are readmitted at 16.0% and 18.5% vs 9.3% for home | Introduce a structured handoff checklist and a 7-day check-in; audit case mix before assigning accountability |
| 3 | The High-risk tier holds 29.9% of readmissions in 15% of encounters | Direct limited follow-up capacity to the High tier first, then extend to Medium; review cutoffs quarterly |

Full write-up: [`docs/insights_memo.md`](docs/insights_memo.md)

## Stakeholder documentation

| Document | Purpose |
|---|---|
| [`docs/requirements_brief.md`](docs/requirements_brief.md) | Personas (Care Quality Manager, Care Transitions Lead, Clinical Lead), their questions and KPIs |
| [`docs/KPI_dictionary.md`](docs/KPI_dictionary.md) | KPI definitions, calculation logic, cleaning rules, model methodology, assumptions |
| [`docs/insights_memo.md`](docs/insights_memo.md) | Three findings, each with a recommended action |
| [`docs/tableau_build_guide.md`](docs/tableau_build_guide.md) | Calculated fields and dashboard build steps |

## Repository structure

```
├── README.md
├── src/
│   └── run_pipeline.py            # load → validate → views → model → exports
├── sql/
│   ├── 01_validation.sql          # data-quality checks
│   └── 02_clean_and_views.sql     # dimensions, clean view, KPI views
├── docs/
│   ├── requirements_brief.md
│   ├── KPI_dictionary.md
│   ├── insights_memo.md
│   ├── tableau_build_guide.md
│   ├── feedback_request_message.md
│   ├── data_quality_checks.csv
│   ├── model_metrics.json
│   └── dashboard_preview.png
├── tableau_exports/               # CSVs used by Tableau
│   ├── encounters_scored.csv
│   └── v_*.csv                    # one file per SQL view
└── data/                          # place diabetic_data.csv here (not committed)
```

## How to reproduce

```bash
git clone https://github.com/Alfiya21/<repo-name>.git
cd <repo-name>
pip install pandas scikit-learn matplotlib

# Download diabetic_data.csv from https://archive.ics.uci.edu/dataset/296
# and place it in data/

python src/run_pipeline.py
```

The script builds `readmission.db` (SQLite), prints the validation results and KPI views, and regenerates everything in `tableau_exports/` and `docs/model_metrics.json`.

## Stakeholder feedback log

*To be completed after a real review of the dashboard.*

| Version | Reviewer (role) | Feedback received | Change made | Why |
|---|---|---|---|---|
| v1 | n/a | Initial build from the requirements brief | n/a | n/a |
| v2 | *name / role* | *what was confusing or missing* | *what changed* | *reason* |

## Limitations

- Data covers 1999–2008; coding standards and clinical practice have changed
- Findings are associations, not causal effects
- Small segments (e.g. Trauma Center n=18, Newborn n=10, ages 0–10 n=160) are unreliable and should be read as directional
- Readmissions outside this hospital network are not observed
- Admission and discharge code labels were transcribed from the UCI `IDs_mapping` reference
- The model supports prioritisation only; it is not a clinical decision tool

## Author

**Alfiya Mulla** · [LinkedIn](https://linkedin.com/in/alfiyamulla) · [GitHub](https://github.com/Alfiya21) · [Portfolio](https://alfiyamulla.netlify.app)
