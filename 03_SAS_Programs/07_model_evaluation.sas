/*****************************************************************************
 * Program:     07_model_evaluation.sas
 * Section:     11 — Model Evaluation
 * Purpose:     Evaluate the churn prediction model using appropriate
 *              classification metrics. Focus on VALIDATION set performance.
 * Input:       CHURN.model_scored
 * Output:      Evaluation metrics, confusion matrix, ROC curve
 * Author:      [Your Name]
 * Date:        [Date]
 *
 * KEY PRINCIPLE: All metrics should be evaluated on the VALIDATION set
 * (Split = 'VALID'), not the training set, to measure generalization.
 *****************************************************************************/

ods graphics on;

/*==========================================================================
  STEP 1: CONFUSION MATRIX
  
  The confusion matrix compares actual vs. predicted churn:
  
                          PREDICTED
                       No Churn | Churn
  ACTUAL   No Churn |    TN    |  FP    |
           Churn    |    FN    |  TP    |
  
  TN = True Negative:  Correctly predicted no churn
  FP = False Positive: Predicted churn but didn't churn (unnecessary intervention)
  FN = False Negative: Predicted no churn but actually churned (MISSED CHURN)
  TP = True Positive:  Correctly predicted churn
==========================================================================*/

/* 1a. Confusion matrix at default 0.5 threshold */
proc freq data=CHURN.model_scored (where=(Split='VALID'));
    title "Confusion Matrix — Validation Set (Threshold = 0.5)";
    tables Churn_Flag * Predicted_Churn / 
           norow nocol nopercent 
           senspec chisq;
run;

/*==========================================================================
  STEP 2: CALCULATE ALL CLASSIFICATION METRICS
  
  Using PROC SQL to compute metrics manually from the confusion matrix.
  This ensures you understand how each metric is calculated.
==========================================================================*/

proc sql;
    title "Classification Metrics — Validation Set";
    select
        /* Confusion matrix components */
        sum(case when Churn_Flag=0 and Predicted_Churn=0 then 1 else 0 end) as TN,
        sum(case when Churn_Flag=0 and Predicted_Churn=1 then 1 else 0 end) as FP,
        sum(case when Churn_Flag=1 and Predicted_Churn=0 then 1 else 0 end) as FN,
        sum(case when Churn_Flag=1 and Predicted_Churn=1 then 1 else 0 end) as TP,
        
        /* Total */
        count(*) as Total,
        
        /* ACCURACY: (TP + TN) / Total */
        /* What % of all predictions were correct? */
        (calculated TP + calculated TN) / calculated Total * 100 
            as Accuracy format=5.1 label="Accuracy (%)",
        
        /* PRECISION: TP / (TP + FP) */
        /* Of those we flagged as churners, what % actually churned? */
        /* High precision = fewer wasted interventions */
        calculated TP / (calculated TP + calculated FP) * 100 
            as Precision format=5.1 label="Precision (%)",
        
        /* RECALL (Sensitivity): TP / (TP + FN) */
        /* Of actual churners, what % did we catch? */
        /* High recall = fewer missed churners */
        calculated TP / (calculated TP + calculated FN) * 100 
            as Recall format=5.1 label="Recall / Sensitivity (%)",
        
        /* SPECIFICITY: TN / (TN + FP) */
        /* Of actual non-churners, what % did we correctly identify? */
        calculated TN / (calculated TN + calculated FP) * 100 
            as Specificity format=5.1 label="Specificity (%)",
        
        /* F1-SCORE: 2 × (Precision × Recall) / (Precision + Recall) */
        /* Harmonic mean of precision and recall */
        2 * (calculated Precision/100 * calculated Recall/100) / 
            (calculated Precision/100 + calculated Recall/100) * 100
            as F1_Score format=5.1 label="F1 Score (%)"
        
    from CHURN.model_scored
    where Split = 'VALID';
quit;

/*==========================================================================
  STEP 3: ROC CURVE AND AUC
  
  ROC-AUC measures the model's ability to discriminate between churners
  and non-churners across ALL possible thresholds.
  
  - AUC = 0.5: No better than random guessing
  - AUC = 0.7-0.8: Acceptable discrimination
  - AUC = 0.8-0.9: Excellent discrimination
  - AUC > 0.9: Outstanding (check for data leakage)
==========================================================================*/

/* Re-run logistic regression to get ROC on validation data */
proc logistic data=CHURN.model_scored (where=(Split='VALID')) 
              descending
              plots(only)=(roc);
    model Churn_Flag = Churn_Probability;
    roc;
    title "ROC Curve — Validation Set";
run;

