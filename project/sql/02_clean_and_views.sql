DROP VIEW IF EXISTS v_kpi_overview; DROP VIEW IF EXISTS v_by_age; DROP VIEW IF EXISTS v_by_diagnosis;
DROP VIEW IF EXISTS v_by_admission_type; DROP VIEW IF EXISTS v_by_discharge; DROP VIEW IF EXISTS v_by_prior_inpatient;
DROP VIEW IF EXISTS v_by_a1c_med; DROP VIEW IF EXISTS v_risk_tiers; DROP VIEW IF EXISTS v_encounters_clean;
DROP TABLE IF EXISTS dim_admission_type; DROP TABLE IF EXISTS dim_discharge; DROP TABLE IF EXISTS dim_admission_source;

CREATE TABLE dim_admission_type(id INT PRIMARY KEY, label TEXT);
INSERT INTO dim_admission_type VALUES (1,'Emergency'),(2,'Urgent'),(3,'Elective'),(4,'Newborn'),(5,'Unknown'),(6,'Unknown'),(7,'Trauma Center'),(8,'Unknown');

CREATE TABLE dim_discharge(id INT PRIMARY KEY, label TEXT, grp TEXT, is_terminal INT);
INSERT INTO dim_discharge VALUES
(1,'Discharged to home','Home',0),(2,'Short-term hospital','Other facility',0),(3,'Skilled nursing facility','Post-acute care',0),
(4,'Intermediate care facility','Post-acute care',0),(5,'Other inpatient institution','Other facility',0),(6,'Home with home health','Home health',0),
(7,'Left against medical advice','AMA',0),(8,'Home under IV care','Home health',0),(9,'Admitted as inpatient','Other facility',0),
(10,'Neonate to another hospital','Other facility',0),(11,'Expired','Expired/Hospice',1),(12,'Still patient','Other facility',0),
(13,'Hospice - home','Expired/Hospice',1),(14,'Hospice - medical facility','Expired/Hospice',1),(15,'Swing bed','Post-acute care',0),
(16,'Outpatient to another institution','Other facility',0),(17,'Outpatient','Other facility',0),(18,'Unknown','Unknown',0),
(19,'Expired at home (Medicaid hospice)','Expired/Hospice',1),(20,'Expired in medical facility','Expired/Hospice',1),(21,'Expired, place unknown','Expired/Hospice',1),
(22,'Rehabilitation facility','Post-acute care',0),(23,'Long-term care hospital','Post-acute care',0),(24,'Nursing facility (Medicaid)','Post-acute care',0),
(25,'Unknown','Unknown',0),(26,'Unknown','Unknown',0),(27,'Federal health facility','Other facility',0),(28,'Psychiatric hospital','Other facility',0),
(29,'Critical access hospital','Other facility',0),(30,'Other health care institution','Other facility',0);

CREATE TABLE dim_admission_source(id INT PRIMARY KEY, label TEXT);
INSERT INTO dim_admission_source VALUES (1,'Physician referral'),(2,'Clinic referral'),(3,'HMO referral'),(4,'Transfer from hospital'),(5,'Transfer from SNF'),
(6,'Transfer from other facility'),(7,'Emergency room'),(8,'Court/law enforcement'),(9,'Unknown'),(10,'Transfer from critical access hospital'),(11,'Normal delivery'),
(12,'Premature delivery'),(13,'Sick baby'),(14,'Extramural birth'),(15,'Unknown'),(17,'Unknown'),(18,'Transfer from home health agency'),(19,'Readmission to same home health agency'),
(20,'Unknown'),(21,'Unknown'),(22,'Transfer within hospital'),(23,'Born inside hospital'),(24,'Born outside hospital'),(25,'Transfer from ambulatory surgery'),(26,'Transfer from hospice');

