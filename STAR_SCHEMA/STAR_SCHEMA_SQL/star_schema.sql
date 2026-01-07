/* =========================================================
   DIMENSION TABLES
   ========================================================= */

/* ---------------------------------------------------------
   dim_date
   Purpose: Provides calendar attributes for time-based analysis
   --------------------------------------------------------- */
   
-- 1. Date Dimension
CREATE TABLE dim_date (
    date_key INT PRIMARY KEY,
    calendar_date DATE NOT NULL,
    day INT,
    month INT,
    month_name VARCHAR(20),
    quarter INT,
    year INT,
    day_of_week VARCHAR(20)
);


/* ---------------------------------------------------------
   dim_patient
   Purpose: Stores descriptive patient attributes
   --------------------------------------------------------- */

-- 2. Patient Dimension
CREATE TABLE dim_patient (
    patient_key INT AUTO_INCREMENT PRIMARY KEY,
    patient_id INT,
    mrn VARCHAR(20),
    first_name VARCHAR(100),
    last_name VARCHAR(100),
    gender CHAR(1),
    date_of_birth DATE,
    age_group VARCHAR(20)
);


/* ---------------------------------------------------------
   dim_specialty
   Purpose: Stores medical specialty information
   --------------------------------------------------------- */

-- 3. Speciality Dimension
CREATE TABLE dim_specialty (
    specialty_key INT AUTO_INCREMENT PRIMARY KEY,
    specialty_id INT,
    specialty_name VARCHAR(100),
    specialty_code VARCHAR(10)
);


/* ---------------------------------------------------------
   dim_department
   Purpose: Describes hospital departments where care occurs
   --------------------------------------------------------- */

-- 4. Department Dimension
CREATE TABLE dim_department (
    department_key INT AUTO_INCREMENT PRIMARY KEY,
    department_id INT,
    department_name VARCHAR(100),
    floor INT,
    capacity INT
);


/* ---------------------------------------------------------
   dim_provider
   Purpose: Stores healthcare provider details
   --------------------------------------------------------- */

-- 5. Providers Dimension
CREATE TABLE dim_provider (
    provider_key INT AUTO_INCREMENT PRIMARY KEY,
    provider_id INT,
    first_name VARCHAR(100),
    last_name VARCHAR(100),
    credential VARCHAR(20),
    specialty_key INT,
    department_key INT,
    FOREIGN KEY (specialty_key) REFERENCES dim_specialty(specialty_key),
    FOREIGN KEY (department_key) REFERENCES dim_department(department_key)
);


/* ---------------------------------------------------------
   dim_encounter_type
   Purpose: Standardizes encounter types (ER, Inpatient, Outpatient)
   --------------------------------------------------------- */

-- 6. Encounter Type Dimension
CREATE TABLE dim_encounter_type (
    encounter_type_key INT AUTO_INCREMENT PRIMARY KEY,
    encounter_type_name VARCHAR(50)
);


/* ---------------------------------------------------------
   dim_diagnosis
   Purpose: Stores diagnosis codes and descriptions
   --------------------------------------------------------- */

-- 7. Diagnosis Dimension
CREATE TABLE dim_diagnosis (
    diagnosis_key INT AUTO_INCREMENT PRIMARY KEY,
    diagnosis_id INT,
    icd10_code VARCHAR(10),
    icd10_description VARCHAR(200)
);

/* ---------------------------------------------------------
   dim_procedure
   Purpose: Stores procedure codes and descriptions
   --------------------------------------------------------- */

-- 8. Procedure Dimension
CREATE TABLE dim_procedure (
    procedure_key INT AUTO_INCREMENT PRIMARY KEY,
    procedure_id INT,
    cpt_code VARCHAR(10),
    cpt_description VARCHAR(200)
);




/* =========================================================
   FACT TABLE
   ========================================================= */

/* ---------------------------------------------------------
   fact_encounters
   Purpose: Central fact table with one row per encounter
   --------------------------------------------------------- */

-- DDL: Fact Table
CREATE TABLE fact_encounters (
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
    encounter_id INT,
    FOREIGN KEY (date_key) REFERENCES dim_date(date_key),
    FOREIGN KEY (patient_key) REFERENCES dim_patient(patient_key),
    FOREIGN KEY (provider_key) REFERENCES dim_provider(provider_key),
    FOREIGN KEY (specialty_key) REFERENCES dim_specialty(specialty_key),
    FOREIGN KEY (department_key) REFERENCES dim_department(department_key),
    FOREIGN KEY (encounter_type_key) REFERENCES dim_encounter_type(encounter_type_key),
    INDEX idx_date_key (date_key),
    INDEX idx_patient_key (patient_key),
    INDEX idx_provider_key (provider_key),
    INDEX idx_specialty_key (specialty_key),
    INDEX idx_department_key (department_key),
    INDEX idx_encounter_type_key (encounter_type_key)
);



/* =========================================================
   BRIDGE TABLES (MANY-TO-MANY RELATIONSHIPS)
   ========================================================= */

/* ---------------------------------------------------------
   bridge_encounter_diagnoses
   Purpose: Resolves many-to-many relationship between
            encounters and diagnoses
   --------------------------------------------------------- */

-- DDL: bridge_encounter_diagnoses
CREATE TABLE bridge_encounter_diagnoses (
    encounter_key INT NOT NULL,
    diagnosis_key INT NOT NULL,
    diagnosis_sequence INT,
    PRIMARY KEY (encounter_key, diagnosis_key),
    FOREIGN KEY (encounter_key) REFERENCES fact_encounters(encounter_key),
    FOREIGN KEY (diagnosis_key) REFERENCES dim_diagnosis(diagnosis_key),
    INDEX idx_bed_encounter (encounter_key),
    INDEX idx_bed_diagnosis (diagnosis_key)
);


/* ---------------------------------------------------------
   bridge_encounter_procedures
   Purpose: Resolves many-to-many relationship between
            encounters and procedures
   --------------------------------------------------------- */
-- DDL: bridge_encounter_procedures
CREATE TABLE bridge_encounter_procedures (
    encounter_key INT NOT NULL,
    procedure_key INT NOT NULL,
    procedure_date DATE,
    PRIMARY KEY (encounter_key, procedure_key),
    FOREIGN KEY (encounter_key) REFERENCES fact_encounters(encounter_key),
    FOREIGN KEY (procedure_key) REFERENCES dim_procedure(procedure_key),
    INDEX idx_bep_encounter (encounter_key),
    INDEX idx_bep_procedure (procedure_key)
);
