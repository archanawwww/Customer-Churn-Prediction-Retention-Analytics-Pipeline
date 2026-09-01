/*****************************************************************************
 * Program:     08_risk_scoring.sas
 * Section:     12 — Customer Risk Scoring
 * Purpose:     Convert predicted churn probabilities into actionable risk
 *              categories and create a customer risk report.
 * Input:       CHURN.model_scored
 * Output:      CHURN.risk_scored (with risk levels and key drivers)
 * Author:      [Your Name]
 * Date:        [Date]
 *****************************************************************************/

/*==========================================================================
  STEP 1: DEFINE RISK THRESHOLDS
  
  HOW THRESHOLDS SHOULD BE SELECTED:
  
  Thresholds should NOT be arbitrary. They should be based on:
  
  1. BUSINESS COST ANALYSIS:
     - Cost of intervention per customer (e.g., $20 for an email + call)
     - Average revenue per customer per year (e.g., $1,200)
     - Expected save rate for each risk tier
     - Break-even: If intervention costs $20 and saves $100/month,
       even a 20% save rate is profitable
  
  2. CAPACITY CONSTRAINTS:
     - How many customers can the retention team contact per week?
     - If team can handle 200/week, set "High Risk" threshold so that
       roughly 200 customers fall in that tier
  
  3. MODEL PERFORMANCE:
     - Review the precision-recall trade-off at different thresholds
       (from 07_model_evaluation.sas)
     - Choose thresholds that balance catching churners (recall) vs.
       not overwhelming the team with false positives (precision)
  
  RECOMMENDED STARTING POINT (adjust after business review):
  - High Risk:   P(Churn) >= 0.6  → Immediate intervention
  - Medium Risk: P(Churn) >= 0.3  → Proactive monitoring / nurture
  - Low Risk:    P(Churn) < 0.3   → Standard operations
  
  IMPORTANT: These thresholds should be reviewed monthly and adjusted
  based on actual intervention outcomes.
==========================================================================*/

%let high_threshold = 0.6;
%let med_threshold  = 0.3;

data CHURN.risk_scored;
    set CHURN.model_scored;
    
    /* Assign risk categories */
    length Risk_Level $12;
    if Churn_Probability >= &high_threshold then Risk_Level = 'High Risk';
    else if Churn_Probability >= &med_threshold then Risk_Level = 'Medium Risk';
    else Risk_Level = 'Low Risk';
    
    /* Numeric risk score (1-100 scale for easier communication) */
    Risk_Score = round(Churn_Probability * 100, 1);
    
    /*==================================================================
      STEP 2: IDENTIFY KEY RISK DRIVERS PER CUSTOMER
      
      For each customer, identify which factors contribute most to
      their churn risk. This uses a rule-based approach derived from
      the model's significant predictors.
      
      WHY: A customer service rep needs to know WHY a customer is 
      at risk, not just THAT they're at risk. "High risk because
      month-to-month contract and no tech support" is actionable.
      "High risk score: 78" is not.
    ==================================================================*/
    length Key_Risk_Drivers $200;
    Key_Risk_Drivers = '';
    
    /* Driver 1: Short tenure */
    if tenure <= 12 then 
        Key_Risk_Drivers = catx('; ', Key_Risk_Drivers, 'New customer (<12 months)');
    
    /* Driver 2: Month-to-month contract */
    if Contract = 'Month-to-month' then 
        Key_Risk_Drivers = catx('; ', Key_Risk_Drivers, 'Month-to-month contract');
    
    /* Driver 3: High monthly charges */
    if MonthlyCharges >= 70 then 
        Key_Risk_Drivers = catx('; ', Key_Risk_Drivers, 'High monthly charges');
    
    /* Driver 4: No support services */
    if Has_Support = 0 then 
        Key_Risk_Drivers = catx('; ', Key_Risk_Drivers, 'No tech support or security');
    
    /* Driver 5: Non-automatic payment */
    if Auto_Pay = 0 then 
        Key_Risk_Drivers = catx('; ', Key_Risk_Drivers, 'Manual payment method');
    
    /* Driver 6: Low engagement */
    if Services_Count <= 2 then 
        Key_Risk_Drivers = catx('; ', Key_Risk_Drivers, 'Low service adoption');
    
    /* Driver 7: Fiber optic (if applicable) */
    if InternetService = 'Fiber optic' then 
        Key_Risk_Drivers = catx('; ', Key_Risk_Drivers, 'Fiber optic service');
    
    /* Driver 8: No streaming (low engagement signal) */
    if Has_Streaming = 0 and InternetService not in ('No') then 
        Key_Risk_Drivers = catx('; ', Key_Risk_Drivers, 'No streaming services');
    
    /* Count number of risk drivers */
    Risk_Driver_Count = countc(Key_Risk_Drivers, ';') + 
                        (Key_Risk_Drivers ne '');
    
    /* Default for customers with no identified drivers */
    if Key_Risk_Drivers = '' then Key_Risk_Drivers = 'No specific risk drivers identified';
    
    label Risk_Level        = "Churn Risk Category"
          Risk_Score        = "Churn Risk Score (0-100)"
          Key_Risk_Drivers  = "Primary Risk Factors"
          Risk_Driver_Count = "Number of Risk Factors";
