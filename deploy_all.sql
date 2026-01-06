-- ============================================================================
-- DEMO: End-to-End ML Pipeline
-- Author: SE Community
-- Expires: 2026-02-05
-- ============================================================================
-- COPY THIS ENTIRE SCRIPT INTO SNOWSIGHT AND CLICK "RUN ALL"
-- ============================================================================

USE ROLE SYSADMIN;

-- Shared demo database and schema
CREATE DATABASE IF NOT EXISTS SNOWFLAKE_EXAMPLE;
CREATE SCHEMA IF NOT EXISTS SNOWFLAKE_EXAMPLE.E2E_MLOPS
    COMMENT = 'DEMO: End-to-End ML Pipeline | Expires: 2026-02-05';

-- Warehouse (SFE_ prefix) - Create first to enable expiration check
CREATE WAREHOUSE IF NOT EXISTS SFE_E2E_MLOPS_WH
    WAREHOUSE_SIZE = 'MEDIUM'
    AUTO_SUSPEND = 60
    AUTO_RESUME = TRUE
    INITIALLY_SUSPENDED = TRUE
    COMMENT = 'DEMO: E2E ML Pipeline | Expires: 2026-02-05';

USE WAREHOUSE SFE_E2E_MLOPS_WH;

-- ============================================================================
-- EXPIRATION CHECK
-- ============================================================================
-- This demo expires 30 days after creation.
-- If expired, deployment should be halted and the repository forked with updated dates.
-- Expiration date: 2026-02-05

SELECT
    '2026-02-05'::DATE AS expiration_date,
    CURRENT_DATE() AS current_date,
    DATEDIFF('day', CURRENT_DATE(), '2026-02-05'::DATE) AS days_remaining,
    CASE
        WHEN DATEDIFF('day', CURRENT_DATE(), '2026-02-05'::DATE) < 0
        THEN 'EXPIRED - Do not deploy. Fork repository and update expiration date.'
        WHEN DATEDIFF('day', CURRENT_DATE(), '2026-02-05'::DATE) <= 7
        THEN 'EXPIRING_SOON - ' || DATEDIFF('day', CURRENT_DATE(), '2026-02-05'::DATE) || ' days remaining'
        ELSE 'ACTIVE - ' || DATEDIFF('day', CURRENT_DATE(), '2026-02-05'::DATE) || ' days remaining'
    END AS demo_status;

-- Hard stop if expired.
EXECUTE IMMEDIATE $$
DECLARE
  demo_expired EXCEPTION (-20001, 'DEMO EXPIRED: 2026-02-05. Do not deploy. Fork repo and update expiration date.');
BEGIN
  IF (CURRENT_DATE() > TO_DATE('2026-02-05')) THEN
    RAISE demo_expired;
  END IF;
END;
$$;

-- ============================================================================
-- COMPUTE POOL (requires ACCOUNTADMIN)
-- ============================================================================
USE ROLE ACCOUNTADMIN;

CREATE COMPUTE POOL IF NOT EXISTS SFE_E2E_MLOPS_CP
    MIN_NODES = 1
    MAX_NODES = 1
    INSTANCE_FAMILY = CPU_X64_M
    AUTO_RESUME = TRUE
    INITIALLY_SUSPENDED = TRUE
    AUTO_SUSPEND_SECS = 300
    COMMENT = 'DEMO: E2E ML Pipeline | Expires: 2026-02-05';

GRANT USAGE, MONITOR ON COMPUTE POOL SFE_E2E_MLOPS_CP TO ROLE SYSADMIN;

USE ROLE SYSADMIN;
USE SCHEMA SNOWFLAKE_EXAMPLE.E2E_MLOPS;

-- ============================================================================
-- SYNTHETIC DATA GENERATION (replaces CSV file)
-- ============================================================================
CREATE OR REPLACE TABLE MORTGAGE_LENDING_DEMO_DATA AS
WITH
    loan_types AS (
        SELECT ARRAY_CONSTRUCT(
            'Conventional', 'FHA-insured', 'FSA/RHS-guaranteed', 'VA-guaranteed'
        ) AS arr
    ),
    loan_purposes AS (
        SELECT ARRAY_CONSTRUCT(
            'Home improvement', 'Home purchase', 'Refinancing'
        ) AS arr
    ),
    counties AS (
        SELECT ARRAY_CONSTRUCT(
            'Los Angeles County', 'Cook County', 'Harris County', 'Maricopa County',
            'San Diego County', 'Orange County', 'Miami-Dade County', 'Dallas County',
            'Kings County', 'Riverside County', 'Clark County', 'Queens County',
            'San Bernardino County', 'King County', 'Tarrant County', 'Santa Clara County',
            'Broward County', 'Wayne County', 'Bexar County', 'Alameda County',
            'Middlesex County', 'Philadelphia County', 'Suffolk County', 'Sacramento County',
            'Bronx County', 'Palm Beach County', 'Hillsborough County', 'Hennepin County',
            'Cuyahoga County', 'Franklin County', 'Allegheny County', 'Travis County',
            'Oakland County', 'Contra Costa County', 'Salt Lake County', 'Fulton County',
            'Orange County FL', 'Pinellas County', 'Fairfax County', 'Montgomery County MD',
            'Mecklenburg County', 'Multnomah County', 'Erie County', 'San Francisco County',
            'Shelby County', 'Marion County', 'Hamilton County', 'Wake County',
            'Baltimore County', 'Milwaukee County', 'Pima County', 'Collin County',
            'St. Louis County', 'DuPage County', 'Fresno County', 'Kern County',
            'El Paso County', 'Essex County', 'Ventura County', 'Gwinnett County',
            'Denver County', 'Prince Georges County', 'New Haven County'
        ) AS arr
    )
