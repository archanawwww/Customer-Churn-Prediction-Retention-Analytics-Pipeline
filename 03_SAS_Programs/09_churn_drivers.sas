/*****************************************************************************
 * Program:     09_churn_drivers.sas
 * Section:     13 — Churn-Driver Analysis
 * Purpose:     Identify which variables contribute most to churn and
 *              translate statistical outputs into product insights.
 * Input:       CHURN.risk_scored, CHURN.model_data
 * Output:      Churn driver analysis report
 * Author:      [Your Name]
 * Date:        [Date]
 *
 * KEY PRINCIPLE: Clearly distinguish CORRELATION from CAUSATION.
 * The model identifies statistical associations, not causal relationships.
 *****************************************************************************/

/*==========================================================================
  STEP 1: MODEL-BASED VARIABLE IMPORTANCE
  
  Extract feature importance from the logistic regression model.
  Variables with larger absolute standardized estimates have more 
  influence on the prediction.
==========================================================================*/

/* Re-fit model to capture parameter estimates */
proc logistic data=CHURN.model_data (where=(Split='TRAIN'))
              descending
              outest=_param_estimates;
    class Contract (ref='Two year') 
          InternetService (ref='No') 
          PaymentMethod (ref='Credit card (automatic)') 
          / param=ref;
    model Churn_Flag = 
        tenure MonthlyCharges Contract InternetService PaymentMethod 
        SeniorCitizen Partner_Flag Dependents_Flag PaperlessBilling_Flag 
        Services_Count Auto_Pay Has_Support Has_Streaming Has_Protection
        / selection=stepwise slentry=0.05 slstay=0.05 stb;
    
    /* Capture odds ratios */
    ods output OddsRatios=_odds_ratios;
    ods output ParameterEstimates=_param_est;
    
    title "Logistic Regression — Parameter Estimates and Odds Ratios";
run;

/* Display odds ratios (key for business interpretation) */
proc print data=_odds_ratios;
    title "Odds Ratios — Churn Drivers";
run;

/* Display parameter estimates with standardized values */
proc print data=_param_est;
    title "Parameter Estimates — Significance and Direction";
run;

/*==========================================================================
  STEP 2: STATISTICAL IMPORTANCE VS. BUSINESS IMPACT
  
  Statistical significance tells us a variable IS associated with churn.
  Business impact tells us HOW MUCH fixing it would matter.
  
  We combine both to rank churn drivers.
==========================================================================*/

proc sql;
    title "Churn Driver Impact Analysis";
    
    /* Contract type impact */
    select 'Contract Type' as Driver,
        sum(case when Contract='Month-to-month' and Churn_Flag=1 then 1 else 0 end) 
            as Churners_Affected,
        sum(case when Contract='Month-to-month' and Churn_Flag=1 then MonthlyCharges else 0 end) 
            as Monthly_Revenue_Lost format=dollar10.2,
        sum(case when Contract='Month-to-month' then Churn_Flag else 0 end) / 
            sum(case when Contract='Month-to-month' then 1 else 0 end) * 100 
            as Churn_Rate_This_Group format=5.1
    from CHURN.risk_scored;
    
    /* Tenure impact */
    select 'Short Tenure (<12m)' as Driver,
        sum(case when tenure<=12 and Churn_Flag=1 then 1 else 0 end) 
            as Churners_Affected,
        sum(case when tenure<=12 and Churn_Flag=1 then MonthlyCharges else 0 end) 
            as Monthly_Revenue_Lost format=dollar10.2,
        sum(case when tenure<=12 then Churn_Flag else 0 end) / 
            sum(case when tenure<=12 then 1 else 0 end) * 100 
            as Churn_Rate_This_Group format=5.1
    from CHURN.risk_scored;
    
    /* No support services */
    select 'No Support Services' as Driver,
        sum(case when Has_Support=0 and Churn_Flag=1 then 1 else 0 end) 
            as Churners_Affected,
        sum(case when Has_Support=0 and Churn_Flag=1 then MonthlyCharges else 0 end) 
            as Monthly_Revenue_Lost format=dollar10.2,
        sum(case when Has_Support=0 then Churn_Flag else 0 end) / 
            sum(case when Has_Support=0 then 1 else 0 end) * 100 
            as Churn_Rate_This_Group format=5.1
    from CHURN.risk_scored;
    
    /* Manual payment */
    select 'Manual Payment' as Driver,
        sum(case when Auto_Pay=0 and Churn_Flag=1 then 1 else 0 end) 
            as Churners_Affected,
        sum(case when Auto_Pay=0 and Churn_Flag=1 then MonthlyCharges else 0 end) 
            as Monthly_Revenue_Lost format=dollar10.2,
        sum(case when Auto_Pay=0 then Churn_Flag else 0 end) / 
            sum(case when Auto_Pay=0 then 1 else 0 end) * 100 
            as Churn_Rate_This_Group format=5.1
    from CHURN.risk_scored;
    
    /* Low engagement */
    select 'Low Engagement (<=2 services)' as Driver,
        sum(case when Services_Count<=2 and Churn_Flag=1 then 1 else 0 end) 
            as Churners_Affected,
        sum(case when Services_Count<=2 and Churn_Flag=1 then MonthlyCharges else 0 end) 
            as Monthly_Revenue_Lost format=dollar10.2,
        sum(case when Services_Count<=2 then Churn_Flag else 0 end) / 
            sum(case when Services_Count<=2 then 1 else 0 end) * 100 
            as Churn_Rate_This_Group format=5.1
    from CHURN.risk_scored;
    
    /* Fiber optic */
    select 'Fiber Optic Service' as Driver,
        sum(case when InternetService='Fiber optic' and Churn_Flag=1 then 1 else 0 end) 
            as Churners_Affected,
        sum(case when InternetService='Fiber optic' and Churn_Flag=1 then MonthlyCharges else 0 end) 
            as Monthly_Revenue_Lost format=dollar10.2,
        sum(case when InternetService='Fiber optic' then Churn_Flag else 0 end) / 
            sum(case when InternetService='Fiber optic' then 1 else 0 end) * 100 
            as Churn_Rate_This_Group format=5.1
    from CHURN.risk_scored;
