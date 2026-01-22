/* =========================================================
   DATABASE: healthcare_oltp
   Purpose : Operational database for day-to-day hospital
             transactions (patients, encounters, billing)
   ========================================================= */

DROP DATABASE IF EXISTS healthcare_oltp;
CREATE DATABASE IF NOT EXISTS healthcare_oltp;


/* Stores core patient demographic information.
   Master entity referenced by encounters and billing. */
CREATE TABLE healthcare_oltp.patients (
  patient_id INT PRIMARY KEY,        /* Business identifier from source system */
  first_name VARCHAR(100),
  last_name VARCHAR(100),
  date_of_birth DATE,
  gender CHAR(1),
  mrn VARCHAR(20) UNIQUE              /* Medical Record Number */
);




/* Lookup table for medical specialties used by providers */
CREATE TABLE healthcare_oltp.specialties (
  specialty_id INT PRIMARY KEY,
  specialty_name VARCHAR(100),
  specialty_code VARCHAR(10)
);




/* Represents hospital departments where care is delivered */
CREATE TABLE healthcare_oltp.departments (
  department_id INT PRIMARY KEY,
  department_name VARCHAR(100),
  floor INT,
  capacity INT
);


/* Stores healthcare provider information.
   Providers are linked to specialty and department. */
CREATE TABLE healthcare_oltp.providers (
  provider_id INT PRIMARY KEY,
  first_name VARCHAR(100),
  last_name VARCHAR(100),
  credential VARCHAR(20),
  specialty_id INT,
  department_id INT,

  CONSTRAINT fk_provider_specialty
    FOREIGN KEY (specialty_id)
      REFERENCES specialties (specialty_id)
        ON DELETE RESTRICT
        ON UPDATE CASCADE /* Preserve specialty history */,

  CONSTRAINT fk_provider_department
    FOREIGN KEY (department_id)
      REFERENCES departments (department_id)
        ON DELETE RESTRICT
        ON UPDATE CASCADE /* Preserve department history */
);




/* Core clinical transaction table.
   One row per patient encounter.
   Protected for legal, audit, and clinical history. */
CREATE TABLE healthcare_oltp.encounters (
  encounter_id INT PRIMARY KEY,
  patient_id INT,
  provider_id INT,
  encounter_type VARCHAR(50),         /* Outpatient, Inpatient, ER */
  encounter_date DATETIME,
  discharge_date DATETIME,
  department_id INT,

  CONSTRAINT fk_encounter_patient
    FOREIGN KEY (patient_id)
      REFERENCES patients (patient_id)
        ON DELETE RESTRICT
        ON UPDATE CASCADE /* Prevent deleting patients with encounters */,

  CONSTRAINT fk_encounter_provider
    FOREIGN KEY (provider_id)
      REFERENCES providers (provider_id)
        ON DELETE RESTRICT
        ON UPDATE CASCADE /* Prevent deleting providers with encounters */,

  CONSTRAINT fk_encounter_department
    FOREIGN KEY (department_id)
      REFERENCES departments (department_id)
        ON DELETE RESTRICT
        ON UPDATE CASCADE /* Preserve department history */,

  INDEX idx_encounter_date (encounter_date) /* Optimize time-based queries */
);



/* Stores ICD-10 diagnosis reference data */
CREATE TABLE healthcare_oltp.diagnoses (
  diagnosis_id INT PRIMARY KEY,
  icd10_code VARCHAR(10),
  icd10_description VARCHAR(200)
);




/* Links encounters to diagnoses.
   Child table dependent on encounters. */
CREATE TABLE healthcare_oltp.encounter_diagnoses (
  encounter_diagnosis_id INT PRIMARY KEY,
  encounter_id INT,
  diagnosis_id INT,
  diagnosis_sequence INT,

  CONSTRAINT fk_ed_encounter
    FOREIGN KEY (encounter_id)
      REFERENCES encounters (encounter_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE /* Remove diagnoses when encounter is deleted */,

  CONSTRAINT fk_ed_diagnosis
    FOREIGN KEY (diagnosis_id)
      REFERENCES diagnoses (diagnosis_id)
        ON DELETE RESTRICT
        ON UPDATE CASCADE /* Protect diagnosis reference data */
);




/* Stores CPT procedure reference data */
CREATE TABLE healthcare_oltp.procedures (
  procedure_id INT PRIMARY KEY,
  cpt_code VARCHAR(10),
  cpt_description VARCHAR(200)
);



/* Links encounters to procedures performed */
CREATE TABLE healthcare_oltp.encounter_procedures (
  encounter_procedure_id INT PRIMARY KEY,
  encounter_id INT,
  procedure_id INT,
  procedure_date DATE,

  CONSTRAINT fk_ep_encounter
    FOREIGN KEY (encounter_id)
      REFERENCES encounters (encounter_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE /* Cascade with encounter deletion */,

  CONSTRAINT fk_ep_procedure
    FOREIGN KEY (procedure_id)
      REFERENCES procedures (procedure_id)
        ON DELETE RESTRICT
        ON UPDATE CASCADE /* Protect procedure reference data */
);



/* Stores financial and claims data per encounter */
CREATE TABLE healthcare_oltp.billing (
  billing_id INT PRIMARY KEY,
  encounter_id INT,
  claim_amount DECIMAL(12,2),
  allowed_amount DECIMAL(12,2),
  claim_date DATE,
  claim_status VARCHAR(50),

  CONSTRAINT fk_billing_encounter
    FOREIGN KEY (encounter_id)
      REFERENCES encounters (encounter_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE /* Remove billing when encounter is deleted */,

  INDEX idx_claim_date (claim_date) /* Support financial reporting */
);

