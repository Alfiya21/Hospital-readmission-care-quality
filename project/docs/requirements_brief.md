# Requirements Brief: Hospital Readmission & Care Quality Dashboard

**Version 1 · One page · Status: draft for stakeholder review**

## Purpose
Give hospital quality and operations teams a single place to see where 30-day readmissions concentrate among diabetic inpatients, and which encounters to prioritise for follow-up.

## Personas

### 1. Care Quality Manager ("Meera")
**Goal:** Reduce avoidable 30-day readmissions and report progress to the quality committee.
**Questions she needs answered**
- What is our 30-day readmission rate, and how does it split by age group, primary diagnosis and admission type?
- Which patient groups sit well above the overall rate?
- Does discharge destination matter for readmission?

**KPIs she tracks:** 30-day readmission rate · any-readmission rate · readmission rate by segment · share of readmissions captured by the High-risk tier.

### 2. Operations / Care Transitions Lead ("Rahul")
**Goal:** Decide where limited follow-up capacity (calls, home visits, post-acute coordination) is spent.
**Questions he needs answered**
- How many encounters would a High-risk outreach list contain, and what share of readmissions would it cover?
- Which discharge destinations need a handoff protocol?
- Does length of stay or admission volume point to capacity pressure?

**KPIs he tracks:** encounter volume · average length of stay · High-tier size and capture rate · readmission rate by discharge group.

### 3. Clinical Lead / Diabetes Programme (secondary)
**Questions:** Do HbA1c testing and medication changes relate to readmission? Is the pattern different for insulin-treated patients?
**KPIs:** readmission rate by A1C result × medication change.

## Dashboard pages
1. **Executive overview:** KPI tiles, trend by segment, volume.
2. **Drill-down:** age group, primary diagnosis group, admission type, discharge destination, prior inpatient visits.
3. **Risk segments:** tier sizes, actual rate by tier, capture curve.

## Scope and constraints
- Source: UCI "Diabetes 130-US Hospitals" (1999–2008, 130 hospitals). Historical data: findings are illustrative, not current practice.
- Readmission within 30 days is the primary outcome; expired/hospice discharges are excluded from the denominator.
- The model supports prioritisation only; it is not a clinical decision tool.

## Open questions for stakeholder review
1. Is "any readmission" useful, or should the dashboard show only 30-day?
2. Are three risk tiers the right granularity for outreach planning?
3. Which segment cut is missing?
