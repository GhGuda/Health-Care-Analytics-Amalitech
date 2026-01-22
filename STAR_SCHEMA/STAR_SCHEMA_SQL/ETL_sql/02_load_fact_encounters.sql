DELIMITER $$

CREATE PROCEDURE healthcare_star.sp_load_fact_encounters()
BEGIN
    -- ==============================
    -- Control Variables
    -- ==============================
    DECLARE v_start_time DATETIME;
    DECLARE v_rows_affected INT DEFAULT 0;

    -- ==============================
    -- Error Handling
    -- ==============================
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;

        UPDATE healthcare_star.etl_run_log
        SET
            end_time = NOW(),
            status = 'FAILED',
            error_message = 'Error occurred during fact encounter load'
        WHERE
            process_name = '02_load_fact_encounters'
            AND start_time = v_start_time
        LIMIT 1;
        RESIGNAL;
    END;

    -- ==============================
    -- Start ETL
    -- ==============================
    SET v_start_time = NOW();

    START TRANSACTION;

    INSERT INTO healthcare_star.etl_run_log (
        process_name,
        start_time,
        status
    )
    VALUES (
        '02_load_fact_encounters',
        v_start_time,
        'RUNNING'
    );

    -- =========================================================
    -- Load fact_encounters (FULL FIELD SET)
    -- =========================================================
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
        dd.date_key,
        dp.patient_key,
        dpr.provider_key,
        ds.specialty_key,
        ddep.department_key,
        det.encounter_type_key,
        COUNT(DISTINCT ed.diagnosis_id) AS diagnosis_count,
        COUNT(DISTINCT ep.procedure_id) AS procedure_count,
        COALESCE(SUM(pr.allowed_amount), 0) AS total_allowed_amount,
        DATEDIFF(e.discharge_date, e.encounter_date) AS length_of_stay,
        e.encounter_id
    FROM healthcare_oltp.encounters e
    JOIN healthcare_star.dim_patient dp
        ON e.patient_id = dp.patient_id
    JOIN healthcare_star.dim_provider dpr
        ON e.provider_id = dpr.provider_id
    JOIN healthcare_star.dim_specialty ds
        ON dpr.specialty_key = ds.specialty_key
    JOIN healthcare_star.dim_department ddep
        ON e.department_id = ddep.department_id
    JOIN healthcare_star.dim_date dd
        ON DATE(e.encounter_date) = dd.calendar_date
    JOIN healthcare_star.dim_encounter_type det
        ON e.encounter_type = det.encounter_type_name
    LEFT JOIN healthcare_oltp.encounter_diagnoses ed
        ON e.encounter_id = ed.encounter_id
    LEFT JOIN healthcare_oltp.encounter_procedures ep
        ON e.encounter_id = ep.encounter_id
    LEFT JOIN healthcare_oltp.procedures pr
        ON ep.procedure_id = pr.procedure_id
    GROUP BY
        dd.date_key,
        dp.patient_key,
        dpr.provider_key,
        ds.specialty_key,
        ddep.department_key,
        det.encounter_type_key,
        e.encounter_id,
        e.encounter_date,
        e.discharge_date;

    SET v_rows_affected = ROW_COUNT();

    -- ==============================
    -- Commit & Log Success
    -- ==============================
    COMMIT;

    UPDATE healthcare_star.etl_run_log
    SET
        end_time = NOW(),
        status = 'SUCCESS',
        rows_affected = v_rows_affected
    WHERE
        process_name = '02_load_fact_encounters'
        AND start_time = v_start_time
    LIMIT 1;

END$$

DELIMITER;

CALL healthcare_star.sp_load_fact_encounters();