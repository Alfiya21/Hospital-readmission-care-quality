# Insights Memo: Where 30-Day Readmissions Concentrate

**To:** Care Quality Manager, Care Transitions Lead · **Data:** 99,340 diabetic inpatient encounters, 130 US hospitals, 1999–2008 · **Overall 30-day readmission rate: 11.4%**

## Bottom line
A small, identifiable group drives a disproportionate share of readmissions. Prior hospital use and discharge destination are the clearest signals, and a simple risk model can turn them into a workable outreach list.

## Finding 1: Prior inpatient visits are the strongest signal
Readmission rises from **8.6%** for patients with no prior inpatient visit in the previous year to **13.3%** (1 visit), **17.9%** (2 visits) and **26.4%** (3+ visits), roughly **3×** the zero-visit rate. About 6,800 encounters (7%) fall in the 3+ group.
**Action:** Enrol patients with 2+ prior inpatient visits in a transitional-care programme (follow-up call within 72 hours, medication review, appointment booked before discharge).

## Finding 2: Discharge destination separates low- from high-risk patients
Patients discharged **home** are readmitted at **9.3%**. Discharge to **post-acute care** (SNF, rehab, long-term care) is **16.0%** and to **other facilities 18.5%**. Home health sits at 12.7%.
**Action:** Introduce a structured handoff checklist and 7-day check-in for post-acute and facility discharges. *Caution: this likely reflects sicker patients, not worse facilities. Audit case mix before assigning accountability.*

## Finding 3: A risk tier captures 30% of readmissions from 15% of encounters
The model's High tier (top 15%, about 14,900 encounters) has a **22.7%** actual readmission rate, **2.0×** the overall rate, and contains **29.9%** of all 30-day readmissions. The Low tier (bottom 50%) runs at 6.8%.
**Action:** Direct limited follow-up capacity to the High tier first, then extend to Medium as capacity allows. Review tier cutoffs quarterly.
*Caveat:* model ROC-AUC is 0.665 (patient-grouped cross-validation). It ranks groups well enough for prioritisation but must not be used to judge individual patients.

## Supporting observations
- Primary diagnosis of **diabetes** has the highest rate (13.1%); musculoskeletal the lowest (9.5%).
- Emergency admissions: 11.8% vs elective 10.5%: a smaller gap than the factors above.
- Ages 20–29 show 14.3%, but n = 1,649 so treat as directional.

## Limitations
Historical data (1999–2008); associations, not causes; readmissions outside this network are not observed.

![Dashboard preview](dashboard_preview.png)
