-- ============================================================================
-- DEMO CLEANUP: End-to-End ML Pipeline
-- ============================================================================
-- Author: SE Community
-- Purpose: Remove all demo resources
-- Expires: 2026-02-05
--
-- WARNING: This script will DROP all E2E ML Pipeline demo objects.
--
-- Objects Removed:
--   - Notebook: TRAIN_DEPLOY_MONITOR_ML
--   - Git Repository: GIT_REPO_E2E_MLOPS
--   - All tables, models, monitors in E2E_MLOPS schema
--   - Schema: SNOWFLAKE_EXAMPLE.E2E_MLOPS (CASCADE)
--   - Warehouse: SFE_E2E_MLOPS_WH
--   - Compute Pool: SFE_E2E_MLOPS_CP
--
-- Protected (NOT removed):
--   - SNOWFLAKE_EXAMPLE database
--   - SFE_GIT_API_INTEGRATION (may be shared by other demos)
-- ============================================================================
-- COPY THIS ENTIRE SCRIPT INTO SNOWSIGHT AND CLICK "RUN ALL"
-- ============================================================================

USE ROLE SYSADMIN;

-- ============================================================================
-- STEP 1: DROP SCHEMA (cascades all tables, notebook, models, monitors)
-- ============================================================================
DROP SCHEMA IF EXISTS SNOWFLAKE_EXAMPLE.E2E_MLOPS CASCADE;

-- ============================================================================
-- STEP 2: DROP WAREHOUSE
-- ============================================================================
DROP WAREHOUSE IF EXISTS SFE_E2E_MLOPS_WH;

-- ============================================================================
-- STEP 3: DROP COMPUTE POOL (requires ACCOUNTADMIN)
-- ============================================================================
USE ROLE ACCOUNTADMIN;

-- Stop all services on compute pool first
ALTER COMPUTE POOL IF EXISTS SFE_E2E_MLOPS_CP STOP ALL;

-- Wait for services to stop
CALL SYSTEM$WAIT(5, 'SECONDS');

-- Drop the compute pool
DROP COMPUTE POOL IF EXISTS SFE_E2E_MLOPS_CP;

-- ============================================================================
-- STEP 4: VERIFICATION
-- ============================================================================
USE ROLE SYSADMIN;

-- Verify schema removed
SHOW SCHEMAS LIKE 'E2E_MLOPS' IN DATABASE SNOWFLAKE_EXAMPLE;

-- Verify warehouse removed
SHOW WAREHOUSES LIKE 'SFE_E2E_MLOPS_WH';

-- Verify compute pool removed (requires ACCOUNTADMIN)
USE ROLE ACCOUNTADMIN;
SHOW COMPUTE POOLS LIKE 'SFE_E2E_MLOPS_CP';

SELECT 'Cleanup complete.' AS STATUS
UNION ALL
SELECT 'Note: SFE_GIT_API_INTEGRATION is a shared resource and was NOT removed.' AS STATUS
UNION ALL
SELECT 'If needed, drop it manually: DROP API INTEGRATION IF EXISTS SFE_GIT_API_INTEGRATION;' AS STATUS;
