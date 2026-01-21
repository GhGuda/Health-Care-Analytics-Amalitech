-- Active: 1768089040947@@127.0.0.1@3306@healthcare_oltp

  
INSERT INTO healthcare_oltp.patients VALUES 
(1001, 'John', 'Doe','1955-03-15', 'M', 'MRN001'),
(1002, 'Jane', 'Smith', '1962-07-22', 'F', 'MRN002'), 
(1003, 'Robert', 'Johnson', '1948-11-08', 'M', 'MRN003');

-- Insert ~5,000 patients using a stored procedure
DELIMITER $$
CREATE PROCEDURE load_patients_5k()
BEGIN
    DECLARE i INT DEFAULT 1;
    DECLARE next_patient_id INT;
    DECLARE batch_counter INT DEFAULT 0;
    DECLARE batch_size INT DEFAULT 1000;


    SELECT IFNULL(MAX(patient_id), 1000)
    INTO next_patient_id
    FROM patients;

    WHILE i <= 4997 DO
        SET next_patient_id = next_patient_id + 1;

        INSERT INTO healthcare_oltp.patients (
            patient_id,
            first_name,
            last_name,
            date_of_birth,
            gender,
            mrn
        )
        VALUES (
            next_patient_id,
            CONCAT('First', next_patient_id),
            CONCAT('Last', next_patient_id),
            DATE_SUB(CURDATE(), INTERVAL (20 + next_patient_id % 60) YEAR),
            IF(next_patient_id % 2 = 0, 'M', 'F'),
            CONCAT('MRN', next_patient_id)
        );

        SET i = i + 1;
        SET batch_counter = batch_counter + 1;
        -- BATCH COMMIT
        IF batch_counter = batch_size THEN
            COMMIT;
            START TRANSACTION;
            SET batch_counter = 0;
        END IF;
    END WHILE;
    -- commit remaining rows
    COMMIT;
END$$

DELIMITER ;

CALL load_patients_5k();


INSERT INTO healthcare_oltp.specialties VALUES 
(1, 'Cardiology', 'CARD'), 
(2, 'Internal Medicine', 'IM'), 
(3, 'Emergency', 'ER');


INSERT INTO healthcare_oltp.departments VALUES 
(1, 'Cardiology Unit', 3, 20), 
(2, 'Internal Medicine', 2, 30), 
(3, 'Emergency', 1, 45);

INSERT INTO healthcare_oltp.providers VALUES 
(101, 'James', 'Chen', 'MD', 1, 1), 
(102, 'Sarah', 'Williams', 'MD', 2, 2), 
(103, 'Michael', 'Rodriguez', 'MD', 3, 3);


INSERT INTO healthcare_oltp.encounters VALUES
(7001, 1001, 101, 'Outpatient', '2024-05-10 10:00:00', '2024-05-10 11:30:00', 1),
(7002, 1001, 101, 'Inpatient', '2024-06-02 14:00:00', '2024-06-06 09:00:00', 1),
(7003, 1002, 102, 'Outpatient', '2024-05-15 09:00:00', '2024-05-15 10:15:00', 2),
(7004, 1003, 103, 'ER', '2024-06-12 23:45:00', '2024-06-13 06:30:00', 3);

-- Insert ~100,000 encounters using a stored procedure
DELIMITER $$
CREATE PROCEDURE load_encounters_100k()
BEGIN
    DECLARE i INT DEFAULT 5;
    DECLARE next_encounter_id INT;
    DECLARE batch_counter INT DEFAULT 0;
    DECLARE batch_size INT DEFAULT 1000;

    -- get the current max encounter_id
    SELECT MAX(encounter_id) INTO next_encounter_id FROM encounters;

    IF next_encounter_id IS NULL THEN
        SET next_encounter_id = 7000;
    END IF;


    START TRANSACTION;
    WHILE i <= 100000 DO
        INSERT INTO healthcare_oltp.encounters (
            encounter_id,
            patient_id,
            provider_id,
            encounter_type,
            encounter_date,
            discharge_date,
            department_id
        )
        VALUES (
            next_encounter_id + 1,

            FLOOR(
                (SELECT MIN(patient_id) FROM patients) +
                RAND() * (
                    (SELECT MAX(patient_id) FROM patients) -
                    (SELECT MIN(patient_id) FROM patients) + 1
                )
            ),

            FLOOR(101 + RAND() * 3),

            ELT(FLOOR(1 + RAND() * 3), 'Outpatient', 'Inpatient', 'ER'),

            DATE_ADD('2024-01-01 08:00:00', INTERVAL FLOOR(RAND() * 180) DAY),

            DATE_ADD(
                DATE_ADD('2024-01-01 08:00:00', INTERVAL FLOOR(RAND() * 180) DAY),
                INTERVAL FLOOR(1 + RAND() * 5) DAY
            ),

            FLOOR(1 + RAND() * 3)
        );


        SET next_encounter_id = next_encounter_id + 1;
        SET i = i + 1;
        SET batch_counter = batch_counter + 1;

        -- BATCH COMMIT
        IF batch_counter = batch_size THEN
            COMMIT;
            START TRANSACTION;
            SET batch_counter = 0;
        END IF;

    END WHILE;
    -- commit remaining rows
    COMMIT;
