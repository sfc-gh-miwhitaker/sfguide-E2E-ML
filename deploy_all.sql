-- ============================================================================
-- DEMO: End-to-End ML Pipeline
-- Author: SE Community
-- Expires: 2025-01-15
-- ============================================================================
-- COPY THIS ENTIRE SCRIPT INTO SNOWSIGHT AND CLICK "RUN ALL"
-- ============================================================================

-- Expiration check
SET DEMO_EXPIRATION = '2025-01-15';
SELECT IFF(CURRENT_DATE() > $DEMO_EXPIRATION::DATE,
    1/0, 'Demo valid until ' || $DEMO_EXPIRATION) AS EXPIRATION_STATUS;

USE ROLE SYSADMIN;

-- Shared demo database and schema
CREATE DATABASE IF NOT EXISTS SNOWFLAKE_EXAMPLE;
CREATE SCHEMA IF NOT EXISTS SNOWFLAKE_EXAMPLE.E2E_MLOPS
    COMMENT = 'DEMO: End-to-End ML Pipeline | Expires: 2025-01-15';

-- Warehouse (SFE_ prefix)
CREATE WAREHOUSE IF NOT EXISTS SFE_E2E_MLOPS_WH
    WAREHOUSE_SIZE = 'MEDIUM'
    AUTO_SUSPEND = 60
    AUTO_RESUME = TRUE
    INITIALLY_SUSPENDED = TRUE
    COMMENT = 'DEMO: E2E ML Pipeline | Expires: 2025-01-15';

-- Compute pool (SFE_ prefix)
CREATE COMPUTE POOL IF NOT EXISTS SFE_E2E_MLOPS_CP
    MIN_NODES = 1
    MAX_NODES = 1
    INSTANCE_FAMILY = CPU_X64_M
    AUTO_RESUME = TRUE
    AUTO_SUSPEND_SECS = 300
    COMMENT = 'DEMO: E2E ML Pipeline | Expires: 2025-01-15';

USE WAREHOUSE SFE_E2E_MLOPS_WH;
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
    counties
COMMENT = 'DEMO: Synthetic mortgage lending data | Expires: 2025-01-15';

-- ============================================================================
-- GIT INTEGRATION
-- ============================================================================
USE ROLE ACCOUNTADMIN;
CREATE API INTEGRATION IF NOT EXISTS SFE_GIT_API_INTEGRATION
    API_PROVIDER = git_https_api
    API_ALLOWED_PREFIXES = ('https://github.com/sfc-gh-miwhitaker')
    ENABLED = TRUE
    COMMENT = 'DEMO: Git integration for Snowflake demos';
GRANT USAGE ON INTEGRATION SFE_GIT_API_INTEGRATION TO ROLE SYSADMIN;

USE ROLE SYSADMIN;
USE SCHEMA SNOWFLAKE_EXAMPLE.E2E_MLOPS;

CREATE OR REPLACE GIT REPOSITORY GIT_REPO_E2E_MLOPS
    ORIGIN = 'https://github.com/sfc-gh-miwhitaker/sfguide-E2E-ML'
    API_INTEGRATION = 'SFE_GIT_API_INTEGRATION'
    COMMENT = 'DEMO: E2E ML repo | Expires: 2025-01-15';

ALTER GIT REPOSITORY GIT_REPO_E2E_MLOPS FETCH;

-- ============================================================================
-- NOTEBOOK
-- ============================================================================
CREATE OR REPLACE NOTEBOOK TRAIN_DEPLOY_MONITOR_ML
    FROM '@GIT_REPO_E2E_MLOPS/branches/main/'
    MAIN_FILE = 'train_deploy_monitor_ML_in_snowflake.ipynb'
    QUERY_WAREHOUSE = SFE_E2E_MLOPS_WH
    RUNTIME_NAME = 'SYSTEM$BASIC_RUNTIME'
    COMPUTE_POOL = 'SFE_E2E_MLOPS_CP'
    IDLE_AUTO_SHUTDOWN_TIME_SECONDS = 3600
    COMMENT = 'DEMO: E2E ML notebook | Expires: 2025-01-15';

SHOW NOTEBOOKS IN SCHEMA;
SELECT
    'Setup complete! Data: ' || (SELECT COUNT(*) FROM MORTGAGE_LENDING_DEMO_DATA) || ' rows generated.'
    AS STATUS;

-- ============================================================================
-- CLEANUP (uncomment to remove all demo objects)
-- ============================================================================
-- USE ROLE SYSADMIN;
-- DROP SCHEMA IF EXISTS SNOWFLAKE_EXAMPLE.E2E_MLOPS CASCADE;
-- DROP WAREHOUSE IF EXISTS SFE_E2E_MLOPS_WH;
-- DROP COMPUTE POOL IF EXISTS SFE_E2E_MLOPS_CP;