SELECT
    ROW_NUMBER() OVER (ORDER BY SEQ8()) AS LOAN_ID,
    DATEADD(
        'second',
        UNIFORM(-31536000, 0, RANDOM()), -- Random timestamp in last year
        CURRENT_TIMESTAMP()
    ) AS TS,
    loan_types.arr[UNIFORM(0, 3, RANDOM())]::STRING AS LOAN_TYPE_NAME,
    loan_purposes.arr[UNIFORM(0, 2, RANDOM())]::STRING AS LOAN_PURPOSE_NAME,
    IFF(
        UNIFORM(0, 100, RANDOM()) < 5, -- 5% NULL rate
        NULL,
        ROUND(UNIFORM(20, 500, RANDOM()) + NORMAL(0, 50, RANDOM()), 0)
    ) AS APPLICANT_INCOME_000S,
    ROUND(UNIFORM(50, 800, RANDOM()) + NORMAL(0, 100, RANDOM()), 0) AS LOAN_AMOUNT_000S,
    counties.arr[UNIFORM(0, 62, RANDOM())]::STRING AS COUNTY_NAME,
    IFF(UNIFORM(0, 100, RANDOM()) < 65, 1, 0) AS MORTGAGERESPONSE -- ~65% approval rate
FROM TABLE(GENERATOR(ROWCOUNT => 370000)),
    loan_types,
    loan_purposes,
    counties;

COMMENT ON TABLE MORTGAGE_LENDING_DEMO_DATA IS 'DEMO: Synthetic mortgage lending data | Expires: 2026-02-05';

-- ============================================================================
-- GIT INTEGRATION
-- ============================================================================
USE ROLE ACCOUNTADMIN;
CREATE API INTEGRATION IF NOT EXISTS SFE_GIT_API_INTEGRATION
    API_PROVIDER = git_https_api
    API_ALLOWED_PREFIXES = ('https://github.com/snowflake-labs/')
    ENABLED = TRUE
    COMMENT = 'DEMO: Git integration for Snowflake demos | Expires: 2026-02-05';
GRANT USAGE ON INTEGRATION SFE_GIT_API_INTEGRATION TO ROLE SYSADMIN;

USE ROLE SYSADMIN;
USE SCHEMA SNOWFLAKE_EXAMPLE.E2E_MLOPS;

CREATE OR REPLACE GIT REPOSITORY GIT_REPO_E2E_MLOPS
    ORIGIN = 'https://github.com/snowflake-labs/sfguide-E2E-ML.git'
    API_INTEGRATION = 'SFE_GIT_API_INTEGRATION'
    COMMENT = 'DEMO: E2E ML repo | Expires: 2026-02-05';

ALTER GIT REPOSITORY GIT_REPO_E2E_MLOPS FETCH;

-- ============================================================================
-- NOTEBOOK
-- ============================================================================
CREATE OR REPLACE NOTEBOOK TRAIN_DEPLOY_MONITOR_ML
    FROM '@GIT_REPO_E2E_MLOPS/branches/main/'
    MAIN_FILE = 'TRAIN_DEPLOY_MONITOR_ML.ipynb'
    WAREHOUSE = SFE_E2E_MLOPS_WH
    QUERY_WAREHOUSE = SFE_E2E_MLOPS_WH
    RUNTIME_NAME = 'SYSTEM$BASIC_RUNTIME'
    COMPUTE_POOL = 'SFE_E2E_MLOPS_CP'
    IDLE_AUTO_SHUTDOWN_TIME_SECONDS = 3600
    COMMENT = 'DEMO: E2E ML notebook | Expires: 2026-02-05';

SHOW NOTEBOOKS IN SCHEMA;
SELECT COUNT(*) AS MORTGAGE_LENDING_DEMO_DATA_ROW_COUNT
FROM MORTGAGE_LENDING_DEMO_DATA;

-- ============================================================================
-- CLEANUP
-- ============================================================================
-- To remove all demo resources, run cleanup.sql
-- This includes: schema, warehouse, compute pool, and all contained objects