quit;

/*==========================================================================
  STEP 3: TRANSLATE STATISTICAL OUTPUTS INTO PRODUCT INSIGHTS
  
  The model outputs (odds ratios, coefficients, p-values) must be 
  translated into language that product managers can act on.
  
  STATISTICAL FINDING → PRODUCT INSIGHT → POSSIBLE ROOT CAUSE
  
  ┌─────────────────────────────────────────────────────────────────────┐
  │ 1. Month-to-month contract → high churn odds ratio                │
  │    Product Insight: Lack of commitment structure                   │
  │    Possible Root Cause: CONTRACT FRICTION                         │
  │    - Customers don't see enough value for long-term commitment    │
  │    - Annual pricing may not be compelling enough                  │
  │    - Customers may not be offered upgrade at the right moment     │
  ├─────────────────────────────────────────────────────────────────────┤
  │ 2. Low tenure → high churn probability                            │
  │    Product Insight: Weak early customer experience                │
  │    Possible Root Cause: POOR ONBOARDING                          │
  │    - Product doesn't deliver value quickly enough                 │
  │    - Setup is complex or confusing                                │
  │    - No guided first-use experience                               │
  ├─────────────────────────────────────────────────────────────────────┤
  │ 3. Few services adopted → higher churn                            │
  │    Product Insight: Low product stickiness                        │
  │    Possible Root Cause: LOW ENGAGEMENT / FEATURE ADOPTION         │
  │    - Customers don't discover available features                  │
  │    - Cross-sell opportunities are missed                          │
  │    - Feature value isn't communicated effectively                 │
  ├─────────────────────────────────────────────────────────────────────┤
  │ 4. No tech support / security → higher churn                      │
  │    Product Insight: Customers feel unsupported                    │
  │    Possible Root Cause: SUPPORT PROBLEMS                          │
  │    - Support services are seen as "nice to have" not essential    │
  │    - Customers who need help can't get it without paying extra    │
  │    - First issue without support → frustration → churn            │
  ├─────────────────────────────────────────────────────────────────────┤
  │ 5. High monthly charges → higher churn                            │
  │    Product Insight: Price-value perception gap                    │
  │    Possible Root Cause: PRICING CONCERNS                          │
  │    - Customers don't perceive enough value for the price          │
  │    - Competitors may offer similar service for less               │
  │    - Price increases without corresponding value increases        │
  ├─────────────────────────────────────────────────────────────────────┤
  │ 6. Electronic check payment → higher churn                        │
  │    Product Insight: Billing friction creates churn opportunity    │
  │    Possible Root Cause: PAYMENT BEHAVIOR                          │
  │    - Non-automatic payment = monthly decision point               │
  │    - Payment friction increases chance of lapse                   │
  │    - Manual payers may be less committed customers overall        │
  └─────────────────────────────────────────────────────────────────────┘
  
  CRITICAL DISTINCTION — CORRELATION vs. CAUSATION:
  
  The model tells us that these variables are ASSOCIATED with churn.
  It does NOT prove they CAUSE churn. For example:
  
  - "Customers with no tech support churn more" does NOT mean 
    "giving everyone free tech support will reduce churn"
  - It might be that customers who don't buy tech support are 
    inherently less committed, and giving them free support 
    won't change their behavior
  - The only way to establish causation is through EXPERIMENTATION
    (A/B testing — see Section 17)
  
  The churn drivers should be treated as HYPOTHESES to be validated,
  not as proven causes to act on without testing.
==========================================================================*/

/* Most common risk driver combinations for churners */
proc sql;
    title "Most Common Risk Driver Combinations — Churned Customers";
    select 
        Key_Risk_Drivers,
        count(*) as Frequency,
        avg(Churn_Probability) as Avg_Churn_Prob format=5.3
    from CHURN.risk_scored
    where Churn_Flag = 1
    group by Key_Risk_Drivers
    having count(*) >= 10
    order by Frequency desc;
quit;

/* Clean up */
proc delete data=_param_estimates _odds_ratios _param_est; run;

title;