run;

/*==========================================================================
  STEP 3: RISK DISTRIBUTION SUMMARY
==========================================================================*/

proc freq data=CHURN.risk_scored;
    title "Risk Level Distribution";
    tables Risk_Level / nocum;
run;

proc sql;
    title "Risk Level Summary — Counts, Revenue, and Actual Churn";
    select 
        Risk_Level,
        count(*) as Customers,
        avg(Risk_Score) as Avg_Risk_Score format=5.1,
        avg(MonthlyCharges) as Avg_Monthly format=6.2,
        sum(MonthlyCharges) as Total_Monthly_Revenue format=10.2,
        avg(Churn_Flag) * 100 as Actual_Churn_Rate format=5.1,
        avg(Risk_Driver_Count) as Avg_Risk_Drivers format=4.1
    from CHURN.risk_scored
    group by Risk_Level
    order by Risk_Level;
quit;

/*==========================================================================
  STEP 4: EXAMPLE CUSTOMER RISK REPORT
  
  OUTPUT FORMAT:
  Customer ID | Churn Probability | Risk Level | Segment | Key Risk Drivers
  
  This is the table that would be exported to the CRM or used by 
  Customer Success Managers for daily outreach.
==========================================================================*/

/* Top 20 highest-risk customers */
proc sql outobs=20;
    title "Top 20 Highest-Risk Customers";
    select 
        customerID                          as Customer_ID,
        Churn_Probability format=5.3        as Churn_Prob,
        Risk_Level,
        Segment_Name                        as Segment,
        tenure                              as Tenure_Months,
        MonthlyCharges format=6.2           as Monthly_Revenue,
        Contract,
        Key_Risk_Drivers
    from CHURN.risk_scored
    where Split = 'VALID'  /* Show validation set examples */
    order by Churn_Probability desc;
quit;

/* Risk report for ALL high-risk customers */
proc sql;
    title "Full High-Risk Customer List (for CRM Export)";
    select 
        customerID,
        Churn_Probability format=5.3,
        Risk_Score,
        Risk_Level,
        Segment_Name,
        Contract,
        tenure,
        MonthlyCharges format=6.2,
        Services_Count,
        Key_Risk_Drivers
    from CHURN.risk_scored
    where Risk_Level = 'High Risk'
    order by Churn_Probability desc;
quit;

/*==========================================================================
  STEP 5: EXPORT RISK REPORT FOR STAKEHOLDERS
  
  Create a CSV export that can be loaded into CRM, shared with CS team,
  or used in presentations.
==========================================================================*/

proc export data=CHURN.risk_scored 
            outfile="&project_path./Output/customer_risk_report.csv"
            dbms=csv 
            replace;
run;

/* Revenue at risk */
proc sql;
    title "Monthly Revenue at Risk by Risk Level";
    select 
        Risk_Level,
        count(*) as Customers,
        sum(MonthlyCharges) as Monthly_Revenue_At_Risk format=dollar10.2,
        sum(MonthlyCharges) * 12 as Annual_Revenue_At_Risk format=dollar12.2
    from CHURN.risk_scored
    where Risk_Level in ('High Risk', 'Medium Risk')
    group by Risk_Level;
quit;

title;
