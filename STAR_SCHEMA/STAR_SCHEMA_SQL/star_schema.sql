/* =========================================================
   DATABASE: healthcare_star
   PURPOSE : Analytical (OLAP) database designed using a
             STAR SCHEMA for reporting and business intelligence.
             This schema is populated via ETL from healthcare_oltp
             and is treated as READ-ONLY for end users.
   ========================================================= */


DROP DATABASE IF EXISTS healthcare_star;
CREATE DATABASE IF NOT EXISTS healthcare_star;


/* Stores ETL execution metadata for monitoring and auditing */
CREATE TABLE healthcare_star.etl_run_log (
    etl_run_id INT AUTO_INCREMENT PRIMARY KEY,
    process_name VARCHAR(100),
    start_time DATETIME,
    end_time DATETIME,
    status VARCHAR(20),
    rows_affected INT,
    error_message TEXT
);



/* Calendar dimension for all time-based analytics */
CREATE TABLE healthcare_star.dim_date (
    date_key INT PRIMARY KEY,        /* Surrogate date key (YYYYMMDD) */
    calendar_date DATE NOT NULL,
    day INT,
    month INT,
    month_name VARCHAR(20),
    quarter INT,
    year INT,
    day_of_week VARCHAR(20)
);




/* Patient descriptive attributes for demographic analysis */
CREATE TABLE healthcare_star.dim_patient (
    patient_key INT AUTO_INCREMENT PRIMARY KEY,
    patient_id INT,                 /* Business key from OLTP */
    mrn VARCHAR(20),
    first_name VARCHAR(100),
    last_name VARCHAR(100),
    gender CHAR(1),
    date_of_birth DATE,
    age_group VARCHAR(20)
);





/* Medical specialty reference dimension */
CREATE TABLE healthcare_star.dim_specialty (
    specialty_key INT AUTO_INCREMENT PRIMARY KEY,
    specialty_id INT,
    specialty_name VARCHAR(100),
    specialty_code VARCHAR(10)
);




/* Hospital department reference dimension */
CREATE TABLE healthcare_star.dim_department (
    department_key INT AUTO_INCREMENT PRIMARY KEY,
    department_id INT,
    department_name VARCHAR(100),
    floor INT,
    capacity INT
);




/* Healthcare provider dimension linked to specialty and department */
CREATE TABLE healthcare_star.dim_provider (
    provider_key INT AUTO_INCREMENT PRIMARY KEY,
    provider_id INT,
    first_name VARCHAR(100),
    last_name VARCHAR(100),
    credential VARCHAR(20),
    specialty_key INT,
    department_key INT,

    CONSTRAINT fk_dim_provider_specialty
      FOREIGN KEY (specialty_key)
        REFERENCES healthcare_star.dim_specialty(specialty_key)
        ON DELETE RESTRICT
        ON UPDATE CASCADE /* Preserve specialty history */,

    CONSTRAINT fk_dim_provider_department
      FOREIGN KEY (department_key)
        REFERENCES healthcare_star.dim_department(department_key)
        ON DELETE RESTRICT
        ON UPDATE CASCADE /* Preserve department history */
);




/* Standardized encounter type dimension */
CREATE TABLE healthcare_star.dim_encounter_type (
    encounter_type_key INT AUTO_INCREMENT PRIMARY KEY,
    encounter_type_name VARCHAR(50)
);




/* ICD-10 diagnosis reference dimension */
CREATE TABLE healthcare_star.dim_diagnosis (
    diagnosis_key INT AUTO_INCREMENT PRIMARY KEY,
    diagnosis_id INT,
    icd10_code VARCHAR(10),
    icd10_description VARCHAR(200)
);




/* CPT procedure reference dimension */
CREATE TABLE healthcare_star.dim_procedure (
    procedure_key INT AUTO_INCREMENT PRIMARY KEY,
    procedure_id INT,
    cpt_code VARCHAR(10),
    cpt_description VARCHAR(200)
);




