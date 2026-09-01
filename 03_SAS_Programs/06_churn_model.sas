/*****************************************************************************
 * Program:     06_churn_model.sas
 * Section:     10 — Churn Prediction Model
 * Purpose:     Build a supervised classification model to predict customer
 *              churn probability. Primary: Logistic Regression.
 *              Comparison: Decision Tree.
 * Input:       CHURN.segmented_telco
 * Output:      CHURN.model_scored (dataset with predicted probabilities)
 *              Model fit statistics and parameter estimates
 * Author:      [Your Name]
 * Date:        [Date]
 *****************************************************************************/

ods graphics on;

/*==========================================================================
  STEP 1: CREATE TRAINING AND VALIDATION SPLIT
  
  WHY: We split the data into training (70%) and validation (30%) to:
  - Train the model on one subset
  - Evaluate performance on unseen data (prevents overfitting)
  - Simulate real-world deployment where the model scores new customers
  
  METHOD: Stratified random sampling ensures both splits have similar
  churn rates (preserves class distribution).
==========================================================================*/

/* Create a random partition variable */
data CHURN.model_data;
    set CHURN.segmented_telco;
    
    /* Set seed for reproducibility */
    call streaminit(42);
    
    /* Stratified split: 70% training, 30% validation */
    rand_num = rand('uniform');
run;

/* Sort by churn status to enable stratified split */
proc sort data=CHURN.model_data; by Churn_Flag; run;

data CHURN.model_data;
    set CHURN.model_data;
    by Churn_Flag;
    
    /* Within each churn group, assign 70% to training */
    if rand_num <= 0.70 then Split = 'TRAIN';
    else Split = 'VALID';
run;

/* Verify the split maintains class balance */
proc freq data=CHURN.model_data;
    title "Train/Validation Split — Churn Distribution";
    tables Split * Churn_Flag / nocum nopercent;
run;

/*==========================================================================
  STEP 2: DEFINE VARIABLES
  
  TARGET VARIABLE:
  - Churn_Flag (1 = Churned, 0 = Retained)
  
  INDEPENDENT VARIABLES (Predictors):
  We select features based on:
  1. EDA findings (significant churn association)
  2. Business domain knowledge
  3. Avoiding multicollinearity (don't include variables that 
     measure the same thing)
  
  Selected predictors:
  - tenure (continuous): Customer relationship length
  - MonthlyCharges (continuous): Monthly revenue / price point
  - Contract (categorical): Commitment level
  - InternetService (categorical): Service type
  - PaymentMethod (categorical): Payment behavior
  - SeniorCitizen (binary): Demographics
  - Partner_Flag (binary): Household composition
  - Dependents_Flag (binary): Household composition
  - PaperlessBilling_Flag (binary): Billing preference
  - Services_Count (continuous): Engagement breadth
  - Auto_Pay (binary): Payment automation
  - Has_Support (binary): Support service adoption
  - Has_Streaming (binary): Entertainment engagement
  - Has_Protection (binary): Security service adoption
  
  EXCLUDED (and why):
  - customerID: Identifier, not a predictor
  - TotalCharges: Highly correlated with tenure × MonthlyCharges
  - Activity_Score: Composite of included variables (would cause collinearity)
  - Tenure_Group, Engagement_Level: Derived from included raw variables
  - Churn (character): Using Churn_Flag instead
  - Individual service variables: Captured in Services_Count and bundle flags
==========================================================================*/

/*==========================================================================
  STEP 3: MODEL 1 — LOGISTIC REGRESSION (PROC LOGISTIC)
  
  WHY LOGISTIC REGRESSION:
  - Interpretable: Produces odds ratios for each variable
  - Probabilistic: Outputs P(Churn) for each customer (0 to 1)
  - Well-understood by business stakeholders
  - Robust with moderate sample sizes
  - Feature selection built-in (stepwise, backward, etc.)
  
  METHOD:
  - Use STEPWISE selection to automatically select significant predictors
  - Model event = Churn_Flag = 1 (we're modeling probability of churn)
  - CLASS statement handles categorical variables automatically
  - SELECTION=STEPWISE with SLENTRY=0.05 and SLSTAY=0.05
==========================================================================*/

/* 3a. Fit logistic regression on TRAINING data */
proc logistic data=CHURN.model_data (where=(Split='TRAIN')) 
              descending  /* Model P(Churn_Flag=1) */
              plots(only)=(roc effect oddsratio);
    
    /* Declare categorical variables */
    class Contract (ref='Two year') 
          InternetService (ref='No') 
          PaymentMethod (ref='Credit card (automatic)') 
          / param=ref;
    
    /* Model specification with stepwise selection */
    model Churn_Flag = 
        tenure 
        MonthlyCharges 
        Contract 
        InternetService 
        PaymentMethod 
        SeniorCitizen 
        Partner_Flag 
        Dependents_Flag 
        PaperlessBilling_Flag 
        Services_Count
        Auto_Pay
        Has_Support
        Has_Streaming
        Has_Protection
        / selection=stepwise 
          slentry=0.05 
          slstay=0.05
          lackfit         /* Hosmer-Lemeshow goodness of fit */
          rsquare         /* R-squared statistics */
          ctable          /* Classification table */
          stb             /* Standardized estimates */
          corrb           /* Correlation of estimates */
          influence;      /* Influence diagnostics */
    
    /* Score BOTH training and validation data */
    score data=CHURN.model_data 
          out=CHURN.logistic_scored 
          fitstat;
    
    /* Store model for later use */
    store CHURN.logistic_model;
    
    /* ROC curve analysis */
    roc;
    
    title "Model 1: Logistic Regression — Churn Prediction";
