
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
- Clear separation of transactional and analytical workloads

- Simpler and more readable analytical SQL

- Consistent aggregation grain

- Scalable query patterns suitable for BI and reporting tools

## Was it worth it?
Yes. Even when performance gains are modest at small scale, the star schema provides clarity, maintainability, and predictable scaling behavior. These benefits outweigh the added ETL complexity for analytical systems.

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
- Original execution time: OLTP execution time: ~0.37–0.49 seconds

- Star schema execution time: ~0.65–0.76 seconds

- Observed result: OLTP faster at small scale

- Explanation: Warm cache and small dataset favor OLTP, but star schema shows cleaner execution and better scalability


## Example 2: Diagnosis–Procedure Pairs
- Original execution time: OLTP execution time: ~2.8 seconds

- Star schema execution time: ~1.9 seconds

- Observed improvement: ~1.5× faster

- Main reason: Pre-modeled many-to-many relationships using bridge tables reduced join complexity


