/*****************************************************************************
 * Program:     01_data_quality.sas
 * Section:     5 — Data Quality Assessment
 * Purpose:     Systematically assess data quality issues before cleaning.
 *              This program does NOT fix issues — it only documents them.
 *              Fixes are applied in 02_data_cleaning.sas.
 * Input:       CHURN.raw_telco
 * Output:      Data quality report (ODS output)
 * Author:      [Your Name]
 * Date:        [Date]
 *****************************************************************************/

/*==========================================================================
  STEP 1: DETECT MISSING VALUES
  
  WHY: Missing values can bias model results. We need to know which
  variables have missing data, how much, and whether the missingness
  is random or systematic.
==========================================================================*/

/* 1a. Count missing values for ALL variables */
proc format;
    value $missfmt ' ' = 'Missing'  other = 'Not Missing';
    value  missfmt .   = 'Missing'  other = 'Not Missing';
run;

/* Numeric variables — missing values */
proc means data=CHURN.raw_telco nmiss n;
    title "Missing Values — Numeric Variables";
    var SeniorCitizen tenure MonthlyCharges;
run;

/* Character variables — blank/empty detection */
proc sql;
    title "Missing/Blank Values — All Character Variables";
    select 
        sum(case when customerID       = ' ' then 1 else 0 end) as customerID_blank,
        sum(case when gender           = ' ' then 1 else 0 end) as gender_blank,
        sum(case when Partner          = ' ' then 1 else 0 end) as Partner_blank,
        sum(case when Dependents       = ' ' then 1 else 0 end) as Dependents_blank,
        sum(case when PhoneService     = ' ' then 1 else 0 end) as PhoneService_blank,
        sum(case when MultipleLines    = ' ' then 1 else 0 end) as MultipleLines_blank,
        sum(case when InternetService  = ' ' then 1 else 0 end) as InternetService_blank,
        sum(case when OnlineSecurity   = ' ' then 1 else 0 end) as OnlineSecurity_blank,
        sum(case when OnlineBackup     = ' ' then 1 else 0 end) as OnlineBackup_blank,
        sum(case when DeviceProtection = ' ' then 1 else 0 end) as DeviceProtection_blank,
        sum(case when TechSupport      = ' ' then 1 else 0 end) as TechSupport_blank,
        sum(case when StreamingTV      = ' ' then 1 else 0 end) as StreamingTV_blank,
        sum(case when StreamingMovies  = ' ' then 1 else 0 end) as StreamingMovies_blank,
        sum(case when Contract         = ' ' then 1 else 0 end) as Contract_blank,
        sum(case when PaperlessBilling = ' ' then 1 else 0 end) as PaperlessBilling_blank,
        sum(case when PaymentMethod    = ' ' then 1 else 0 end) as PaymentMethod_blank,
        sum(case when TotalCharges     = ' ' then 1 else 0 end) as TotalCharges_blank,
        sum(case when Churn            = ' ' then 1 else 0 end) as Churn_blank
    from CHURN.raw_telco;
quit;

/*
  KNOWN ISSUE: TotalCharges has blank values for customers with tenure = 0.
  These are new customers who haven't been charged yet.
  This is expected data, not a data error.
*/

/* 1b. Identify which rows have blank TotalCharges */
proc sql;
    title "Customers with Blank TotalCharges";
    select customerID, tenure, MonthlyCharges, TotalCharges
    from CHURN.raw_telco
    where TotalCharges = ' ';
quit;
/* Expected: ~11 rows where tenure = 0 */

/*==========================================================================
  STEP 2: DETECT DUPLICATE RECORDS
  
  WHY: Duplicates inflate counts and distort model training.
  We check for exact row duplicates and duplicate customer IDs.
==========================================================================*/

/* 2a. Check for duplicate customerIDs */
proc sql;
    title "Duplicate Customer IDs";
    select customerID, count(*) as occurrences
    from CHURN.raw_telco
    group by customerID
    having count(*) > 1;
quit;
/* Expected: 0 rows (no duplicates in this dataset) */

/* 2b. Check for fully identical rows (all columns the same) */
proc sort data=CHURN.raw_telco out=_check_dupes nodupkey dupout=_dupes;
    by _all_;
run;

proc sql;
    select count(*) as Duplicate_Rows from _dupes;
quit;
title "Number of Exact Duplicate Rows";

/* Clean up temp tables */
proc delete data=_check_dupes _dupes; run;

/*==========================================================================
  STEP 3: IDENTIFY INCORRECT DATA TYPES
  
  WHY: Variables stored as the wrong type will cause errors in calculations
  and model building. The most common issue is numeric values stored as 
  character strings.
==========================================================================*/

/* 3a. Check variable types */
proc contents data=CHURN.raw_telco short;
    title "Variable Types — Quick Reference";
run;

/* 3b. Verify TotalCharges is character (known issue) */
proc sql;
    title "TotalCharges — Type Check";
    select name, type, length
    from dictionary.columns
    where libname = 'CHURN' 
      and memname = 'RAW_TELCO' 
      and upcase(name) = 'TOTALCHARGES';
quit;
/*
  ISSUE: TotalCharges should be NUMERIC but PROC IMPORT reads it as 
  CHARACTER because some values are blank (which SAS interprets as 
  non-numeric). This must be fixed in 02_data_cleaning.sas.
*/

