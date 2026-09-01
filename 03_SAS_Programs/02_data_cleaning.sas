/*****************************************************************************
 * Program:     02_data_cleaning.sas
 * Section:     6 — Data Cleaning and Preprocessing
 * Purpose:     Fix all data quality issues identified in 01_data_quality.sas.
 *              Every decision is documented with rationale.
 * Input:       CHURN.raw_telco
 * Output:      CHURN.clean_telco (cleaned dataset, ready for EDA)
 * Author:      [Your Name]
 * Date:        [Date]
 *****************************************************************************/

/*==========================================================================
  PREPROCESSING DECISION LOG
  
  | # | Issue                    | Decision                     | Rationale                              |
  |---|--------------------------|------------------------------|----------------------------------------|
  | 1 | TotalCharges is CHAR     | Convert to NUMERIC           | Needed for calculations and modeling   |
  | 2 | TotalCharges blanks      | Impute with 0                | These are tenure=0 (new) customers     |
  | 3 | Churn is CHAR (Yes/No)   | Create numeric Churn_Flag    | PROC LOGISTIC needs numeric target     |
  | 4 | SeniorCitizen is 0/1     | Keep as-is                   | Already numeric binary                 |
  | 5 | Category standardization | Trim & upcase first letter   | Ensure consistency                     |
  | 6 | No duplicates found      | No action needed             | Confirmed in quality assessment        |
  | 7 | No impossible values     | No action needed             | Range checks passed                    |
  | 8 | Outliers in charges      | Keep — they are real values  | High charges reflect premium plans     |
==========================================================================*/

/*==========================================================================
  STEP 1: CREATE CLEANED DATASET
  
  This single DATA step applies all cleaning transformations.
  We create a new dataset (clean_telco) rather than modifying the original,
  preserving the raw data for audit purposes.
==========================================================================*/

data CHURN.clean_telco;
    set CHURN.raw_telco;
    
    /*----------------------------------------------------------------------
      FIX 1: Convert TotalCharges from CHARACTER to NUMERIC
      
      DECISION: Use INPUT() function to convert. Blank values will become 
      SAS missing (.). We handle these in Fix 2.
      
      RATIONALE: TotalCharges was imported as character because some values 
      are blank (for tenure=0 customers). We need it as numeric for 
      calculations like Average Revenue Per User and correlation analysis.
    ----------------------------------------------------------------------*/
    TotalCharges_Num = input(TotalCharges, ?? best12.);
    
    /*----------------------------------------------------------------------
      FIX 2: Handle missing TotalCharges (blank → 0 for new customers)
      
      DECISION: Impute 0 for customers with tenure = 0. These are new 
      customers who haven't been billed yet, so $0 total charges is 
      logically correct.
      
      RATIONALE: 
      - These are NOT random missing values — they have a clear business reason
      - Deleting these rows would remove all brand-new customers, biasing 
        the model against detecting early churn
      - Imputing with mean/median would be misleading (a new customer hasn't 
        actually spent the average amount)
      - $0 is the truthful value
    ----------------------------------------------------------------------*/
    if TotalCharges_Num = . then TotalCharges_Num = 0;
    
    /*----------------------------------------------------------------------
      FIX 3: Create numeric Churn target variable (Churn_Flag)
      
      DECISION: Map "Yes" → 1, "No" → 0. Keep original Churn for reference.
      
      RATIONALE: PROC LOGISTIC and other modeling procedures require 
      numeric response variables. The event of interest (churn) is coded 
      as 1 so that the model predicts P(Churn = 1).
    ----------------------------------------------------------------------*/
    if upcase(strip(Churn)) = 'YES' then Churn_Flag = 1;
    else if upcase(strip(Churn)) = 'NO' then Churn_Flag = 0;
    else Churn_Flag = .;  /* Flag unexpected values */
    
    /*----------------------------------------------------------------------
      FIX 4: Standardize categorical variables
      
      DECISION: Strip whitespace and apply proper casing.
      
      RATIONALE: Prevents "Yes" vs "yes" vs " Yes" from being treated 
      as different categories.
    ----------------------------------------------------------------------*/
    gender           = strip(propcase(gender));
    Partner          = strip(propcase(Partner));
    Dependents       = strip(propcase(Dependents));
    PhoneService     = strip(propcase(PhoneService));
    MultipleLines    = strip(propcase(MultipleLines));
    InternetService  = strip(propcase(InternetService));
    OnlineSecurity   = strip(propcase(OnlineSecurity));
    OnlineBackup     = strip(propcase(OnlineBackup));
    DeviceProtection = strip(propcase(DeviceProtection));
    TechSupport      = strip(propcase(TechSupport));
    StreamingTV      = strip(propcase(StreamingTV));
    StreamingMovies  = strip(propcase(StreamingMovies));
    Contract         = strip(Contract);  /* Keep original casing — mixed case is standard */
    PaperlessBilling = strip(propcase(PaperlessBilling));
    PaymentMethod    = strip(PaymentMethod);  /* Keep original — contains proper names */
    
    /*----------------------------------------------------------------------
      FIX 5: Create binary numeric indicators for key categorical variables
      
      DECISION: Create 0/1 numeric versions of binary categorical variables.
      
      RATIONALE: While PROC LOGISTIC can use CLASS statement for categorical 
      variables, having numeric indicators available simplifies EDA, 
      correlation analysis, and feature engineering.
    ----------------------------------------------------------------------*/
    Partner_Flag     = (upcase(strip(Partner))     = 'YES');
    Dependents_Flag  = (upcase(strip(Dependents))  = 'YES');
    PhoneService_Flag = (upcase(strip(PhoneService)) = 'YES');
    PaperlessBilling_Flag = (upcase(strip(PaperlessBilling)) = 'YES');
    
    /*----------------------------------------------------------------------
      LABELS: Add descriptive labels for all new variables
    ----------------------------------------------------------------------*/
    label TotalCharges_Num      = "Total Charges (Numeric, $)"
          Churn_Flag            = "Churn Indicator (1=Churned, 0=Retained)"
          Partner_Flag          = "Has Partner (1=Yes, 0=No)"
          Dependents_Flag       = "Has Dependents (1=Yes, 0=No)"
          PhoneService_Flag     = "Has Phone Service (1=Yes, 0=No)"
          PaperlessBilling_Flag = "Uses Paperless Billing (1=Yes, 0=No)";
    
    /*----------------------------------------------------------------------
      DROP the original character TotalCharges column 
      (we keep TotalCharges_Num as the numeric version)
    ----------------------------------------------------------------------*/
    drop TotalCharges;
    
    /*----------------------------------------------------------------------
      RENAME TotalCharges_Num to TotalCharges for cleaner naming
    ----------------------------------------------------------------------*/
    rename TotalCharges_Num = TotalCharges;