run;

/*
  HOW TO READ THE OUTPUT:
  
  1. PARAMETER ESTIMATES TABLE:
     - Estimate: Direction and magnitude of effect
     - Odds Ratio: How much the odds of churn change per unit increase
       > 1 means increases churn risk, < 1 means decreases churn risk
     - Pr > ChiSq: p-value; < 0.05 means statistically significant
  
  2. MODEL FIT STATISTICS:
     - AIC, BIC: Lower is better (penalizes model complexity)
     - c-statistic: Same as ROC-AUC (0.5 = random, 1.0 = perfect)
     - Hosmer-Lemeshow: p > 0.05 means adequate fit
  
  3. STEPWISE SELECTION:
     - Shows which variables entered/stayed in the model
     - Variables not selected are not significant predictors
     - This IS the feature selection process
  
  4. CLASSIFICATION TABLE:
     - Shows accuracy at various probability cutoffs
     - Default cutoff is 0.5, but optimal may differ
*/

/*==========================================================================
  STEP 4: MODEL 2 — DECISION TREE (PROC HPSPLIT)
  
  WHY COMPARE:
  - Decision trees capture non-linear relationships and interactions
  - Highly interpretable (visual tree structure)
  - No assumption about variable distributions
  - Can identify interaction effects logistic regression might miss
  
  NOTE: PROC HPSPLIT requires SAS 9.4M5+ or SAS Viya. If unavailable,
  use PROC HPFOREST (random forest) or skip this comparison.
==========================================================================*/

proc hpsplit data=CHURN.model_data (where=(Split='TRAIN'))
             maxdepth=5          /* Prevent overfitting */
             mincatsize=50       /* Minimum leaf size */
             plots=all;          /* Generate all diagnostic plots */
    
    class Contract InternetService PaymentMethod Churn_Flag;
    
    model Churn_Flag (event='1') = 
        tenure 
        MonthlyCharges 
        Contract 
        InternetService 
        PaymentMethod 
        SeniorCitizen 
        Partner_Flag 
        Dependents_Flag 
        PaperlessBilling_Flag 
        Services_Count
        Auto_Pay
        Has_Support
        Has_Streaming
        Has_Protection;
    
    /* Pruning to find optimal tree complexity */
    prune costcomplexity;
    
    /* Variable importance */
    partition fraction(validate=0.3);
    
    /* Score validation data */
    score data=CHURN.model_data 
          out=CHURN.tree_scored;
    
    title "Model 2: Decision Tree — Churn Prediction";
run;

/*==========================================================================
  STEP 5: CREATE FINAL SCORED DATASET
  
  Merge logistic regression predictions with original data.
  The key output columns are:
  - P_1: Predicted probability of churn (from logistic regression)
  - F_Churn_Flag: Predicted class (0 or 1)
==========================================================================*/

/* Rename prediction columns for clarity */
data CHURN.model_scored;
    set CHURN.logistic_scored;
    
    /* P_1 = Predicted probability of Churn=1 */
    Churn_Probability = P_1;
    
    /* Create predicted class at 0.5 threshold (adjust later in risk scoring) */
    if Churn_Probability >= 0.5 then Predicted_Churn = 1;
    else Predicted_Churn = 0;
    
    label Churn_Probability = "Predicted Probability of Churn"
          Predicted_Churn   = "Predicted Churn (1=Yes, 0=No)";
    
    keep customerID Churn Churn_Flag Churn_Probability Predicted_Churn
         Split tenure MonthlyCharges TotalCharges Contract InternetService 
         PaymentMethod Services_Count Activity_Score Segment_ID Segment_Name
         Tenure_Group Value_Tier Auto_Pay Has_Support Has_Streaming
         SeniorCitizen Partner_Flag Dependents_Flag PaperlessBilling_Flag
         Has_Protection P_0 P_1;
run;

/* Quick check of predictions */
proc means data=CHURN.model_scored mean std min max;
    title "Churn Probability Distribution";
    class Split;
    var Churn_Probability;
run;

proc sgplot data=CHURN.model_scored;
    title "Distribution of Predicted Churn Probabilities";
    histogram Churn_Probability / binwidth=0.05 group=Churn 
              transparency=0.3;
    xaxis label="Predicted Churn Probability";
    yaxis label="Count";
run;

ods graphics off;
title;
