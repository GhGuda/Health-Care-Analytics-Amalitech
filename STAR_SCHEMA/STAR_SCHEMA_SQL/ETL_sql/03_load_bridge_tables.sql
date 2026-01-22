DELIMITER $$

CREATE PROCEDURE healthcare_star.sp_load_bridge_tables()
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
            error_message = 'Error occurred during bridge table load'
        WHERE
            process_name = '03_load_bridge_tables'
            AND start_time = v_start_time
        LIMIT 1;
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
        '03_load_bridge_tables',
        v_start_time,
        'RUNNING'
    );

    -- =========================================================
    -- Load bridge_encounter_diagnosis
    -- =========================================================
    INSERT INTO healthcare_star.bridge_encounter_diagnosis (
        encounter_key,
        diagnosis_key
    )
    SELECT
        fe.fact_encounter_key,
        dd.diagnosis_key
    FROM healthcare_oltp.encounter_diagnoses ed
    JOIN healthcare_star.fact_encounters fe
        ON ed.encounter_id = fe.encounter_id
    JOIN healthcare_star.dim_diagnosis dd
        ON ed.diagnosis_id = dd.diagnosis_id;

    SET v_rows_affected = v_rows_affected + ROW_COUNT();

    -- =========================================================
    -- Load bridge_encounter_procedure
    -- =========================================================
    INSERT INTO healthcare_star.bridge_encounter_procedure (
        encounter_key,
        procedure_key
    )
    SELECT
        fe.fact_encounter_key,
        dp.procedure_key
    FROM healthcare_oltp.encounter_procedures ep
    JOIN healthcare_star.fact_encounters fe
        ON ep.encounter_id = fe.encounter_id
    JOIN healthcare_star.dim_procedure dp
        ON ep.procedure_id = dp.procedure_id;

    SET v_rows_affected = v_rows_affected + ROW_COUNT();

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
        process_name = '03_load_bridge_tables'
        AND start_time = v_start_time
    LIMIT 1;

END$$

DELIMITER ;

CALL healthcare_star.sp_load_bridge_tables();
