USE healthcare_star;

DELIMITER $$

CREATE PROCEDURE healthcare_star.sp_load_dimensions()
BEGIN
    -- ==============================
    -- Control Variables
    -- ==============================
    DECLARE v_start_time DATETIME;
    DECLARE v_rows_affected INT DEFAULT 0;

    -- ==============================
    -- Error Handling (Enterprise)
    -- ==============================
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;

        UPDATE healthcare_star.etl_run_log
        SET
            end_time = NOW(),
            status = 'FAILED',
            error_message = 'Error occurred during dimension load'
        WHERE
            process_name = '01_load_dimensions'
            AND start_time = v_start_time
        LIMIT 1;
    END;

    -- ==============================
    -- Start ETL Process
    -- ==============================
    SET v_start_time = NOW();

    START TRANSACTION;

    INSERT INTO healthcare_star.etl_run_log (
        process_name,
        start_time,
        status
    )
    VALUES (
        '01_load_dimensions',
        v_start_time,
        'RUNNING'
    );

    -- =========================================================
    -- Load dim_date (Generated, not from OLTP)
    -- =========================================================
    INSERT INTO healthcare_star.dim_date (
        date_key,
        calendar_date,
        day,
        month,
        month_name,
        quarter,
        year,
        day_of_week
    )
    SELECT DISTINCT
        DATE_FORMAT(d, '%Y%m%d'),
        d,
        DAY(d),
        MONTH(d),
        MONTHNAME(d),
        QUARTER(d),
        YEAR(d),
        DAYNAME(d)
    FROM (
        SELECT DATE(encounter_date) AS d
        FROM healthcare_oltp.encounters
    ) dates;

    SET v_rows_affected = v_rows_affected + ROW_COUNT();

    -- =========================================================
    -- Load dim_patient
    -- =========================================================
    INSERT INTO healthcare_star.dim_patient (
        patient_id,
        mrn,
        first_name,
        last_name,
        gender,
        date_of_birth,
        age_group
    )
    SELECT
        p.patient_id,
        p.mrn,
        p.first_name,
        p.last_name,
        p.gender,
        p.date_of_birth,
        CASE
            WHEN TIMESTAMPDIFF(YEAR, p.date_of_birth, CURDATE()) < 18 THEN 'Child'
            WHEN TIMESTAMPDIFF(YEAR, p.date_of_birth, CURDATE()) BETWEEN 18 AND 64 THEN 'Adult'
            ELSE 'Senior'
        END
    FROM healthcare_oltp.patients p;

    SET v_rows_affected = v_rows_affected + ROW_COUNT();

    -- =========================================================
    -- Load dim_specialty
    -- =========================================================
    INSERT INTO healthcare_star.dim_specialty (
        specialty_id,
        specialty_name,
        specialty_code
    )
    SELECT
        s.specialty_id,
        s.specialty_name,
        s.specialty_code
    FROM healthcare_oltp.specialties s;

    SET v_rows_affected = v_rows_affected + ROW_COUNT();

    -- =========================================================
    -- Load dim_department
    -- =========================================================
    INSERT INTO healthcare_star.dim_department (
        department_id,
        department_name,
        floor,
        capacity
    )
    SELECT
        d.department_id,
        d.department_name,
        d.floor,
        d.capacity
    FROM healthcare_oltp.departments d;

    SET v_rows_affected = v_rows_affected + ROW_COUNT();

    -- =========================================================
    -- Load dim_provider
    -- =========================================================
    INSERT INTO healthcare_star.dim_provider (
        provider_id,
        first_name,
        last_name,
        credential,
        specialty_key,
        department_key
    )
    SELECT
        p.provider_id,
        p.first_name,
        p.last_name,
        p.credential,
        s.specialty_key,
        d.department_key
    FROM healthcare_oltp.providers p
    JOIN healthcare_star.dim_specialty s 
        ON p.specialty_id = s.specialty_id
    JOIN healthcare_star.dim_department d 
        ON p.department_id = d.department_id;

    SET v_rows_affected = v_rows_affected + ROW_COUNT();

    -- =========================================================
    -- Load dim_encounter_type
    -- =========================================================
    INSERT INTO healthcare_star.dim_encounter_type (encounter_type_name)
    SELECT DISTINCT encounter_type
    FROM healthcare_oltp.encounters;

    SET v_rows_affected = v_rows_affected + ROW_COUNT();

    -- =========================================================
    -- Load dim_diagnosis
    -- =========================================================
    INSERT INTO healthcare_star.dim_diagnosis (
        diagnosis_id,
        icd10_code,
        icd10_description
    )
    SELECT
        diagnosis_id,
        icd10_code,
        icd10_description
    FROM healthcare_oltp.diagnoses;

    SET v_rows_affected = v_rows_affected + ROW_COUNT();

    -- =========================================================
    -- Load dim_procedure
    -- =========================================================
    INSERT INTO healthcare_star.dim_procedure (
        procedure_id,
        cpt_code,
        cpt_description
    )
    SELECT
        procedure_id,
        cpt_code,
        cpt_description
    FROM healthcare_oltp.procedures;

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
        process_name = '01_load_dimensions'
        AND start_time = v_start_time
    LIMIT 1;

END$$

DELIMITER ;


CALL healthcare_star.sp_load_dimensions();