/* 3c. Check SeniorCitizen — should be 0/1 only */
proc freq data=CHURN.raw_telco;
    title "SeniorCitizen — Value Distribution (should be 0 and 1 only)";
    tables SeniorCitizen / missing;
run;

/*==========================================================================
  STEP 4: FIND INVALID / OUTLIER VALUES
  
  WHY: Extreme values can disproportionately influence model coefficients.
  We need to understand whether outliers are real or data errors.
==========================================================================*/

/* 4a. Descriptive statistics for numeric variables */
proc means data=CHURN.raw_telco n nmiss min q1 median q3 max mean std;
    title "Descriptive Statistics — Numeric Variables";
    var SeniorCitizen tenure MonthlyCharges;
run;

/* 4b. Check for impossible values */
proc sql;
    title "Data Validation — Range Checks";
    select 
        sum(case when tenure < 0 then 1 else 0 end) as Negative_Tenure,
        sum(case when MonthlyCharges < 0 then 1 else 0 end) as Negative_Monthly,
        sum(case when SeniorCitizen not in (0, 1) then 1 else 0 end) as Invalid_Senior,
        min(tenure) as Min_Tenure,
        max(tenure) as Max_Tenure,
        min(MonthlyCharges) as Min_Monthly,
        max(MonthlyCharges) as Max_Monthly
    from CHURN.raw_telco;
quit;

/* 4c. Box plots to visualize potential outliers */
proc sgplot data=CHURN.raw_telco;
    title "Distribution of Monthly Charges";
    vbox MonthlyCharges / category=Churn;
    xaxis label="Churn Status";
    yaxis label="Monthly Charges ($)";
run;

proc sgplot data=CHURN.raw_telco;
    title "Distribution of Tenure";
    vbox tenure / category=Churn;
    xaxis label="Churn Status";
    yaxis label="Tenure (months)";
run;

/*==========================================================================
  STEP 5: CHECK INCONSISTENT CATEGORIES
  
  WHY: Categorical variables may have inconsistent values due to data
  entry errors (e.g., "Yes", "yes", "YES", "Y" all meaning the same thing).
==========================================================================*/

/* 5a. Frequency tables for ALL categorical variables */
proc freq data=CHURN.raw_telco;
    title "Category Values — All Categorical Variables";
    tables gender Partner Dependents PhoneService MultipleLines
           InternetService OnlineSecurity OnlineBackup DeviceProtection
           TechSupport StreamingTV StreamingMovies Contract 
           PaperlessBilling PaymentMethod Churn / missing nocum;
run;

/*
  WHAT TO LOOK FOR:
  - Unexpected category values (e.g., "Yse" instead of "Yes")
  - Case inconsistencies (e.g., "yes" vs "Yes")
  - Leading/trailing spaces
  - Very rare categories that might be errors
  - "No internet service" / "No phone service" — these are valid 
    dependent categories, not errors
*/

/*==========================================================================
  STEP 6: ANALYZE CHURN CLASS DISTRIBUTION
  
  WHY: Understanding the class balance is critical for choosing the right
  model evaluation metrics and determining if resampling is needed.
==========================================================================*/

/* 6a. Churn distribution — counts and percentages */
proc freq data=CHURN.raw_telco;
    title "Churn Class Distribution";
    tables Churn / missing nocum;
run;

/* 6b. Visualize the class imbalance */
proc sgplot data=CHURN.raw_telco;
    title "Churn Class Distribution";
    vbar Churn / stat=freq datalabel 
         fillattrs=(color=CX4A90D9) 
         outlineattrs=(color=CX2C5F8A);
    xaxis label="Churn Status";
    yaxis label="Number of Customers";
run;

/* 6c. Churn rate as a percentage */
proc sql;
    title "Churn Rate Summary";
    select 
        count(*) as Total_Customers,
        sum(case when Churn = 'Yes' then 1 else 0 end) as Churned,
        sum(case when Churn = 'No'  then 1 else 0 end) as Retained,
        calculated Churned / calculated Total_Customers * 100 
            as Churn_Rate_Pct format=5.1,
        calculated Retained / calculated Total_Customers * 100 
            as Retention_Rate_Pct format=5.1
    from CHURN.raw_telco;
quit;

/*==========================================================================
  DATA QUALITY SUMMARY
  
  After running this program, document your findings in this checklist:
  
  ┌──────────────────────────────┬──────────┬───────────────────────────┐
  │ Check                        │ Status   │ Notes                     │
  ├──────────────────────────────┼──────────┼───────────────────────────┤
  │ Missing values               │ [CHECK]  │ TotalCharges ~11 blanks   │
  │ Duplicate records            │ [CHECK]  │ Expected: none            │
  │ Incorrect data types         │ [CHECK]  │ TotalCharges is char      │
  │ Invalid/outlier values       │ [CHECK]  │ No impossible values      │
  │ Inconsistent categories      │ [CHECK]  │ Expected: clean           │
  │ Class balance                │ [CHECK]  │ ~26.5% churn (moderate)   │
  └──────────────────────────────┴──────────┴───────────────────────────┘
  
  WHAT SHOULD BE FIXED (in 02_data_cleaning.sas):
  1. Convert TotalCharges from CHARACTER to NUMERIC
  2. Handle blank TotalCharges values (impute with 0 for tenure=0 customers)
  3. Convert Churn from "Yes"/"No" to 1/0 numeric for modeling
  4. Create numeric indicator variables for categorical predictors
  5. Verify no other anomalies were found
==========================================================================*/

title;  /* Clear titles */
