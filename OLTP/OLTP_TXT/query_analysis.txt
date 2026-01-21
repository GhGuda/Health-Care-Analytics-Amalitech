
-- Question 1: Monthly Encounters by Specialty

-- a. SQL query
EXPLAIN ANALYZE
SELECT
        s.specialty_name,
        e.encounter_type,
        MONTH(e.encounter_date) AS encounter_month,
        YEAR(e.encounter_date) AS encounter_year,
        COUNT(e.encounter_id) AS total_encounters,
        COUNT(DISTINCT e.patient_id) AS unique_patients
    FROM healthcare_oltp.encounters e
        JOIN healthcare_oltp.providers p 
            ON e.provider_id = p.provider_id
        JOIN healthcare_oltp.specialties s 
            ON p.specialty_id = s.specialty_id
        GROUP BY 
            s.specialty_name,
            e.encounter_type,
            YEAR(e.encounter_date), 
            MONTH(e.encounter_date)
        ORDER BY 
            s.specialty_name,
            e.encounter_type,
            encounter_month, 
            encounter_year;

-- Schema Analysis:

-- Tables joined:
    -- healthcare_oltp.encounters

    -- healthcare_oltp.providers

    -- healthcare_oltp.specialties

-- Number of joins:
    -- 2 joins

-- Performance:

-- Execution time:
    -- ~0.37 seconds - 0.49 seconds

-- Estimated rows scanned: ~ 100,000 rows

-- Bottleneck Identified
    -- Primary bottleneck:
    -- Sorting and grouping on derived date fields over a large encounter dataset.



-- Question 2: Top Diagnosis-Procedure Pairs
EXPLAIN ANALYZE
SELECT
    d.diagnosis_id AS "ICD code",
    p.procedure_id AS "CPT code",
    COUNT(ed.encounter_diagnosis_id) AS encounter_count
    FROM healthcare_oltp.encounter_diagnoses ed
        JOIN healthcare_oltp.diagnoses d 
            ON d.diagnosis_id = ed.diagnosis_id
        JOIN healthcare_oltp.encounter_procedures ep
            ON ed.encounter_id = ep.encounter_id
        JOIN healthcare_oltp.procedures p
            ON ep.procedure_id = p.procedure_id
        GROUP BY
            d.diagnosis_id,
            p.procedure_id
        ORDER BY
            d.diagnosis_id,
            p.procedure_id,
            encounter_count DESC
            LIMIT 10;

-- Schema Analysis:

-- Tables joined:
    -- healthcare_oltp.encounter_diagnoses

    -- healthcare_oltp.diagnoses

    -- healthcare_oltp.encounter_procedures

    -- healthcare_oltp.procedures

-- Number of joins:
    -- 3 joins

-- Performance:
    -- Execution time:
        -- ~ 2.8 seconds

    -- Estimated rows scanned: ~333,000 rows

-- Bottleneck Identified:
    -- Primary bottleneck:
    -- Large many-to-many joins between encounter-level tables resulting in row explosion and expensive aggregation.



-- Question 3: 30-Day Readmission Rate
-- a. SQL query
EXPLAIN ANALYZE
SELECT
    s.specialty_name,
    COUNT(DISTINCT e1.encounter_id) AS readmission_count
FROM healthcare_oltp.encounters e1
JOIN healthcare_oltp.encounters e2
    ON e1.patient_id = e2.patient_id
JOIN healthcare_oltp.providers p
    ON e1.provider_id = p.provider_id
JOIN healthcare_oltp.specialties s
    ON p.specialty_id = s.specialty_id
WHERE e1.encounter_type = 'Inpatient'
  AND e2.encounter_date > e1.discharge_date
  AND e2.encounter_date <= DATE_ADD(e1.discharge_date, INTERVAL 30 DAY)
GROUP BY s.specialty_name
ORDER BY readmission_count DESC;

-- Schema Analysis:

-- Tables joined:
    -- healthcare_oltp.encounters (self-joined as e1 and e2)

    -- healthcare_oltp.providers

    -- healthcare_oltp.specialties

-- Number of joins:
    -- 3 joins (including the self-join)

-- Performance:
    -- Execution time:
        -- ~ 1.85 seconds

    -- Estimated rows scanned: ~ 104,000 rows

-- Bottleneck Identified:
    -- Primary bottleneck:
    -- Self-join on the encounters table combined with range-based date filtering.



-- Question 4: Revenue by Specialty & Month
-- a. SQL query
EXPLAIN ANALYZE
SELECT
    s.specialty_name,
    YEAR(e.encounter_date) AS encounter_year,
    MONTH(e.encounter_date) AS encounter_month,
    SUM(b.allowed_amount) AS total_revenue
FROM healthcare_oltp.encounters e
JOIN healthcare_oltp.providers p
    ON e.provider_id = p.provider_id
JOIN healthcare_oltp.specialties s
    ON p.specialty_id = s.specialty_id
JOIN healthcare_oltp.billing b
    ON e.encounter_id = b.encounter_id
GROUP BY
    s.specialty_name,
    YEAR(e.encounter_date),
    MONTH(e.encounter_date)
ORDER BY
    s.specialty_name,
    encounter_year,
    MONTH(e.encounter_date);


-- Schema Analysis:
-- Tables joined:
    -- healthcare_oltp.billing

    -- healthcare_oltp.encounters

    -- healthcare_oltp.providers

    -- healthcare_oltp.specialties

-- Number of joins:
    -- 3 joins

-- Performance:
    -- Execution time:
        -- 0.75 seconds

    -- Estimated rows scanned: ~ 100,000 rows

-- Bottleneck Identified:
    -- Primary bottleneck:
    -- Runtime date calculations combined with aggregation over a large transactional dataset.