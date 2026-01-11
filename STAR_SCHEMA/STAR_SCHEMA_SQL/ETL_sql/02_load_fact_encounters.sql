-- Fact tables loading for encounters
INSERT INTO healthcare_star.fact_encounters (
    date_key,
    patient_key,
    provider_key,
    specialty_key,
    department_key,
    encounter_type_key,
    diagnosis_count,
    procedure_count,
    total_allowed_amount,
    length_of_stay,
    encounter_id
)
SELECT
    DATE_FORMAT(e.encounter_date, '%Y%m%d') AS date_key,
    dp.patient_key,
    dpr.provider_key,
    dpr.specialty_key,
    dpr.department_key,
    det.encounter_type_key,
    COUNT(DISTINCT ed.diagnosis_id) AS diagnosis_count,
    COUNT(DISTINCT ep.procedure_id) AS procedure_count,
    SUM(b.allowed_amount) AS total_allowed_amount,
    DATEDIFF(e.discharge_date, e.encounter_date) AS length_of_stay,
    e.encounter_id
FROM healthcare_oltp.encounters e
JOIN healthcare_star.dim_patient dp
    ON e.patient_id = dp.patient_id
JOIN healthcare_star.dim_provider dpr
    ON e.provider_id = dpr.provider_id
JOIN healthcare_star.dim_encounter_type det
    ON e.encounter_type = det.encounter_type_name
LEFT JOIN healthcare_oltp.encounter_diagnoses ed
    ON e.encounter_id = ed.encounter_id
LEFT JOIN healthcare_oltp.encounter_procedures ep
    ON e.encounter_id = ep.encounter_id
LEFT JOIN healthcare_oltp.billing b
    ON e.encounter_id = b.encounter_id
GROUP BY
    e.encounter_id,
    dp.patient_key,
    dpr.provider_key,
    dpr.specialty_key,
    dpr.department_key,
    det.encounter_type_key,
    date_key;
SELECT * FROM healthcare_star.fact_encounters ORDER BY encounter_id;
SELECT COUNT(*) AS total_fact_encounters FROM healthcare_star.fact_encounters;

/* =========================================================
   END OF FACT TABLES LOADING
   ========================================================= */
