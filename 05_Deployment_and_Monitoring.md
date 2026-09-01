# Section 18: Deployment & Operational Workflow

Building the model is only half the battle; deploying it into a production environment where it influences daily business operations is the other half.

## Operational Workflow

Here is how the model operates in production on a daily/weekly basis:

**1. Data Ingestion (Nightly Batch):**
* `New Customer Data` (billing, usage, demographics) is extracted from the data warehouse.

**2. SAS Data Pipeline:**
* Automated SAS scripts (`00_import`, `02_clean`, `04_feature_engineering`) run via SAS batch processing or SAS Viya scheduling to prepare the new daily snapshot.

**3. Model Scoring:**
* The saved SAS model (`CHURN.logistic_model`) is applied to the new data using `PROC LOGISTIC ... INMODEL=` or `PROC SCORE`.
* Every active customer receives a new `Churn_Probability` (0 to 1).

**4. Risk Classification:**
* The scoring script categorizes users into `High`, `Medium`, and `Low` risk based on predefined thresholds.
* Key risk drivers (e.g., "Month-to-month + High charge") are appended.

**5. System Integration:**
* The `risk_scored` table is exported and pushed to the company's CRM (e.g., Salesforce) via API or secure FTP.

**6. Action & Intervention:**
* **Customer Success Team:** Logs into Salesforce, sees a prioritized list of "High Risk" accounts, and initiates retention calls.
* **Marketing Automation:** Triggers targeted emails (e.g., the "Commit & Save" offer) to specific risk segments.
* **Product:** Reviews the automated SAS Dashboard (Section 14) to monitor macro trends.

---

# Section 19: Model Monitoring

A model's performance degrades over time as customer behavior, products, and market conditions change (concept drift). Continuous monitoring is required.

## 1. Data Quality Monitoring
Before scoring new data, the pipeline must check for anomalies:
* **Missing Value Spikes:** E.g., if a database error causes `MonthlyCharges` to be missing for 50% of users, scoring must halt.
* **Category Changes:** E.g., if the company introduces a new `Contract = 'Three year'`, the model will fail or score unpredictably unless updated.

## 2. Prediction Performance Monitoring (Model Decay)
We only know if a prediction was correct after the observation window closes (e.g., 30 days later).
* **Monthly Audit:** Compare last month's predictions against this month's actual churn.
* **Monitor ROC-AUC & Precision/Recall:** If ROC-AUC drops below 0.70, or precision falls significantly, the model is losing its predictive power.

## 3. Drift Monitoring
* **Feature Drift:** Are the distributions of input variables changing? (e.g., Average `tenure` suddenly dropping because of a massive marketing campaign acquiring new users).
* **Target Drift:** Is the overall baseline churn rate shifting significantly?

## 4. Model Retraining Criteria
Do not retrain the model daily. Set specific thresholds for retraining:
* **Scheduled:** Retrain quarterly to capture seasonal variations.
* **Triggered:** Retrain if ROC-AUC drops by more than 5% from the validation baseline.
* **Business Change:** Retrain immediately after major product launches, pricing changes, or the introduction of new data sources.
