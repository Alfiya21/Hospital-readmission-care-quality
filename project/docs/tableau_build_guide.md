# Tableau Public Build Guide (about 60–90 minutes)

**Data source:** connect to `tableau_exports/encounters_scored.csv` (one row per encounter, 99,340 rows). The `v_*.csv` files are pre-aggregated and reproduce the SQL views if you want to show the SQL lineage.

## Calculated fields
```
30D Readmit Rate   = SUM([readmit_30d]) / COUNT([encounter_id])
Avg LOS            = AVG([los_days])
High-Risk Capture  = SUM(IF [risk_tier]='High' THEN [readmit_30d] END) / SUM([readmit_30d])
Lift vs Overall    = [30D Readmit Rate] / { FIXED : SUM([readmit_30d]) / COUNT([encounter_id]) }
Small Sample Flag  = IF COUNT([encounter_id]) < 200 THEN 'Low n' ELSE 'OK' END
```

## Page 1: Executive overview
KPI tiles (30D Readmit Rate 11.4%, Avg LOS 4.4, Encounters 99,340, Patients 69,987); bar of rate by `age_group`; bar of volume by `admission_type`; filter on `gender` and `race`.

## Page 2: Drill-down
Rate by `primary_dx_group` (sorted); rate by `discharge_group`; rate by prior inpatient band (create a group on `number_inpatient`: 0, 1, 2, 3+); heat map of `age_band` × `primary_dx_group`. Use `Small Sample Flag` as colour/opacity. Add a dashboard action: click a bar → filter all sheets.

## Page 3: Risk segments
Tier bars (encounters and actual rate, reference line at overall 11.4%); High-tier table by `primary_dx_group` and `discharge_group`; text box with the model caveat (AUC 0.665, prioritisation only).

## Publish
Tableau Public → Save to Tableau Public → copy link into README. Use `docs/dashboard_preview.png` as a fallback screenshot.
Optional Power BI: rebuild Page 1 from the same CSV (cards + two bar charts) to show both tools.