/* Alternative: Manual ROC computation using PROC LOGISTIC score output */
proc logistic data=CHURN.model_data (where=(Split='TRAIN'))
              descending
              noprint;
    class Contract (ref='Two year') 
          InternetService (ref='No') 
          PaymentMethod (ref='Credit card (automatic)') 
          / param=ref;
    model Churn_Flag = 
        tenure MonthlyCharges Contract InternetService PaymentMethod 
        SeniorCitizen Partner_Flag Dependents_Flag PaperlessBilling_Flag 
        Services_Count Auto_Pay Has_Support Has_Streaming Has_Protection
        / selection=stepwise slentry=0.05 slstay=0.05;
    
    /* Score validation set and compute ROC */
    score data=CHURN.model_data (where=(Split='VALID'))
          out=_roc_scored 
          fitstat;
    roc;
    ods output ROCAssociation=_roc_auc;
run;

/* Display AUC */
proc print data=_roc_auc;
    title "ROC-AUC — Validation Set";
run;

/*==========================================================================
  STEP 4: WHY RECALL IS PARTICULARLY IMPORTANT FOR CHURN
  
  In churn prediction, the cost of errors is ASYMMETRIC:
  
  | Error Type       | Business Consequence                    | Cost    |
  |------------------|-----------------------------------------|---------|
  | False Negative   | Missed a churner → customer leaves      | HIGH    |
  |  (FN)            | Revenue lost + acquisition cost to      |         |
  |                  | replace them                            |         |
  | False Positive   | Flagged a non-churner → unnecessary     | LOW     |
  |  (FP)            | retention outreach (email, call, offer) |         |
  
  WHY THIS MATTERS:
  - Missing a churner (FN) costs the company the customer's lifetime value
    (potentially $1,000+ per customer per year)
  - Reaching out to a non-churner (FP) costs a phone call or email 
    (~$5-20 per contact) and might even strengthen the relationship
  
  THEREFORE:
  - RECALL is more important than precision for churn prediction
  - We'd rather flag 100 customers (and have 30 false alarms) than
    miss 30 actual churners to avoid those false alarms
  - The ideal threshold should be LOWER than 0.5 (e.g., 0.3-0.4)
    to catch more actual churners at the cost of more false positives
  
  This trade-off should be calibrated based on:
  1. Cost of intervention per customer
  2. Average revenue per customer per year
  3. Retention success rate (what % of flagged customers are actually saved)
==========================================================================*/

/*==========================================================================
  STEP 5: EVALUATE AT MULTIPLE THRESHOLDS
  
  Helps identify the optimal operating point for the business.
==========================================================================*/

%macro evaluate_threshold(threshold);
    proc sql noprint;
        select
            &threshold as Threshold,
            sum(case when Churn_Flag=1 and Churn_Probability >= &threshold then 1 else 0 end) as TP,
            sum(case when Churn_Flag=0 and Churn_Probability >= &threshold then 1 else 0 end) as FP,
            sum(case when Churn_Flag=1 and Churn_Probability <  &threshold then 1 else 0 end) as FN,
            sum(case when Churn_Flag=0 and Churn_Probability <  &threshold then 1 else 0 end) as TN,
            calculated TP / (calculated TP + calculated FN) * 100 as Recall format=5.1,
            calculated TP / (calculated TP + calculated FP) * 100 as Precision format=5.1,
            2*(calculated Recall/100 * calculated Precision/100) / 
              (calculated Recall/100 + calculated Precision/100) * 100 as F1 format=5.1,
            (calculated TP + calculated TN) / count(*) * 100 as Accuracy format=5.1
        from CHURN.model_scored
        where Split = 'VALID';
    quit;
%mend;

title "Performance at Different Probability Thresholds — Validation Set";
%evaluate_threshold(0.3);
%evaluate_threshold(0.4);
%evaluate_threshold(0.5);
%evaluate_threshold(0.6);

/*==========================================================================
  STEP 6: GAINS AND LIFT CHARTS
  
  Shows how much better the model performs compared to random selection.
  A good model should capture most churners in the top deciles.
==========================================================================*/

/* Create decile ranks */
proc rank data=CHURN.model_scored (where=(Split='VALID')) 
          out=_decile_data groups=10 descending;
    var Churn_Probability;
    ranks Decile;
run;

proc sql;
    title "Cumulative Gains by Decile — Validation Set";
    select 
        Decile + 1 as Decile_Rank,
        count(*) as Customers,
        sum(Churn_Flag) as Churners_Captured,
        avg(Churn_Probability) as Avg_Predicted_Prob format=5.3,
        avg(Churn_Flag) as Actual_Churn_Rate format=5.3
    from _decile_data
    group by Decile
    order by Decile;
quit;

/* Clean up */
proc delete data=_roc_scored _roc_auc _decile_data; run;

ods graphics off;
title;