END$$
DELIMITER ;

CALL load_encounters_100k();



INSERT INTO healthcare_oltp.diagnoses VALUES 
(3001, 'I10', 'Hypertension'), 
(3002, 'E11.9', 'Type 2 Diabetes'), 
(3003, 'I50.9', 'Heart Failure');

INSERT INTO healthcare_oltp.encounter_diagnoses VALUES
(8001, 7001, 3001, 1),
(8002, 7001, 3002, 2),
(8003, 7002, 3001, 1),
(8004, 7002, 3003, 2),
(8005, 7003, 3002, 1),
(8006, 7004, 3001, 1);


-- Insert ~2-3 per encounter diagnoses using a stored procedure
DELIMITER $$

CREATE PROCEDURE load_encounter_diagnoses()
BEGIN
    DECLARE done INT DEFAULT 0;
    DECLARE visit_counter_id INT;
    DECLARE v_diag_count INT;
    DECLARE i INT;
    DECLARE v_diagnosis_id INT;
    DECLARE v_enc_diag_id INT;
    DECLARE batch_counter INT DEFAULT 0;
    DECLARE batch_size INT DEFAULT 1000;

    -- Cursor to loop through encounters
    DECLARE cur_encounters CURSOR FOR
        SELECT encounter_id FROM encounters;

    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = 1;


    -- Get the current max encounter_diagnosis_id
    SELECT COALESCE(MAX(encounter_diagnosis_id), 0)
    INTO v_enc_diag_id
    FROM encounter_diagnoses;

    START TRANSACTION;
    OPEN cur_encounters;

    encounter_loop: LOOP
        FETCH cur_encounters INTO visit_counter_id;

        IF done = 1 THEN
            LEAVE encounter_loop;
        END IF;

        -- Decide whether this encounter gets 2 or 3 diagnoses
        SET v_diag_count = 2 + FLOOR(RAND() * 2);
        SET i = 1;

        diag_loop: WHILE i <= v_diag_count DO

            -- Pick a random existing diagnosis_id
            SELECT diagnosis_id
            INTO v_diagnosis_id
            FROM diagnoses
            ORDER BY RAND()
            LIMIT 1;

            -- Insert only if this sequence does not already exist
            IF NOT EXISTS (
                SELECT 1
                FROM encounter_diagnoses
                WHERE encounter_id = visit_counter_id
                  AND diagnosis_sequence = i
            ) THEN

                -- Manually increment the primary key
                SET v_enc_diag_id = v_enc_diag_id + 1;

                INSERT INTO healthcare_oltp.encounter_diagnoses (
                    encounter_diagnosis_id,
                    encounter_id,
                    diagnosis_id,
                    diagnosis_sequence
                )
                VALUES (
                    v_enc_diag_id,
                    visit_counter_id,
                    v_diagnosis_id,
                    i
                );
            END IF;

            SET i = i + 1;
            SET batch_counter = batch_counter + 1;

            -- BATCH COMMIT
            IF batch_counter = batch_size THEN
                COMMIT;
                START TRANSACTION;
                SET batch_counter = 0;
            END IF;
        END WHILE;

    END LOOP;

    CLOSE cur_encounters;
    -- commit remaining rows
    COMMIT;
END$$
DELIMITER ;

CALL load_encounter_diagnoses();



INSERT INTO healthcare_oltp.procedures VALUES 
(4001, '99213', 'Office Visit'), 
(4002, '93000', 'EKG'), 
(4003, '71020', 'Chest X-ray');


INSERT INTO healthcare_oltp.encounter_procedures VALUES
(9001, 7001, 4001, '2024-05-10'),
(9002, 7001, 4002, '2024-05-10'),
(9003, 7002, 4001, '2024-06-02'),
(9004, 7003, 4001, '2024-05-15');

-- Insert ~1-2 per encounter procedures using a stored procedure
DELIMITER $$

