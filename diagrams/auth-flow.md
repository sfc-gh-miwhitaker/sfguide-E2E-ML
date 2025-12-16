# Auth Flow - End-to-End ML Pipeline Demo
Author: SE Community
Last Updated: 2024-12-16
Expires: 2025-01-15
Status: Reference Implementation

![Snowflake](https://img.shields.io/badge/Snowflake-29B5E8?style=for-the-badge&logo=snowflake&logoColor=white)

Reference Implementation: This code demonstrates production-grade architectural patterns and best practices. Review and customize security, networking, and logic for your organization's specific requirements before deployment.

## Overview
This diagram shows the authentication and authorization flow for the E2E ML pipeline, demonstrating how SYSADMIN role is used for all operations and how permissions are granted for Git integration access.

```mermaid
sequenceDiagram
    actor User as User/Data Scientist
    participant Snowsight
    participant AuthService as Snowflake Auth
    participant RoleService as Role Service
    participant DB as SNOWFLAKE_EXAMPLE DB
    participant Objects as E2E_MLOPS Objects
    participant GitInt as Git Integration
    participant GitHub
    
    User->>Snowsight: Login (username/password or SSO)
    Snowsight->>AuthService: Authenticate User
    AuthService-->>Snowsight: Session Token
    
    User->>Snowsight: Open deploy_all.sql
    User->>Snowsight: Execute Script
    
    Snowsight->>RoleService: USE ROLE SYSADMIN
    RoleService-->>Snowsight: SYSADMIN Active
    
    Note over Snowsight,RoleService: SYSADMIN has CREATE DATABASE<br/>and CREATE WAREHOUSE privileges
    
    Snowsight->>DB: CREATE DATABASE IF NOT EXISTS SNOWFLAKE_EXAMPLE
    DB-->>Snowsight: Success (or already exists)
    
    Snowsight->>DB: CREATE SCHEMA E2E_MLOPS
    DB-->>Snowsight: Success
    
    Snowsight->>Objects: CREATE WAREHOUSE SFE_E2E_MLOPS_WH
    Objects-->>Snowsight: Success
    
    Snowsight->>Objects: CREATE COMPUTE POOL SFE_E2E_MLOPS_CP
    Objects-->>Snowsight: Success
    
    Note over Snowsight,RoleService: Switch to ACCOUNTADMIN<br/>for Git integration setup
    
    Snowsight->>RoleService: USE ROLE ACCOUNTADMIN
    RoleService-->>Snowsight: ACCOUNTADMIN Active
    
    Snowsight->>GitInt: CREATE API INTEGRATION SFE_GIT_API_INTEGRATION
    GitInt-->>Snowsight: Success
    
    Snowsight->>GitInt: GRANT USAGE ON INTEGRATION TO SYSADMIN
    GitInt-->>Snowsight: Permission Granted
    
    Note over Snowsight,RoleService: Return to SYSADMIN for<br/>remaining operations
    
    Snowsight->>RoleService: USE ROLE SYSADMIN
    RoleService-->>Snowsight: SYSADMIN Active
    
    Snowsight->>Objects: CREATE GIT REPOSITORY (uses integration)
    Objects->>GitInt: Validate Integration Permission
    GitInt-->>Objects: Permission OK
    Objects->>GitHub: Fetch Repository (HTTPS)
    GitHub-->>Objects: Repository Contents
    Objects-->>Snowsight: Success
    
    Snowsight->>Objects: CREATE NOTEBOOK (from Git repo)
    Objects-->>Snowsight: Success
    
    User->>Snowsight: Open Notebook
    Snowsight->>RoleService: Verify SYSADMIN Active
    RoleService-->>Snowsight: Authorized
    Snowsight->>Objects: Load Notebook
    Objects-->>Snowsight: Notebook Ready
    Snowsight-->>User: Notebook Interface
    
    User->>Snowsight: Execute Notebook Cells
    Snowsight->>Objects: Query/Write Operations
    Note over Snowsight,Objects: All operations run as SYSADMIN<br/>using SFE_E2E_MLOPS_WH
    Objects-->>Snowsight: Results
    Snowsight-->>User: Display Results
```

## Component Descriptions

### Authentication Layer
- **Snowflake Auth Service**
  - Purpose: Authenticate users via username/password, SSO, or federated auth
  - Technology: Snowflake authentication service
  - Methods: Native, SAML, OAuth, Okta, ADFS
  - Session: Tokens valid for configured session timeout
  
### Authorization Layer
- **Role Service**
  - Purpose: Manage role context and permission checks
  - Roles Used:
    - **SYSADMIN**: Primary role for all demo operations
    - **ACCOUNTADMIN**: Only for creating Git API integration
  - Security Model: Role-based access control (RBAC)

### Privileged Operations

#### SYSADMIN Role Permissions
```sql
-- Database Operations
CREATE DATABASE IF NOT EXISTS
CREATE SCHEMA IF NOT EXISTS

-- Compute Operations
CREATE WAREHOUSE (account-level)
CREATE COMPUTE POOL (account-level)

-- Object Operations
CREATE TABLE
CREATE NOTEBOOK
CREATE GIT REPOSITORY (requires integration permission)
CREATE OR REPLACE MODEL
CREATE MODEL MONITOR

-- Usage Operations
USE WAREHOUSE
USE DATABASE
USE SCHEMA
```

#### ACCOUNTADMIN Role Permissions (Limited Use)
```sql
-- Integration Operations (one-time setup)
CREATE API INTEGRATION SFE_GIT_API_INTEGRATION
GRANT USAGE ON INTEGRATION ... TO SYSADMIN
```

### Git Integration Authentication
- **SFE_GIT_API_INTEGRATION**
  - Purpose: Authenticate Snowflake to GitHub for repository access
  - Type: API Integration (git_https_api)
  - Credentials: None required (public repository)
  - Access: Read-only
  - Scope: Allowed prefixes (https://github.com/sfc-gh-miwhitaker)
  - Security: ACCOUNTADMIN creates, SYSADMIN uses

### Object Ownership
All objects created by SYSADMIN:
```
SNOWFLAKE_EXAMPLE (Database)
├── E2E_MLOPS (Schema)
    ├── MORTGAGE_LENDING_DEMO_DATA (Table)
    ├── TRAIN_DEPLOY_MONITOR_ML (Notebook)
    ├── GIT_REPO_E2E_MLOPS (Git Repository)
    ├── MORTGAGE_LENDING_MLOPS_0 (Model Registry)
    └── Model Monitors (Monitoring Objects)

Account-Level Objects:
├── SFE_E2E_MLOPS_WH (Warehouse)
├── SFE_E2E_MLOPS_CP (Compute Pool)
└── SFE_GIT_API_INTEGRATION (API Integration - ACCOUNTADMIN)
```

### Permission Flow

1. **Initial Setup**
   - User authenticates to Snowflake
   - User assumes SYSADMIN role
   - SYSADMIN creates database, schema, warehouse, compute pool

2. **Git Integration Setup**
   - Switch to ACCOUNTADMIN (required for CREATE INTEGRATION)
   - Create SFE_GIT_API_INTEGRATION
   - Grant USAGE to SYSADMIN
   - Switch back to SYSADMIN

3. **Repository and Notebook Creation**
   - SYSADMIN creates Git repository (uses integration)
   - Snowflake authenticates to GitHub via integration
   - Fetch repository contents
   - Create notebook from repository

4. **Runtime Execution**
   - User opens notebook (SYSADMIN permission check)
   - Notebook executes on SFE_E2E_MLOPS_CP (SYSADMIN-owned)
   - Queries use SFE_E2E_MLOPS_WH (SYSADMIN-owned)
   - All data access controlled by SYSADMIN object ownership

### Security Boundaries

| Boundary | Control | Implementation |
|----------|---------|----------------|
| User Authentication | Snowflake Auth | Username/password or SSO |
| Role Authorization | RBAC | SYSADMIN role required |
| Object Access | Ownership | SYSADMIN owns all objects |
| Git Access | API Integration | ACCOUNTADMIN creates, SYSADMIN uses |
| Network | HTTPS/TLS | All external connections encrypted |

### Access Control List (Effective Permissions)

```
SYSADMIN Role:
  ✅ CREATE DATABASE, SCHEMA, WAREHOUSE, COMPUTE POOL
  ✅ CREATE TABLE, VIEW, NOTEBOOK
  ✅ CREATE GIT REPOSITORY (with integration permission)
  ✅ CREATE MODEL, MODEL MONITOR
  ✅ USAGE on SFE_GIT_API_INTEGRATION (explicitly granted)
  ❌ CREATE INTEGRATION (requires ACCOUNTADMIN)

ACCOUNTADMIN Role:
  ✅ All SYSADMIN permissions
  ✅ CREATE INTEGRATION
  ✅ GRANT permissions to other roles
```

## Best Practices

1. **Principle of Least Privilege**
   - Use SYSADMIN for all operations except integration creation
   - Only escalate to ACCOUNTADMIN when required
   - Immediately return to SYSADMIN after privileged operation

2. **Role Segregation**
   - ACCOUNTADMIN: Setup integrations only
   - SYSADMIN: All demo operations and object management
   - User roles: Read-only access (not covered in this demo)

3. **Object Ownership**
   - All demo objects owned by SYSADMIN
   - Clear cleanup path (DROP CASCADE from SYSADMIN)
   - No orphaned objects

4. **Integration Security**
   - API integrations require ACCOUNTADMIN
   - Grant USAGE to SYSADMIN explicitly
   - Use allowed_prefixes to restrict access scope

## Change History
See `.cursor/DIAGRAM_CHANGELOG.md` for version history.

