
CREATE DATABASE IF NOT EXISTS healthcare_oltp;
USE healthcare_oltp;

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
    FROM encounters e
        JOIN providers p 
            ON e.provider_id = p.provider_id
        JOIN specialties s 
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
    -- encounters

    -- providers

    -- specialties

-- Number of joins:
    -- 2 joins

-- Performance:

-- Execution time:
    -- ~4ms–7ms on small dataset

-- Estimated rows scanned:
    -- All relevant rows from encounters, plus lookups into providers and specialties

-- Bottleneck Identified:
    -- This query is slow because answering it requires multiple joins across encounters, providers, and specialties, followed by a GROUP BY on several columns.
    -- The COUNT(DISTINCT patient_id) operation is particularly expensive, as the database must track unique patients per group.
    -- As the encounters table grows, these joins and aggregations significantly increase execution time.


-- Question 2: Top Diagnosis-Procedure Pairs

SELECT
    d.diagnosis_id AS "ICD code",
    p.procedure_id AS "CPT code",
    COUNT(ed.encounter_diagnosis_id) AS encounter_count
    FROM encounter_diagnoses ed
        JOIN diagnoses d 
            ON d.diagnosis_id = ed.diagnosis_id
        JOIN encounter_procedures ep
            ON ed.encounter_id = ep.encounter_id
        JOIN procedures p
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
    -- encounter_diagnoses

    -- diagnoses

    -- encounter_procedures

    -- procedures

-- Number of joins:
    -- 3 joins

-- Performance:
    -- Execution time:
        -- ~5ms–10ms on small dataset

    -- Estimated rows scanned:
        -- Large intermediate result set created from joining two junction tables

-- Bottleneck Identified:
    -- This query is slow because it joins two junction tables (encounter_diagnoses and encounter_procedures).
    -- For encounters with multiple diagnoses and multiple procedures, the join creates row explosion, where each diagnosis is combined with each procedure.
    -- This dramatically increases the number of rows that must be grouped and counted, making the query inefficient as data volume grows.


-- Question 3: 30-Day Readmission Rate
-- a. SQL query
SELECT
    s.specialty_name,
    COUNT(DISTINCT e1.encounter_id) AS readmission_count
FROM encounters e1
JOIN encounters e2
    ON e1.patient_id = e2.patient_id
JOIN providers p
    ON e1.provider_id = p.provider_id
JOIN specialties s
    ON p.specialty_id = s.specialty_id
WHERE e1.encounter_type = 'Inpatient'
  AND e2.encounter_date > e1.discharge_date
  AND e2.encounter_date <= DATE_ADD(e1.discharge_date, INTERVAL 30 DAY)
GROUP BY s.specialty_name
ORDER BY readmission_count DESC;

-- Schema Analysis:

-- Tables joined:
    -- encounters (self-joined as e1 and e2)

    -- providers

    -- specialties

-- Number of joins:
    -- 3 joins (including the self-join)

-- Performance:
    -- Execution time:
        -- ~2ms–8ms on small dataset

    -- Estimated rows scanned:
        -- Potentially many rows from encounters, especially for patients with multiple visits

-- Bottleneck Identified:
    -- This query is slow because it uses a self-join on the encounters table, which is typically the largest table in the schema.
    -- The self-join forces the database to compare encounters for the same patient, creating a large number of row comparisons (row explosion), especially for patients with frequent visits.
    -- Date range filtering and grouping by specialty further increase computational cost as data volume grows.



-- Question 4: Revenue by Specialty & Month
-- a. SQL query
SELECT
    s.specialty_name,
    YEAR(e.encounter_date) AS encounter_year,
    MONTH(e.encounter_date) AS encounter_month,
    SUM(b.allowed_amount) AS total_revenue
FROM encounters e
JOIN providers p
    ON e.provider_id = p.provider_id
JOIN specialties s
    ON p.specialty_id = s.specialty_id
JOIN billing b
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
    -- billing

    -- encounters

    -- providers

    -- specialties

-- Number of joins:
    -- 3 joins

-- Performance:
    -- Execution time:
        -- ~6ms–12ms on small dataset

    -- Estimated rows scanned:
        -- Proportional to the size of billing and encounters tables
        -- Increases significantly as encounter volume grows

-- Bottleneck Identified:
    -- This query is slow because answering it requires a long join chain across billing, 
    -- encounters, providers, and specialties, followed by runtime aggregation and grouping by
    -- specialty and month, which increases CPU and memory usage as data volume grows.

