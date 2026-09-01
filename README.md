# SAS Customer Churn Prediction & Analysis Pipeline

## 📖 Project Overview
This project is an end-to-end data analytics and machine learning pipeline built to predict **voluntary customer churn** for a subscription-based business (e.g., Telecom, SaaS). 

The goal of this project is to transform churn from a lagging indicator ("we lost customers last month") into a leading indicator ("these customers are likely to leave next month, and here is why"). By identifying at-risk customers before they leave, the business can proactively intervene, reduce acquisition costs, and protect recurring revenue.

**Key Deliverables:**
- **Predictive Model:** A binary classification model that scores each active customer's probability of churning within the next billing cycle.
- **Risk-Scored Customer List:** Actionable data exports for Customer Success teams to prioritize outreach.
- **Churn Drivers Analysis:** Identification of top product gaps and service attributes driving customer attrition for Product Managers.
- **Automated KPI Dashboard:** An ODS HTML dashboard tracking churn rates, retention, and risk distributions across segments.

## 🛠️ Technologies Used
The entire data lifecycle—from ingestion and cleaning to modeling and reporting—is fully scripted using **SAS**.

- **Core Technology:** SAS (SAS 9.4, SAS Studio, or SAS Viya)
- **Data Ingestion & Processing:** `PROC IMPORT`, standard SAS Data Steps
- **Exploratory Data Analysis (EDA):** `PROC MEANS`, `PROC FREQ`, `PROC SGPLOT`
- **Machine Learning & Modeling:**
  - `PROC LOGISTIC` (Primary classification model)
  - `PROC HPSPLIT` (Decision tree comparison)
  - `PROC FASTCLUS` (Customer segmentation/clustering)
- **Reporting & Visualization:** SAS Output Delivery System (ODS HTML) for generating automated KPI dashboards.
- **Documentation:** Markdown & Mermaid.js for architecture diagrams
- **Dataset:** [Telco Customer Churn (Kaggle)](https://www.kaggle.com/datasets/blastchar/telco-customer-churn)

---

# How to Run This Project

This project is designed to be run sequentially in any modern SAS environment (SAS 9.4, SAS Studio, or SAS Viya). 

Follow these steps to execute the entire pipeline from raw data to the final KPI dashboard.

## Step 1: Set Up the Folders
1. Ensure your project folder structure matches the layout defined in [06_Architecture_and_Plan.md](06_Architecture_and_Plan.md).
2. Specifically, make sure you have created these two folders:
   - `Data/Raw/`
   - `Data/Processed/`
   - `Output/`

## Step 2: Download the Dataset
1. Go to Kaggle: [Telco Customer Churn Dataset](https://www.kaggle.com/datasets/blastchar/telco-customer-churn)
2. Download the CSV file.
3. Rename the file to **`telco_churn.csv`** (all lowercase).
4. Place the file inside your `Data/Raw/` folder.

## Step 3: Update the Project Path
Before running any code, you must tell SAS where your project folder is located on your computer.

1. Open `03_SAS_Programs/00_import_data.sas`.
2. Find the line that says: 
   `%let project_path = /home/your_username/SAS_Churn_Project;`
3. Change `/home/your_username/SAS_Churn_Project` to the actual absolute path of your SAS folder (e.g., `/Users/archana/Documents/SAS`).
   *Note: If you are using SAS Studio on the cloud (SAS OnDemand for Academics), the path will look something like `/home/u12345678/SAS/`.*

## Step 4: Run the Programs Sequentially
Open and run each `.sas` program in the exact order listed below. Do not skip any programs, as each script relies on the dataset created by the previous one.

1. **`00_import_data.sas`** 
   - *What it does:* Loads the CSV and creates `CHURN.raw_telco`.
2. **`01_data_quality.sas`**
   - *What it does:* Runs quality checks (no new data generated). Review the output logs.
3. **`02_data_cleaning.sas`**
   - *What it does:* Fixes data types and missing values, creates `CHURN.clean_telco`.
4. **`03_eda.sas`**
   - *What it does:* Generates business charts and exploratory analysis.
5. **`04_feature_engineering.sas`**
   - *What it does:* Creates predictive variables, outputs `CHURN.features_telco`.
6. **`05_segmentation.sas`**
   - *What it does:* Clusters customers, outputs `CHURN.segmented_telco`.
7. **`06_churn_model.sas`**
   - *What it does:* Trains the Logistic Regression model, outputs `CHURN.model_scored`.
8. **`07_model_evaluation.sas`**
   - *What it does:* Evaluates accuracy, recall, ROC-AUC.
9. **`08_risk_scoring.sas`**
   - *What it does:* Categorizes risk, exports `customer_risk_report.csv` to the Output folder.
10. **`09_churn_drivers.sas`**
    - *What it does:* Identifies what causes churn for product recommendations.
11. **`10_dashboard.sas`**
    - *What it does:* Generates the final `Churn_KPI_Dashboard.html` in the Output folder.

## Step 5: Review Outputs
Once complete, navigate to your `Output/` folder to view the deliverables:
* `customer_risk_report.csv`: The list of customers to hand off to the Customer Success team.
* `Churn_KPI_Dashboard.html`: The KPI dashboard for the Product Management team.
