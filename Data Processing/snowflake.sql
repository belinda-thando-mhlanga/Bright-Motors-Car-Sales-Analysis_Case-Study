-- EXPLORATORY ANALYSIS: Understanding the Bright Motors Data
===============================================================================================
SELECT * FROM BRIGHT_MOTORS.CASESTUDY.CARSALES LIMIT 100;

-- Query 1: Check total number of records and basic data quality
SELECT 
    COUNT(*) AS total_records,
    COUNT(DISTINCT vin) AS unique_vins,
    COUNT(DISTINCT make) AS unique_makes,
    COUNT(DISTINCT state) AS unique_states,
    MIN(saledate) AS earliest_sale_text,
    MAX(saledate) AS latest_sale_text
FROM BRIGHT_MOTORS.CASESTUDY.CARSALES;

-- Query 2: Check for missing values in key columns
SELECT 
    COUNT(*) AS total_rows,
    COUNT(sellingprice) AS has_selling_price,
    COUNT(odometer) AS has_odometer,
    COUNT(condition) AS has_condition,
    COUNT(mmr) AS has_mmr,
    COUNT(*) - COUNT(sellingprice) AS missing_price,
    COUNT(*) - COUNT(odometer) AS missing_odometer
FROM BRIGHT_MOTORS.CASESTUDY.CARSALES;

-- Query 3: Top 10 car makes by sales volume
SELECT 
    make,
    COUNT(*) AS total_sales,
    AVG(sellingprice) AS avg_price,
    MIN(sellingprice) AS min_price,
    MAX(sellingprice) AS max_price
FROM BRIGHT_MOTORS.CASESTUDY.CARSALES
GROUP BY make
ORDER BY total_sales DESC
LIMIT 10;

-- Query 4: Sales by state (regional performance)
SELECT 
    state,
    COUNT(*) AS total_sales,
    AVG(sellingprice) AS avg_selling_price,
    SUM(sellingprice) AS total_revenue
FROM BRIGHT_MOTORS.CASESTUDY.CARSALES
GROUP BY state
ORDER BY total_revenue DESC;

-- Query 5: Price range distribution
SELECT 
    CASE 
        WHEN sellingprice BETWEEN 0 AND 9999 THEN 'Under 10K'
        WHEN sellingprice BETWEEN 10000 AND 19999 THEN '10K-20K'
        WHEN sellingprice BETWEEN 20000 AND 29999 THEN '20K-30K'
        WHEN sellingprice BETWEEN 30000 AND 39999 THEN '30K-40K'
        WHEN sellingprice >= 40000 THEN 'Over 40K'
    END AS selling_price_bucket,
    COUNT(*) AS car_count,
    AVG(odometer) AS avg_mileage,
    AVG(sellingprice) AS avg_price,
    MIN(sellingprice) AS min_price,
    MAX(sellingprice) AS max_price
FROM BRIGHT_MOTORS.CASESTUDY.CARSALES
WHERE sellingprice IS NOT NULL
GROUP BY selling_price_bucket
ORDER BY MIN(sellingprice);

-- Query 6: Top vehicle body types
SELECT 
    body,
    COUNT(*) AS total_sales,
    AVG(sellingprice) AS avg_price
FROM BRIGHT_MOTORS.CASESTUDY.CARSALES
WHERE body IS NOT NULL
GROUP BY body
ORDER BY total_sales DESC;

-- Query 7: Top 10 models overall
SELECT 
    make,
    model,
    COUNT(*) AS units_sold,
    AVG(sellingprice) AS avg_price,
    SUM(sellingprice) AS total_revenue
FROM BRIGHT_MOTORS.CASESTUDY.CARSALES
GROUP BY make, model
ORDER BY total_revenue DESC
LIMIT 10;

-- Query 8: Check data distribution by year
SELECT 
    "YEAR",
    COUNT(*) AS car_count,
    AVG(sellingprice) AS avg_price,
    AVG(odometer) AS avg_mileage
FROM BRIGHT_MOTORS.CASESTUDY.CARSALES
WHERE "YEAR" IS NOT NULL
GROUP BY "YEAR"
ORDER BY "YEAR" DESC;


===============================BIGQUERY=====================================================================

WITH Date_CTE AS (
    SELECT
        *,
        TRY_TO_TIMESTAMP(
            SUBSTR(saledate, 1, 24),
            'DY MON DD YYYY HH24:MI:SS'
        ) AS sale_ts,
       FROM BRIGHT_MOTORS.CASESTUDY.CARSALES)

SELECT
    year,
    make,
    model,
    state,

    sellingprice,
    SUM(year) AS total_year_manufacture,
    AVG(sellingprice) AS avg_price,

    odometer AS mileage,

	 -- Categorize by mileage
        CASE 
            WHEN mileage < 50000 THEN 'Low Mileage (<50k)'
            WHEN mileage BETWEEN 50000 AND 100000 THEN 'Medium Mileage (50k-100k)'
            ELSE 'High Mileage (>100k)'
        END AS mileage_category,


    -- Categorize by price range
        CASE 
            WHEN SELLINGPRICE < 10000 THEN 'Budget (<10k)'
            WHEN SELLINGPRICE BETWEEN 10000 AND 25000 THEN 'Mid-Range (10k-25k)'
            WHEN SELLINGPRICE BETWEEN 25000 AND 50000 THEN 'Premium (25k-50k)'
            ELSE 'Luxury (>50k)'
        END AS selling_price_bucket,
 
    -- Time of day (HH24:MI:SS)
    TO_VARCHAR(sale_ts, 'HH24:MI:SS') AS time,

    -- Date Only
    TO_DATE(sale_ts) AS date,

    -- Formatted Year Name
    TO_CHAR(sale_ts, 'MON DD YYYY') AS year_name,

    -- Year Grouping
    CASE
        WHEN EXTRACT(YEAR FROM sale_ts) BETWEEN 2014 AND 2015 THEN '2014-2015 (Current)'
        WHEN EXTRACT(YEAR FROM sale_ts) BETWEEN 2012 AND 2013 THEN '2012-2013 (Recent)'
        WHEN EXTRACT(YEAR FROM sale_ts) BETWEEN 2010 AND 2011 THEN '2010-2011 (Mid-Age)'
        WHEN EXTRACT(YEAR FROM sale_ts) BETWEEN 2005 AND 2009 THEN '2005-2009 (Older)'
        WHEN YEAR <= 2004 THEN 'Pre-2005 (Vintage)'
END AS YEAR_CATEGORY,

    -- Day of Week (Mon, Tue, etc.)
    TO_CHAR(sale_ts, 'DY') AS day_of_week,

FROM Date_CTE
GROUP BY ALL;
