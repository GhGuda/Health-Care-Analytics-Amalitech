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