-- Clean analytic view. Business rules documented in docs/KPI_dictionary.md
CREATE VIEW v_encounters_clean AS
SELECT
  r.encounter_id, r.patient_nbr,
  CASE WHEN r.race='?' THEN 'Unknown' ELSE r.race END AS race,
  r.gender,
  r.age AS age_group,
  CASE r.age WHEN '[0-10)' THEN '0-29' WHEN '[10-20)' THEN '0-29' WHEN '[20-30)' THEN '0-29'
       WHEN '[30-40)' THEN '30-49' WHEN '[40-50)' THEN '30-49' WHEN '[50-60)' THEN '50-59'
       WHEN '[60-70)' THEN '60-69' WHEN '[70-80)' THEN '70-79' ELSE '80+' END AS age_band,
  r.time_in_hospital AS los_days,
  t.label AS admission_type, s.label AS admission_source,
  d.label AS discharge_label, d.grp AS discharge_group,
  CASE WHEN r.medical_specialty='?' THEN 'Unknown' ELSE r.medical_specialty END AS specialty,
  r.num_lab_procedures, r.num_procedures, r.num_medications,
  r.number_outpatient, r.number_emergency, r.number_inpatient, r.number_diagnoses,
  r.A1Cresult AS a1c_result, r.insulin, r."change" AS med_change, r.diabetesMed AS on_diabetes_med,
  CASE
    WHEN r.diag_1 IS NULL OR r.diag_1='?' OR r.diag_1 LIKE 'V%' OR r.diag_1 LIKE 'E%' THEN 'Other'
    WHEN r.diag_1 LIKE '250%' THEN 'Diabetes'
    WHEN CAST(r.diag_1 AS REAL) BETWEEN 390 AND 459 OR CAST(r.diag_1 AS REAL)=785 THEN 'Circulatory'
    WHEN CAST(r.diag_1 AS REAL) BETWEEN 460 AND 519 OR CAST(r.diag_1 AS REAL)=786 THEN 'Respiratory'
    WHEN CAST(r.diag_1 AS REAL) BETWEEN 520 AND 579 OR CAST(r.diag_1 AS REAL)=787 THEN 'Digestive'
    WHEN CAST(r.diag_1 AS REAL) BETWEEN 580 AND 629 OR CAST(r.diag_1 AS REAL)=788 THEN 'Genitourinary'
    WHEN CAST(r.diag_1 AS REAL) BETWEEN 800 AND 999 THEN 'Injury'
    WHEN CAST(r.diag_1 AS REAL) BETWEEN 710 AND 739 THEN 'Musculoskeletal'
    WHEN CAST(r.diag_1 AS REAL) BETWEEN 140 AND 239 THEN 'Neoplasms'
    ELSE 'Other' END AS primary_dx_group,
  r.readmitted,
  CASE WHEN r.readmitted='<30' THEN 1 ELSE 0 END AS readmit_30d,
  CASE WHEN r.readmitted IN ('<30','>30') THEN 1 ELSE 0 END AS readmit_any
FROM raw_encounters r
LEFT JOIN dim_admission_type t ON t.id=r.admission_type_id
LEFT JOIN dim_admission_source s ON s.id=r.admission_source_id
LEFT JOIN dim_discharge d ON d.id=r.discharge_disposition_id
WHERE r.gender IN ('Male','Female')
  AND r.encounter_id IN (SELECT MIN(encounter_id) FROM raw_encounters GROUP BY encounter_id)
  AND d.is_terminal = 0;

CREATE VIEW v_kpi_overview AS
SELECT COUNT(*) AS encounters, COUNT(DISTINCT patient_nbr) AS patients,
  ROUND(100.0*AVG(readmit_30d),2) AS readmit_30d_pct,
  ROUND(100.0*AVG(readmit_any),2) AS readmit_any_pct,
  ROUND(AVG(los_days),2) AS avg_los_days,
  ROUND(AVG(num_medications),1) AS avg_medications
FROM v_encounters_clean;

CREATE VIEW v_by_age AS
SELECT age_group, COUNT(*) AS encounters, ROUND(100.0*AVG(readmit_30d),2) AS readmit_30d_pct, ROUND(AVG(los_days),2) AS avg_los_days
FROM v_encounters_clean GROUP BY age_group ORDER BY age_group;

CREATE VIEW v_by_diagnosis AS
SELECT primary_dx_group, COUNT(*) AS encounters, ROUND(100.0*AVG(readmit_30d),2) AS readmit_30d_pct, ROUND(AVG(los_days),2) AS avg_los_days
FROM v_encounters_clean GROUP BY primary_dx_group ORDER BY readmit_30d_pct DESC;

CREATE VIEW v_by_admission_type AS
SELECT admission_type, COUNT(*) AS encounters, ROUND(100.0*AVG(readmit_30d),2) AS readmit_30d_pct, ROUND(AVG(los_days),2) AS avg_los_days
FROM v_encounters_clean GROUP BY admission_type ORDER BY encounters DESC;

CREATE VIEW v_by_discharge AS
SELECT discharge_group, COUNT(*) AS encounters, ROUND(100.0*AVG(readmit_30d),2) AS readmit_30d_pct
FROM v_encounters_clean GROUP BY discharge_group ORDER BY readmit_30d_pct DESC;

CREATE VIEW v_by_prior_inpatient AS
SELECT CASE WHEN number_inpatient=0 THEN '0' WHEN number_inpatient=1 THEN '1' WHEN number_inpatient=2 THEN '2' ELSE '3+' END AS prior_inpatient_visits,
  COUNT(*) AS encounters, ROUND(100.0*AVG(readmit_30d),2) AS readmit_30d_pct
FROM v_encounters_clean GROUP BY 1 ORDER BY 1;

CREATE VIEW v_by_a1c_med AS
SELECT a1c_result, med_change, COUNT(*) AS encounters, ROUND(100.0*AVG(readmit_30d),2) AS readmit_30d_pct
FROM v_encounters_clean GROUP BY a1c_result, med_change;
