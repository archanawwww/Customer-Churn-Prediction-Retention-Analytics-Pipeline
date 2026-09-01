/*****************************************************************************
 * Program:     10_dashboard.sas
 * Section:     14 — KPI Dashboard
 * Purpose:     Generate a consolidated dashboard report for product managers
 *              to monitor churn KPIs, risk segments, and model performance.
 * Input:       CHURN.risk_scored, CHURN.model_scored (validation set)
 * Output:      ODS HTML/PDF dashboard
 * Author:      [Your Name]
 * Date:        [Date]
 *****************************************************************************/

/* Configure ODS for an HTML dashboard layout */
ods html body="&project_path./Output/Churn_KPI_Dashboard.html" 
         style=Illuminate 
         options(doc="html5");
ods graphics on / width=600px height=400px;

title1 "Executive Churn & Retention Dashboard";
title2 "Based on Validation Data";

/*==========================================================================
  KPI 1: OVERALL CHURN & RETENTION RATES
  WHAT IT TELLS A PM: The baseline health of the business. Are we bleeding
  customers, or are we retaining them? This is the ultimate North Star metric.
==========================================================================*/

proc sql;
    title3 "1. Top-Line Metrics";
    select 
        count(*) as Total_Active_Base,
        sum(Churn_Flag) as Churned_Customers,
        count(*) - sum(Churn_Flag) as Retained_Customers,
        sum(Churn_Flag) / count(*) * 100 as Churn_Rate_Pct format=5.1,
        (count(*) - sum(Churn_Flag)) / count(*) * 100 as Retention_Rate_Pct format=5.1,
        sum(case when Risk_Level='High Risk' then 1 else 0 end) as High_Risk_Count
    from CHURN.risk_scored
    where Split = 'VALID';
quit;

/*==========================================================================
  KPI 2: CHURN BY SEGMENT
  WHAT IT TELLS A PM: Which customer cohorts are driving the churn rate.
  Helps allocate retention resources (focus on high-value, high-churn).
==========================================================================*/

title3 "2. Churn by Customer Segment";
proc sgplot data=CHURN.risk_scored (where=(Split='VALID'));
    vbar Segment_Name / response=Churn_Flag stat=mean 
         datalabel datalabelfitpolicy=none
         categoryorder=respdesc;
    xaxis label="Customer Segment";
    yaxis label="Churn Rate" values=(0 to 1 by 0.1);
run;

/*==========================================================================
  KPI 3: CHURN BY TENURE
  WHAT IT TELLS A PM: Whether the problem is onboarding/early-life (new 
  customers) or value-delivery over time (established customers).
==========================================================================*/

title3 "3. Churn by Tenure Lifecycle";
proc sgplot data=CHURN.risk_scored (where=(Split='VALID'));
    vbar Tenure_Group / response=Churn_Flag stat=mean 
         datalabel;
    xaxis label="Lifecycle Stage";
    yaxis label="Churn Rate" values=(0 to 1 by 0.1);
run;

/*==========================================================================
  KPI 4: CHURN BY ENGAGEMENT
  WHAT IT TELLS A PM: Validation that product adoption drives retention.
  If low engagement = high churn, the product mandate is to increase usage.
==========================================================================*/

title3 "4. Churn by Engagement Level";
proc sgplot data=CHURN.risk_scored (where=(Split='VALID'));
    vbar Engagement_Level / response=Churn_Flag stat=mean 
         datalabel;
    xaxis label="Engagement Level";
    yaxis label="Churn Rate" values=(0 to 1 by 0.1);
run;

/*==========================================================================
  KPI 5: MODEL PERFORMANCE TRACKING
  WHAT IT TELLS A PM: Can we trust this model to target interventions?
  If precision is too low, we waste money. If recall is too low, we miss
  revenue. If ROC-AUC drops over time, the model is degrading.
==========================================================================*/

proc sql;
    title3 "5. Model Performance Metrics (at 0.3 threshold)";
    select 
        /* Assuming 0.3 threshold from Section 11 */
        sum(case when Churn_Flag=1 and Churn_Probability >= 0.3 then 1 else 0 end) as TP,
        sum(case when Churn_Flag=0 and Churn_Probability >= 0.3 then 1 else 0 end) as FP,
        sum(case when Churn_Flag=1 and Churn_Probability <  0.3 then 1 else 0 end) as FN,
        
        calculated TP / (calculated TP + calculated FP) * 100 
            as Precision format=5.1 label="Precision (%)",
            
        calculated TP / (calculated TP + calculated FN) * 100 
            as Recall format=5.1 label="Recall (%)"
            
    from CHURN.model_scored
    where Split = 'VALID';
quit;

/*==========================================================================
  KPI 6: RISK PIPELINE
  WHAT IT TELLS A PM: How many customers need intervention right now,
  and how much revenue is associated with them.
==========================================================================*/

title3 "6. Current Risk Pipeline";
proc sql;
    select 
        Risk_Level,
        count(*) as Customer_Count,
        sum(MonthlyCharges) as Revenue_At_Risk format=dollar10.2
    from CHURN.risk_scored
    where Split = 'VALID'
    group by Risk_Level
    order by Risk_Level;
quit;

/* Close ODS */
ods html close;
ods graphics off;
title;