CREATE PROCEDURE load_encounter_procedures()
BEGIN
    -- Variables
    DECLARE done INT DEFAULT 0;
    DECLARE v_encounter_id INT;
    DECLARE v_proc_count INT;
    DECLARE i INT;
    DECLARE v_procedure_id INT;
    DECLARE v_enc_proc_id INT;
    DECLARE batch_counter INT DEFAULT 0;
    DECLARE batch_size INT DEFAULT 1000;
    -- Cursor
    DECLARE cur_encounters CURSOR FOR
        SELECT encounter_id FROM encounters;
    -- Handler
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = 1;

    -- Get current max encounter_procedure_id
    SELECT COALESCE(MAX(encounter_procedure_id), 0)
    INTO v_enc_proc_id
    FROM encounter_procedures;


    START TRANSACTION;
    OPEN cur_encounters;

    encounter_loop: LOOP
        FETCH cur_encounters INTO v_encounter_id;

        IF done = 1 THEN
            LEAVE encounter_loop;
        END IF;

        -- Decide whether this encounter gets 1 or 2 procedures
        SET v_proc_count = 1 + FLOOR(RAND() * 2);
        SET i = 1;

        proc_loop: WHILE i <= v_proc_count DO

            -- Pick a random existing procedure_id
            SELECT procedure_id
            INTO v_procedure_id
            FROM procedures
            ORDER BY RAND()
            LIMIT 1;

            -- Insert only if this procedure slot does not exist
            IF NOT EXISTS (
                SELECT 1
                FROM encounter_procedures
                WHERE encounter_id = v_encounter_id
                  AND procedure_id = v_procedure_id
            ) THEN
                SET v_enc_proc_id = v_enc_proc_id + 1;

                INSERT INTO healthcare_oltp.encounter_procedures (
                    encounter_procedure_id,
                    encounter_id,
                    procedure_id,
                    procedure_date
                )
                VALUES (
                    v_enc_proc_id,
                    v_encounter_id,
                    v_procedure_id,
                    DATE_ADD('2024-01-01', INTERVAL FLOOR(RAND() * 180) DAY)
                );
            END IF;

            SET i = i + 1;

            SET batch_counter = batch_counter + 1;

            -- BATCH COMMIT
            IF batch_counter = batch_size THEN
                COMMIT;
                START TRANSACTION;
                SET batch_counter = 0;
            END IF;
        END WHILE;

    END LOOP;

    CLOSE cur_encounters;
    -- commit remaining rows
    COMMIT;
END$$

DELIMITER ;

CALL load_encounter_procedures();



INSERT INTO healthcare_oltp.billing VALUES 
(14001, 7001, 350, 280, '2024-05-11', 'Paid'), 
(14002, 7002, 12500, 10000, '2024-06-08', 'Paid');

-- Insert ~1 billing per encounter using a stored procedure
DELIMITER $$

CREATE PROCEDURE load_billing_per_encounter()
BEGIN
    DECLARE done INT DEFAULT 0;
    DECLARE v_encounter_id INT;
    DECLARE v_billing_id INT;
    DECLARE batch_counter INT DEFAULT 0;
    DECLARE batch_size INT DEFAULT 1000;

    DECLARE cur_encounters CURSOR FOR
        SELECT encounter_id FROM encounters;

    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = 1;

    -- Get current max billing_id
    SELECT COALESCE(MAX(billing_id), 14000)
    INTO v_billing_id
    FROM billing;

    START TRANSACTION;
    OPEN cur_encounters;

    read_loop: LOOP
        FETCH cur_encounters INTO v_encounter_id;

        IF done = 1 THEN
            LEAVE read_loop;
        END IF;

        -- Insert only if billing does not exist
        IF NOT EXISTS (
            SELECT 1 FROM billing WHERE encounter_id = v_encounter_id
        ) THEN
            SET v_billing_id = v_billing_id + 1;

            INSERT INTO healthcare_oltp.billing (
                billing_id,
                encounter_id,
                claim_amount,
                allowed_amount,
                claim_date,
                claim_status
            )
            VALUES (
                v_billing_id,
                v_encounter_id,
                500 + FLOOR(RAND() * 5000),
                300 + FLOOR(RAND() * 3000),
                DATE_ADD('2024-01-01', INTERVAL FLOOR(RAND() * 180) DAY),
                'Paid'
            );
        END IF;

        SET batch_counter = batch_counter + 1;

        -- BATCH COMMIT
        IF batch_counter = batch_size THEN
            COMMIT;
            START TRANSACTION;
            SET batch_counter = 0;
        END IF;

    END LOOP;

    CLOSE cur_encounters;

    -- commit remaining rows
    COMMIT;
END$$

DELIMITER ;

CALL load_billing_per_encounter();
