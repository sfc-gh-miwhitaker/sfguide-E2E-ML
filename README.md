![Reference Implementation](https://img.shields.io/badge/Reference-Implementation-blue)
![Ready to Run](https://img.shields.io/badge/Ready%20to%20Run-Yes-green)
![Snowflake](https://img.shields.io/badge/Snowflake-29B5E8?logo=snowflake&logoColor=white)
![Expires](https://img.shields.io/badge/Expires-2026--02--05-orange)

# End-to-End ML Pipeline Demo

> **DEMONSTRATION PROJECT - EXPIRES: 2026-02-05**<br>
> This demo uses Snowflake ML features current as of December 2025.<br>
> After expiration, this repository will be archived and made private.

- **Author:** SE Community
- **Purpose:** Reference implementation for end-to-end ML workflow in Snowflake
- **Created:** 2025-12-16 | **Expires:** 2026-02-05 (30 days) | **Status:** ACTIVE

---

## First Time Here?

Follow these steps to deploy and run the complete ML pipeline:

1. **Deploy Infrastructure** -> Copy `deploy_all.sql` into Snowsight (2 min)
2. **Run Setup** -> Click "Run All" - generates 370K rows of synthetic data (5 min)
3. **Open Notebook** -> Launch `TRAIN_DEPLOY_MONITOR_ML` notebook (1 min)
4. **Execute Workflow** -> Run notebook cells top-to-bottom (15 min)
5. **Cleanup** -> When finished, run `cleanup.sql` to remove all resources (1 min)

**Total setup time: ~23 minutes** | **Cleanup time: ~1 minute**

---

## What This Demo Showcases

This reference implementation demonstrates a production-grade end-to-end machine learning workflow entirely within Snowflake:

### Feature Store
- Store and track engineered feature definitions
- Reproducible feature computation across train/test datasets
- Automated feature lineage tracking

### Model Training and HPO
- **Baseline Model**: XGBoost classifier with default parameters
- **Optimized Model**: XGBoost with distributed hyperparameter optimization (HPO)
- Comparison of model performance to identify overfitting

### Model Registry
- Version control for ML models with metadata tracking
- Inference capabilities (batch and real-time)
- Built-in explainability with SHAP values
- Model comparison and promotion workflows

### ML Observability
- Model monitoring over 1 year of predictions
- Performance metrics: F1, Precision, Recall
- Model drift detection (prediction distribution changes)
- Side-by-side model comparison
- Data quality issue identification

### Data and Model Lineage
- Track data origin and feature computation
- View datasets used for model training
- Monitor available model versions
- End-to-end lineage visualization

### Advanced Features (Optional)
- Distributed GPU model training
- Snowpark Container Services (SPCS) deployment for inference
- REST API scoring endpoints

---

## Architecture Overview

### Data Flow
```
Synthetic Data Generation (370K rows)
  |
Feature Engineering (10 features)
  |
Train/Test Split (70/30)
  |
Model Training (XGBoost + HPO)
  |
Model Registry (version control)
  |
Batch Inference
  |
Model Monitoring (drift + performance)
```

### Key Components
- **Database:** `SNOWFLAKE_EXAMPLE.E2E_MLOPS` (shared demo namespace)
- **Warehouse:** `SFE_E2E_MLOPS_WH` (MEDIUM, auto-suspend 60s)
- **Compute Pool:** `SFE_E2E_MLOPS_CP` (1 node CPU_X64_M)
- **Notebook:** `TRAIN_DEPLOY_MONITOR_ML` (Jupyter-compatible)
- **Data:** 100% synthetic (no external files)

---

## Detailed Setup Instructions

### Prerequisites
- Snowflake account with SYSADMIN role access
- Snowsight UI access
- No external dependencies or data files required

### Step-by-Step Deployment

#### 1. Deploy Infrastructure (2 minutes)
```sql
-- Open deploy_all.sql in your code editor
-- Copy the entire file contents
-- Paste into Snowsight SQL worksheet
-- Click "Run All"
```

**What this does:**
- Creates `SNOWFLAKE_EXAMPLE.E2E_MLOPS` schema
- Provisions `SFE_E2E_MLOPS_WH` warehouse
- Creates `SFE_E2E_MLOPS_CP` compute pool
- Generates 370,000 rows of synthetic mortgage data
- Fetches notebook from Git repository
- Creates `TRAIN_DEPLOY_MONITOR_ML` notebook

#### 2. Verify Setup (1 minute)
```sql
-- Check that data was generated
SELECT COUNT(*) FROM SNOWFLAKE_EXAMPLE.E2E_MLOPS.MORTGAGE_LENDING_DEMO_DATA;
-- Expected: 370000

-- View available notebooks
SHOW NOTEBOOKS IN SCHEMA SNOWFLAKE_EXAMPLE.E2E_MLOPS;
-- Expected: TRAIN_DEPLOY_MONITOR_ML
```

#### 3. Run the Notebook (15 minutes)

**Navigate to Notebook:**
1. In Snowsight, go to **Projects** -> **Notebooks**
2. Select database: `SNOWFLAKE_EXAMPLE`
3. Select schema: `E2E_MLOPS`
4. Open notebook: `TRAIN_DEPLOY_MONITOR_ML`

**Execute Workflow:**
1. Click **Run All** or execute cells sequentially
2. Monitor progress (cells execute automatically)
3. Review outputs and visualizations

**Notebook Workflow:**
- Cell 1-5: Setup and data loading
- Cell 6-15: Feature engineering
- Cell 16-25: Feature Store setup
- Cell 26-40: Model training (baseline + HPO)
- Cell 41-55: Model registry operations
- Cell 56-70: Model inference
- Cell 71-85: Model monitoring setup
- Cell 86-95: SPCS deployment (optional)

---

## Architecture Diagrams

Detailed architecture documentation is available in the `diagrams/` directory:

- **[Data Model](diagrams/data-model.md)** - Database schema and table relationships
- **[Data Flow](diagrams/data-flow.md)** - How data moves through the pipeline
- **[Network Flow](diagrams/network-flow.md)** - Network architecture and connectivity
- **[Auth Flow](diagrams/auth-flow.md)** - Authentication and authorization patterns

---

## Features in Detail

### Synthetic Data Generation
No external CSV files or downloads required. Data is generated directly in Snowflake using:
- **GENERATOR** table function (370K rows)
- **UNIFORM** and **NORMAL** distributions for realistic values
- **RANDOM** functions for variability
- Configurable distributions and null rates

**Schema:**
```
LOAN_ID              INT       Unique identifier
TS                   TIMESTAMP Loan timestamp (past year)
LOAN_TYPE_NAME       STRING    Conventional/FHA/VA/FSA
LOAN_PURPOSE_NAME    STRING    Home purchase/improvement/refinancing
APPLICANT_INCOME_000S NUMBER   Applicant income (thousands, 5% NULL)
LOAN_AMOUNT_000S     NUMBER    Loan amount (thousands)
COUNTY_NAME          STRING    63 US counties
MORTGAGERESPONSE     INT       Approval (1) or denial (0) - 65% approval rate
```

### Feature Engineering
10 engineered features created using Snowpark:
- **Timestamp features**: MONTH, DAY_OF_YEAR, DOTW
- **Financial features**: LOAN_AMOUNT, INCOME, INCOME_LOAN_RATIO
- **Aggregate features**: MEAN_COUNTY_INCOME, HIGH_INCOME_FLAG
- **Window features**: AVG_THIRTY_DAY_LOAN_AMOUNT

### Model Training
Two XGBoost models trained and compared:
- **XGB_BASE**: Baseline with default hyperparameters (fast)
- **XGB_OPTIMIZED**: HPO-tuned for better generalization (slower, 8 trials)

Distributed HPO uses Snowflake's Ray cluster for parallel trials.

### Model Monitoring
Continuous monitoring of both models:
- **Performance metrics**: F1, Precision, Recall computed daily
- **Prediction drift**: Track changes in average predictions over time
- **Segmentation**: Analyze by loan purpose (home purchase, improvement, refinancing)
- **Baseline comparison**: Training data vs. production inference

---

## Cleanup

When finished with the demo, remove all resources using the dedicated cleanup script:

1. Open `cleanup.sql`
2. Copy the entire script into Snowsight
3. Click "Run All"

**What gets removed:**
- Schema `SNOWFLAKE_EXAMPLE.E2E_MLOPS` (CASCADE - all tables, notebook, models, monitors)
- Warehouse `SFE_E2E_MLOPS_WH`
- Compute Pool `SFE_E2E_MLOPS_CP`
- Verification checks confirm successful cleanup

**What stays (shared infrastructure):**
- `SFE_GIT_API_INTEGRATION` (may be used by other demos)
- `SNOWFLAKE_EXAMPLE` database (shared across demos)

The cleanup script includes verification steps. Review it before running, as it drops demo objects.

---

## Troubleshooting

### Data Not Generated
```sql
-- Check if table exists
SHOW TABLES LIKE 'MORTGAGE_LENDING_DEMO_DATA' IN SCHEMA SNOWFLAKE_EXAMPLE.E2E_MLOPS;

-- Regenerate if needed
USE SCHEMA SNOWFLAKE_EXAMPLE.E2E_MLOPS;
-- Run the CREATE TABLE AS SELECT from deploy_all.sql
```

### Notebook Not Found
```sql
-- Verify notebook exists
SHOW NOTEBOOKS IN SCHEMA SNOWFLAKE_EXAMPLE.E2E_MLOPS;

-- Recreate from Git if needed
ALTER GIT REPOSITORY GIT_REPO_E2E_MLOPS FETCH;
-- Run the CREATE NOTEBOOK command from deploy_all.sql
```

### Permission Errors
```sql
-- Verify you're using SYSADMIN
SELECT CURRENT_ROLE();

-- Switch if needed
USE ROLE SYSADMIN;
```

### Notebook Execution Failures
- Check warehouse is running: `SHOW WAREHOUSES LIKE 'SFE_E2E_MLOPS_WH';`
- Check compute pool status: `SHOW COMPUTE POOLS LIKE 'SFE_E2E_MLOPS_CP';`
- Restart notebook kernel if cells hang

---

## Technical Details

### Resource Sizing
- **Warehouse**: MEDIUM (sufficient for 370K rows)
- **Compute Pool**: 1 node CPU_X64_M (notebook runtime)
- **Data Size**: ~50MB compressed
- **Execution Time**: 15-20 minutes for full workflow

### Dependencies
All dependencies managed by Snowflake:
- Python 3.10 (SYSTEM$BASIC_RUNTIME)
- snowflake-ml-python >= 1.7.2
- XGBoost, pandas, numpy, scikit-learn
- SHAP for explainability

### Git Integration
Notebook synced from: `https://github.com/snowflake-labs/sfguide-e2e-ml`
- Auto-fetched during deployment
- Read-only access (public repository)
- Updates via `ALTER GIT REPOSITORY ... FETCH`

---

## Learn More

### Snowflake Documentation
- [Snowflake ML Overview](https://docs.snowflake.com/en/developer-guide/snowflake-ml/overview)
- [Feature Store](https://docs.snowflake.com/en/developer-guide/snowflake-ml/feature-store/overview)
- [Model Registry](https://docs.snowflake.com/en/developer-guide/snowflake-ml/model-registry/overview)
- [Model Monitoring](https://docs.snowflake.com/en/developer-guide/snowflake-ml/model-monitoring/overview)
- [Notebooks](https://docs.snowflake.com/en/user-guide/ui-snowsight-notebooks)

### Related Quickstarts
- [Getting Started with Snowflake ML](https://quickstarts.snowflake.com/guide/getting_started_with_snowflake_ml)
- [Machine Learning with Snowpark](https://quickstarts.snowflake.com/guide/machine_learning_with_snowpark)

---

## Support & Feedback

This is a reference implementation maintained by the Snowflake SE Community.

For issues or questions:
1. Review the [Troubleshooting](#troubleshooting) section
2. Check the [Architecture Diagrams](diagrams/)
3. Consult [Snowflake Documentation](https://docs.snowflake.com)

---

## License

See [LICENSE](LICENSE) file for details.

---

**Demo Expiration:** 2026-02-05 | **Status:** ACTIVE
