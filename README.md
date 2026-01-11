# Health Care Analytics — Amalitech

A compact project demonstrating OLTP design and a STAR-schema analytical layer for healthcare data, plus modular ETL SQL scripts to load dimensions, facts, and bridge tables.

**Contents**

- **OLTP:** transactional schema and sample data ([OLTP/OLTP_SQL/OLTP_schema.sql](OLTP/OLTP_SQL/OLTP_schema.sql), [OLTP/OLTP_SQL/OLTP_sample_data.sql](OLTP/OLTP_SQL/OLTP_sample_data.sql)).
- **STAR_SCHEMA:** analytical star schema, ETL scripts and example queries ([STAR_SCHEMA/STAR_SCHEMA_SQL/star_schema.sql](STAR_SCHEMA/STAR_SCHEMA_SQL/star_schema.sql), [STAR_SCHEMA/STAR_SCHEMA_SQL/ETL_sql](STAR_SCHEMA/STAR_SCHEMA_SQL/ETL_sql)).
- **Notes and design:** [md/reflection.md](md/reflection.md), [STAR_SCHEMA/design_decisions.txt](STAR_SCHEMA/design_decisions.txt), [STAR_SCHEMA/etl_design.txt](STAR_SCHEMA/etl_design.txt)

**Databases Used**

This project uses two separate databases: one for OLTP operations (`healthcare_oltp`) and one for analytical processing (`healthcare_star`). This separation mirrors real-world data architecture, where transactional systems are isolated from analytical workloads to avoid performance interference.

**ETL Orchestration**

The ETL pipeline is modularized into dimension, fact, and bridge load scripts. See the ETL SQL scripts under [STAR_SCHEMA/STAR_SCHEMA_SQL/ETL_sql](STAR_SCHEMA/STAR_SCHEMA_SQL/ETL_sql).

Recommended order to run the ETL scripts:

- [STAR_SCHEMA/STAR_SCHEMA_SQL/ETL_sql/01_load_dimensions.sql](STAR_SCHEMA/STAR_SCHEMA_SQL/ETL_sql/01_load_dimensions.sql) — load dimension tables first.
- [STAR_SCHEMA/STAR_SCHEMA_SQL/ETL_sql/02_load_fact_encounters.sql](STAR_SCHEMA/STAR_SCHEMA_SQL/ETL_sql/02_load_fact_encounters.sql) — load fact table(s).
- [STAR_SCHEMA/STAR_SCHEMA_SQL/ETL_sql/03_load_bridge_tables.sql](STAR_SCHEMA/STAR_SCHEMA_SQL/ETL_sql/03_load_bridge_tables.sql) — load bridge/auxiliary tables.

**Project Structure (high level)**

- **OLTP/** — OLTP schema, sample data and transactional SQL used to model operational data.
- **STAR_SCHEMA/** — STAR schema DDL, ETL scripts, and analytical queries.
- **md/** — notes and reflections about design decisions and analysis.

**How to use**

- Create two databases: `healthcare_oltp` and `healthcare_star` in your RDBMS of choice (Postgres, MySQL, etc.).
- Run the OLTP schema and sample data in `healthcare_oltp` using files in [OLTP/OLTP_SQL](OLTP/OLTP_SQL).
- Apply the STAR-schema DDL in `healthcare_star` using [STAR_SCHEMA/STAR_SCHEMA_SQL/star_schema.sql](STAR_SCHEMA/STAR_SCHEMA_SQL/star_schema.sql).
- Execute the ETL scripts in the order shown above to populate the analytical schema from transactional extracts (ETL scripts assume you have extracted staging data or can adapt queries to source tables).

**Notes & Next steps**

- The ETL scripts are plain SQL for clarity; you can wrap them with an orchestration tool (Airflow, dbt, or cron) for scheduling and dependency management.
- Review design rationale in [md/reflection.md](md/reflection.md) and [STAR_SCHEMA/design_decisions.txt](STAR_SCHEMA/design_decisions.txt) before adapting to a production environment.