run;

/*==========================================================================
  STEP 2: VALIDATE CLEANING RESULTS
==========================================================================*/

/* 2a. Check new variable types and counts */
proc contents data=CHURN.clean_telco varnum;
    title "Cleaned Dataset — Variable Metadata";
run;

/* 2b. Confirm TotalCharges is now numeric */
proc means data=CHURN.clean_telco n nmiss min mean max;
    title "TotalCharges — Numeric Validation";
    var TotalCharges;
run;

/* 2c. Confirm Churn_Flag is properly coded */
proc freq data=CHURN.clean_telco;
    title "Churn_Flag vs Original Churn — Cross Validation";
    tables Churn * Churn_Flag / missing nocum nopercent;
run;

/* 2d. Confirm no missing values remain in critical variables */
proc means data=CHURN.clean_telco nmiss;
    title "Missing Value Check — Post Cleaning";
    var tenure MonthlyCharges TotalCharges Churn_Flag SeniorCitizen;
run;

/* 2e. Final row count — confirm no rows were lost */
proc sql;
    title "Row Count Comparison";
    select 
        (select count(*) from CHURN.raw_telco) as Raw_Count,
        (select count(*) from CHURN.clean_telco) as Clean_Count,
        calculated Raw_Count - calculated Clean_Count as Rows_Lost;
quit;
/* Expected: 0 rows lost */

/* 2f. Verify standardized categories */
proc freq data=CHURN.clean_telco;
    title "Category Verification — Post Cleaning";
    tables gender Contract InternetService PaymentMethod / missing nocum;
run;

/*==========================================================================
  STEP 3: CREATE ANALYSIS-READY SUMMARY
==========================================================================*/

proc sql;
    title "Cleaned Dataset Summary";
    select 
        count(*) as Total_Customers,
        sum(Churn_Flag) as Churned,
        count(*) - sum(Churn_Flag) as Retained,
        sum(Churn_Flag) / count(*) * 100 as Churn_Rate format=5.1,
        avg(tenure) as Avg_Tenure format=5.1,
        avg(MonthlyCharges) as Avg_Monthly format=6.2,
        avg(TotalCharges) as Avg_Total format=8.2
    from CHURN.clean_telco;
quit;

title;
