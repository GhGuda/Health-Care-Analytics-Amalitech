-- Load bridge tables for encounter-diagnoses
INSERT INTO healthcare_star.bridge_encounter_diagnoses (
    encounter_key,
    diagnosis_key,
    diagnosis_sequence
)
SELECT
    fe.encounter_key,
    dd.diagnosis_key,
    ed.diagnosis_sequence
FROM healthcare_oltp.encounter_diagnoses ed
JOIN healthcare_star.fact_encounters fe
    ON ed.encounter_id = fe.encounter_id
JOIN healthcare_star.dim_diagnosis dd
    ON ed.diagnosis_id = dd.diagnosis_id;
SELECT * FROM healthcare_star.bridge_encounter_diagnoses ORDER BY encounter_key, diagnosis_key;

-- Load bridge tables for encounter-procedures
INSERT INTO healthcare_star.bridge_encounter_procedures (
    encounter_key,
    procedure_key,
    procedure_date
)
SELECT
    fe.encounter_key,
    dp.procedure_key,
    ep.procedure_date   
FROM healthcare_oltp.encounter_procedures ep
JOIN healthcare_star.fact_encounters fe
    ON ep.encounter_id = fe.encounter_id
JOIN healthcare_star.dim_procedure dp
    ON ep.procedure_id = dp.procedure_id;
SELECT * FROM healthcare_star.bridge_encounter_procedures ORDER BY encounter_key, procedure_key;

/* =========================================================
   END OF BRIDGE TABLES LOADING
   ========================================================= */