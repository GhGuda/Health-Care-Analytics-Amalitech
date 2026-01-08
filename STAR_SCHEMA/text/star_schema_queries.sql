CREATE DATABASE IF NOT EXISTS healthcare_star;
USE healthcare_star;
-- Question 1: Monthly Encounters by Specialty
EXPLAIN ANALYZE
SELECT
    d.year,
    d.month_name,
    s.specialty_name,
    et.encounter_type_name AS encounter_type,
    COUNT(*) AS total_encounters,
    COUNT(DISTINCT fe.patient_key) AS unique_patients
FROM healthcare_star.fact_encounters fe
JOIN healthcare_star.dim_date d
    ON fe.date_key = d.date_key
JOIN healthcare_star.dim_specialty s
    ON fe.specialty_key = s.specialty_key
JOIN healthcare_star.dim_encounter_type et
    ON fe.encounter_type_key = et.encounter_type_key
GROUP BY
    d.year,
    d.month_name,
    s.specialty_name,
    et.encounter_type_name
ORDER BY
    d.year,
    d.month_name,
    s.specialty_name;


-- Question 2: Top Diagnosis-Procedure Pairs
EXPLAIN ANALYZE
SELECT
    dd.icd10_code,
    dd.icd10_description,
    dp.cpt_code,
    dp.cpt_description,
    COUNT(*) AS occurrence_count
FROM healthcare_star.bridge_encounter_diagnoses bed
JOIN healthcare_star.bridge_encounter_procedures bep
    ON bed.encounter_key = bep.encounter_key
JOIN healthcare_star.dim_diagnosis dd
    ON bed.diagnosis_key = dd.diagnosis_key
JOIN healthcare_star.dim_procedure dp
    ON bep.procedure_key = dp.procedure_key
GROUP BY
    dd.icd10_code,
    dd.icd10_description,
    dp.cpt_code,
    dp.cpt_description
ORDER BY
    occurrence_count DESC
LIMIT 10;



-- Question 3: 30-Day Readmission Rate

EXPLAIN ANALYZE
SELECT
    COUNT(DISTINCT fe1.encounter_key) AS total_encounters,
    COUNT(DISTINCT fe2.encounter_key) AS readmitted_encounters,
    ROUND(
        COUNT(DISTINCT fe2.encounter_key) 
        / COUNT(DISTINCT fe1.encounter_key) * 100,
        2
    ) AS readmission_rate_pct
FROM healthcare_star.fact_encounters fe1
LEFT JOIN healthcare_star.fact_encounters fe2
    ON fe1.patient_key = fe2.patient_key
   AND fe2.encounter_id <> fe1.encounter_id
   AND fe2.date_key > fe1.date_key
   AND fe2.date_key <= fe1.date_key + 30;



-- Question 4: Revenue by Specialty & Month
EXPLAIN ANALYZE
SELECT
    d.year,
    d.month,
    d.month_name,
    s.specialty_name,
    SUM(fe.total_allowed_amount) AS total_revenue
FROM healthcare_star.fact_encounters fe
JOIN healthcare_star.dim_date d
    ON fe.date_key = d.date_key
JOIN healthcare_star.dim_specialty s
    ON fe.specialty_key = s.specialty_key
GROUP BY
    d.year,
    d.month,
    d.month_name,
    s.specialty_name
ORDER BY
    d.year,
    d.month,
    total_revenue DESC;
