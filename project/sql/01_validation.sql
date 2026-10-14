-- Data-quality checks on raw table. Each row: check name, count, note.
SELECT 'rows_total', COUNT(*), 'raw encounters' FROM raw_encounters;
SELECT 'duplicate_encounter_id', COUNT(*) - COUNT(DISTINCT encounter_id), 'should be 0' FROM raw_encounters;
SELECT 'patients_distinct', COUNT(DISTINCT patient_nbr), 'repeat patients present -> split by patient when modelling' FROM raw_encounters;
SELECT 'weight_missing', SUM(weight='?'), 'column unusable if >90% missing' FROM raw_encounters;
SELECT 'payer_code_missing', SUM(payer_code='?'), 'kept, flagged Unknown' FROM raw_encounters;
SELECT 'medical_specialty_missing', SUM(medical_specialty='?'), 'kept, flagged Unknown' FROM raw_encounters;
SELECT 'race_missing', SUM(race='?'), 'kept, flagged Unknown' FROM raw_encounters;
SELECT 'diag_1_missing', SUM(diag_1='?'), 'kept, grouped Other' FROM raw_encounters;
SELECT 'gender_unknown_invalid', SUM(gender='Unknown/Invalid'), 'dropped from clean' FROM raw_encounters;
SELECT 'invalid_los', SUM(time_in_hospital<1 OR time_in_hospital>14), 'outside 1-14 days' FROM raw_encounters;
SELECT 'age_bucket_invalid', SUM(age NOT LIKE '[%'), 'should be 0' FROM raw_encounters;
SELECT 'unmapped_admission_type', SUM(admission_type_id IN (5,6,8)), 'Not Available/NULL/Not Mapped -> Unknown' FROM raw_encounters;
SELECT 'unmapped_admission_source', SUM(admission_source_id IN (9,15,17,20,21)), 'Not Available/NULL/Not Mapped -> Unknown' FROM raw_encounters;
SELECT 'expired_or_hospice_discharge', SUM(discharge_disposition_id IN (11,13,14,19,20,21)), 'cannot be readmitted -> excluded from KPI denominator' FROM raw_encounters;
SELECT 'readmitted_invalid_label', SUM(readmitted NOT IN ('NO','>30','<30')), 'should be 0' FROM raw_encounters;
