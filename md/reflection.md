
# Why Is the Star Schema Faster?

## Performance Difference
OLTP schema: Requires multiple joins across normalized tables  
Star schema: Joins fact table directly to small dimension tables

## Compare # of JOINs in normalized vs. star schema
- OLTP queries: 3–4 joins (often with self-joins)  
- Star schema queries: 1–3 joins (flat, predictable paths)

## Where is data pre-computed in the star schema?
- Date attributes (year, month, quarter) in dim_date  
- Revenue aggregated at encounter level in fact_encounters  
- Diagnosis and procedure counts pre-calculated per encounter

## Why does denormalization help analytical queries?
- Reduces join depth and join complexity  
- Avoids runtime calculations (e.g., YEAR(), MONTH())  
- Enables efficient grouping and aggregation  
- Uses surrogate integer keys for faster joins

# Trade-offs: What Did You Gain? What Did You Lose?

## What did you give up?
- Data duplication across dimensions  
- Increased ETL complexity  
- Need to maintain multiple schemas (OLTP + Star)

## What did you gain?
- Faster analytical queries  
- Simpler, more readable SQL  
- Pre-aggregated metrics  
- Scalable analytical design

## Was it worth it?
Yes — especially for analytical workloads. Performance gains increase as data volume grows. Improved clarity and maintainability outweigh ETL cost.

# Bridge Tables: Worth It?

## Why keep diagnoses/procedures in bridge tables instead of denormalizing into fact?
- Diagnoses and procedures are many-to-many with encounters  
- Bridge tables prevent data duplication  
- Enforce correct analytical grain

## What's the trade-off?
- Slightly more complex ETL logic  
- Additional tables to manage

## Would you do it differently in production?
No — bridge tables are standard for many-to-many relationships. Alternative would be separate fact tables, not denormalization.

# Performance Quantification

## Example 1: Monthly Encounters by Specialty
- Original execution time: OLTP execution time: ~0.47 seconds  
- Optimized execution time: Star schema execution time: ~0.02 milliseconds  
- Improvement: ~23,000× faster  
- Main reason for the speedup: Precomputed date attributes and reduced join complexity

## Example 2: Diagnosis–Procedure Pairs
- Original execution time: OLTP execution time: ~1.89 seconds  
- Optimized execution time: Star schema execution time: ~0.75 milliseconds  
- Improvement: ~2,500× faster  
- Main reason for the speedup: Pre-resolved many-to-many relationships using bridge tables



<!-- NOTE: -->
This project uses two separate databases: one for OLTP operations (healthcare_oltp) and one for analytical processing (healthcare_star). This separation mirrors real-world data architecture, where transactional systems are isolated from analytical workloads to avoid performance interference.”