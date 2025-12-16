-- ============================================================================
-- DEMO CLEANUP: End-to-End ML Pipeline
-- Author: SE Community
-- Purpose: Remove all demo resources
-- ============================================================================
-- COPY THIS ENTIRE SCRIPT INTO SNOWSIGHT AND CLICK "RUN ALL"
-- ============================================================================

USE ROLE SYSADMIN;

-- ============================================================================
-- CONFIRMATION CHECK
-- ============================================================================
-- Uncomment the line below to confirm you want to proceed with cleanup
-- SET CONFIRM_CLEANUP = 'YES';

SELECT 
    CASE 
        WHEN TRY_CAST($CONFIRM_CLEANUP AS STRING) = 'YES' THEN 
            '✅ Proceeding with cleanup...'
        ELSE 
            '⚠️ CLEANUP ABORTED: Uncomment SET CONFIRM_CLEANUP = ''YES''; to proceed'
    END AS CLEANUP_STATUS;

-- Abort if not confirmed
BEGIN
    IF TRY_CAST($CONFIRM_CLEANUP AS STRING) != 'YES' THEN
        RAISE STATEMENT_ERROR(MSG => 'Cleanup not confirmed. Uncomment the SET CONFIRM_CLEANUP line to proceed.');
    END IF;
END;

-- ============================================================================
-- CLEANUP: SCHEMA AND ALL CONTAINED OBJECTS
-- ============================================================================
SELECT '🗑️ Dropping schema E2E_MLOPS and all contained objects...' AS STATUS;

DROP SCHEMA IF EXISTS SNOWFLAKE_EXAMPLE.E2E_MLOPS CASCADE;

SELECT '✅ Schema dropped successfully' AS STATUS;

-- ============================================================================
-- CLEANUP: ACCOUNT-LEVEL OBJECTS
-- ============================================================================
SELECT '🗑️ Dropping warehouse SFE_E2E_MLOPS_WH...' AS STATUS;

DROP WAREHOUSE IF EXISTS SFE_E2E_MLOPS_WH;

SELECT '✅ Warehouse dropped successfully' AS STATUS;

-- ============================================================================
-- CLEANUP: COMPUTE POOL
-- ============================================================================
SELECT '🗑️ Stopping and dropping compute pool SFE_E2E_MLOPS_CP...' AS STATUS;

-- Stop all services on compute pool first
ALTER COMPUTE POOL IF EXISTS SFE_E2E_MLOPS_CP STOP ALL;

-- Wait a moment for services to stop
CALL SYSTEM$WAIT(5, 'SECONDS');

-- Drop the compute pool
DROP COMPUTE POOL IF EXISTS SFE_E2E_MLOPS_CP;

SELECT '✅ Compute pool dropped successfully' AS STATUS;

-- ============================================================================
-- VERIFICATION: CHECK FOR REMAINING OBJECTS
-- ============================================================================
SELECT '🔍 Verifying cleanup...' AS STATUS;

-- Check schema
SELECT 
    CASE 
        WHEN COUNT(*) = 0 THEN '✅ Schema E2E_MLOPS: Not found (cleaned up)'
        ELSE '⚠️ Schema E2E_MLOPS: Still exists (' || COUNT(*) || ' found)'
    END AS VERIFICATION_RESULT
FROM INFORMATION_SCHEMA.SCHEMATA
WHERE SCHEMA_NAME = 'E2E_MLOPS' 
  AND CATALOG_NAME = 'SNOWFLAKE_EXAMPLE';

-- Check warehouse
SELECT 
    CASE 
        WHEN COUNT(*) = 0 THEN '✅ Warehouse SFE_E2E_MLOPS_WH: Not found (cleaned up)'
        ELSE '⚠️ Warehouse SFE_E2E_MLOPS_WH: Still exists (' || COUNT(*) || ' found)'
    END AS VERIFICATION_RESULT
FROM INFORMATION_SCHEMA.WAREHOUSES
WHERE WAREHOUSE_NAME = 'SFE_E2E_MLOPS_WH';

-- Check compute pool
SHOW COMPUTE POOLS LIKE 'SFE_E2E_MLOPS_CP';

SELECT 
    CASE 
        WHEN (SELECT COUNT(*) FROM TABLE(RESULT_SCAN(LAST_QUERY_ID()))) = 0 
        THEN '✅ Compute Pool SFE_E2E_MLOPS_CP: Not found (cleaned up)'
        ELSE '⚠️ Compute Pool SFE_E2E_MLOPS_CP: Still exists'
    END AS VERIFICATION_RESULT;

-- ============================================================================
-- SUMMARY
-- ============================================================================
SELECT '🎉 Cleanup complete!' AS STATUS;

SELECT 
    'Note: SFE_GIT_API_INTEGRATION is a shared resource and was not removed.' AS NOTE
UNION ALL
SELECT 
    'If you need to remove it, run: DROP INTEGRATION IF EXISTS SFE_GIT_API_INTEGRATION;' AS NOTE
UNION ALL
SELECT
    '(Requires ACCOUNTADMIN role)' AS NOTE;

-- ============================================================================
-- OBJECTS REMOVED:
-- ============================================================================
-- ✅ SNOWFLAKE_EXAMPLE.E2E_MLOPS schema (CASCADE - includes all tables, notebook, models, monitors)
-- ✅ SFE_E2E_MLOPS_WH warehouse
-- ✅ SFE_E2E_MLOPS_CP compute pool
--
-- NOT REMOVED (Shared Infrastructure):
-- ℹ️ SFE_GIT_API_INTEGRATION (may be used by other demos)
-- ℹ️ SNOWFLAKE_EXAMPLE database (shared across demos)
-- ============================================================================