/* Central fact table: one row per encounter */
CREATE TABLE healthcare_star.fact_encounters (
    encounter_key INT AUTO_INCREMENT PRIMARY KEY,
    date_key INT NOT NULL,
    patient_key INT NOT NULL,
    provider_key INT NOT NULL,
    specialty_key INT NOT NULL,
    department_key INT NOT NULL,
    encounter_type_key INT NOT NULL,
    encounter_count INT NOT NULL DEFAULT 1,
    diagnosis_count INT,
    procedure_count INT,
    total_allowed_amount DECIMAL(12,2),
    length_of_stay INT,
    encounter_id INT,               /* Degenerate dimension */

    CONSTRAINT fk_fact_date
      FOREIGN KEY (date_key)
        REFERENCES healthcare_star.dim_date(date_key)
        ON DELETE RESTRICT
        ON UPDATE CASCADE /* Protect fact history */,

    CONSTRAINT fk_fact_patient
      FOREIGN KEY (patient_key)
        REFERENCES healthcare_star.dim_patient(patient_key)
        ON DELETE RESTRICT
        ON UPDATE CASCADE,

    CONSTRAINT fk_fact_provider
      FOREIGN KEY (provider_key)
        REFERENCES healthcare_star.dim_provider(provider_key)
        ON DELETE RESTRICT
        ON UPDATE CASCADE,

    CONSTRAINT fk_fact_specialty
      FOREIGN KEY (specialty_key)
        REFERENCES healthcare_star.dim_specialty(specialty_key)
        ON DELETE RESTRICT
        ON UPDATE CASCADE,

    CONSTRAINT fk_fact_department
      FOREIGN KEY (department_key)
        REFERENCES healthcare_star.dim_department(department_key)
        ON DELETE RESTRICT
        ON UPDATE CASCADE,

    CONSTRAINT fk_fact_encounter_type
      FOREIGN KEY (encounter_type_key)
        REFERENCES healthcare_star.dim_encounter_type(encounter_type_key)
        ON DELETE RESTRICT
        ON UPDATE CASCADE,

    INDEX idx_date_key (date_key),
    INDEX idx_patient_key (patient_key),
    INDEX idx_provider_key (provider_key),
    INDEX idx_specialty_key (specialty_key),
    INDEX idx_department_key (department_key),
    INDEX idx_encounter_type_key (encounter_type_key)
);





/* Resolves many-to-many relationship between encounters and diagnoses */
CREATE TABLE healthcare_star.bridge_encounter_diagnoses (
    encounter_key INT NOT NULL,
    diagnosis_key INT NOT NULL,
    diagnosis_sequence INT,
    PRIMARY KEY (encounter_key, diagnosis_key, diagnosis_sequence),

    CONSTRAINT fk_bed_fact
      FOREIGN KEY (encounter_key)
        REFERENCES healthcare_star.fact_encounters(encounter_key)
        ON DELETE CASCADE
        ON UPDATE CASCADE /* Remove bridge rows with fact */,

    CONSTRAINT fk_bed_diagnosis
      FOREIGN KEY (diagnosis_key)
        REFERENCES healthcare_star.dim_diagnosis(diagnosis_key)
        ON DELETE RESTRICT
        ON UPDATE CASCADE /* Preserve diagnosis history */
);




/* Resolves many-to-many relationship between encounters and procedures */
CREATE TABLE healthcare_star.bridge_encounter_procedures (
    encounter_key INT NOT NULL,
    procedure_key INT NOT NULL,
    procedure_date DATE,
    PRIMARY KEY (encounter_key, procedure_key),

    CONSTRAINT fk_bep_fact
      FOREIGN KEY (encounter_key)
        REFERENCES healthcare_star.fact_encounters(encounter_key)
        ON DELETE CASCADE
        ON UPDATE CASCADE /* Cascade with fact */,

    CONSTRAINT fk_bep_procedure
      FOREIGN KEY (procedure_key)
        REFERENCES healthcare_star.dim_procedure(procedure_key)
        ON DELETE RESTRICT /* Protect procedure dimension */
);



/* =========================================================
   END OF STAR SCHEMA DEFINITION
   ========================================================= */
