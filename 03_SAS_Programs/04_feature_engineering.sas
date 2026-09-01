/*****************************************************************************
 * Program:     04_feature_engineering.sas
 * Section:     8 — Feature Engineering
 * Purpose:     Create meaningful predictive features from the cleaned data.
 *              Each feature includes rationale for why it could influence churn.
 * Input:       CHURN.clean_telco
 * Output:      CHURN.features_telco (dataset with engineered features)
 * Author:      [Your Name]
 * Date:        [Date]
 *****************************************************************************/

data CHURN.features_telco;
    set CHURN.clean_telco;
    
    /*======================================================================
      FEATURE 1: TENURE GROUPS
      
      WHY: Raw tenure is continuous. Grouping reveals lifecycle stages
      and aligns with business concepts (new, growing, established, loyal).
      
      CHURN INFLUENCE: New customers are far more likely to churn. This
      feature captures the non-linear relationship between tenure and churn.
    ======================================================================*/
    length Tenure_Group $20;
    if tenure <= 6 then Tenure_Group = '01. New (0-6m)';
    else if tenure <= 12 then Tenure_Group = '02. Early (7-12m)';
    else if tenure <= 24 then Tenure_Group = '03. Growing (13-24m)';
    else if tenure <= 48 then Tenure_Group = '04. Established (25-48m)';
    else Tenure_Group = '05. Loyal (49-72m)';
    
    label Tenure_Group = "Customer Lifecycle Stage";
    
    /*======================================================================
      FEATURE 2: SERVICES COUNT (Engagement/Usage Metric)
      
      WHY: Number of active services measures how embedded a customer is
      in the platform. More services = more switching costs.
      
      CHURN INFLUENCE: Customers using only 1 service can easily switch.
      Customers using 5+ services would need to replace multiple products
      if they leave — the "stickiness" effect.
    ======================================================================*/
    Services_Count = 0;
    if upcase(strip(PhoneService))     = 'YES' then Services_Count + 1;
    if upcase(strip(MultipleLines))    = 'YES' then Services_Count + 1;
    if upcase(strip(InternetService)) not in ('NO') then Services_Count + 1;
    if upcase(strip(OnlineSecurity))   = 'YES' then Services_Count + 1;
    if upcase(strip(OnlineBackup))     = 'YES' then Services_Count + 1;
    if upcase(strip(DeviceProtection)) = 'YES' then Services_Count + 1;
    if upcase(strip(TechSupport))      = 'YES' then Services_Count + 1;
    if upcase(strip(StreamingTV))      = 'YES' then Services_Count + 1;
    if upcase(strip(StreamingMovies))  = 'YES' then Services_Count + 1;
    
    label Services_Count = "Total Number of Active Services";
    
    /* Engagement level based on service count */
    length Engagement_Level $16;
    if Services_Count <= 2 then Engagement_Level = '01. Low';
    else if Services_Count <= 4 then Engagement_Level = '02. Medium';
    else Engagement_Level = '03. High';
    
    label Engagement_Level = "Customer Engagement Level";
    
    /*======================================================================
      FEATURE 3: HAS SUPPORT SERVICES (Support Interaction Proxy)
      
      WHY: The dataset doesn't have direct support ticket counts, but
      subscription to TechSupport and OnlineSecurity indicates whether
      the customer has access to support services.
      
      CHURN INFLUENCE: Customers without any support safety net may 
      feel unsupported when issues arise, increasing churn risk.
    ======================================================================*/
    Has_Support = 0;
    if upcase(strip(TechSupport))    = 'YES' then Has_Support = 1;
    if upcase(strip(OnlineSecurity)) = 'YES' then Has_Support = 1;
    
    /* More granular: both, one, or none */
    Support_Level = 0;
    if upcase(strip(TechSupport))    = 'YES' then Support_Level + 1;
    if upcase(strip(OnlineSecurity)) = 'YES' then Support_Level + 1;
    
    label Has_Support    = "Has Any Support Service (0/1)"
          Support_Level  = "Number of Support Services (0-2)";
    
    /*======================================================================
      FEATURE 4: AVERAGE MONTHLY REVENUE (Average Transaction Value)
      
      WHY: TotalCharges / tenure = average monthly revenue per customer.
      This normalizes spend across customer lifetimes.
      
      CHURN INFLUENCE: A divergence between current MonthlyCharges and
      historical average might indicate price increases that trigger churn.
    ======================================================================*/
    if tenure > 0 then Avg_Monthly_Revenue = TotalCharges / tenure;
    else Avg_Monthly_Revenue = MonthlyCharges;  /* New customers */
    
    label Avg_Monthly_Revenue = "Average Monthly Revenue ($)";
    
    /* Price change indicator: current charge vs. historical average */
    if Avg_Monthly_Revenue > 0 then 
        Price_Change_Ratio = MonthlyCharges / Avg_Monthly_Revenue;
    else Price_Change_Ratio = 1;
    
    label Price_Change_Ratio = "Current vs. Historical Price Ratio";
    
    /*======================================================================
      FEATURE 5: CUSTOMER ACTIVITY LEVEL (Composite Engagement Score)
      
      WHY: Combines multiple signals into one engagement metric:
      - Service breadth (how many services)
      - Tenure (how long)
      - Support adoption
      
      CHURN INFLUENCE: Disengaged customers (low services + short tenure
      + no support) are highest risk.
    ======================================================================*/
    /* Normalize components to 0-1 scale */
    Tenure_Norm = tenure / 72;  /* Max tenure is ~72 months */
    Services_Norm = Services_Count / 9;  /* Max possible services = 9 */
    
    /* Weighted composite score (0-100) */
    Activity_Score = (Tenure_Norm * 40) + (Services_Norm * 40) + (Has_Support * 20);
    Activity_Score = round(Activity_Score * 100, 0.1);
    
    label Activity_Score = "Customer Activity Score (0-100)";
    
    /* Activity level categories */
    length Activity_Level $16;
    if Activity_Score < 25 then Activity_Level = '01. Inactive';
    else if Activity_Score < 50 then Activity_Level = '02. Low';
    else if Activity_Score < 75 then Activity_Level = '03. Active';
    else Activity_Level = '04. Highly Active';
    
    label Activity_Level = "Customer Activity Level";
    
    /*======================================================================
      FEATURE 6: PAYMENT BEHAVIOR (Automated vs. Manual)
      
      WHY: Automatic payment reduces friction and signals commitment.
      Manual payment requires active effort each month.
      
      CHURN INFLUENCE: Automatic payers have deliberately set up billing — 
      they're less likely to churn on impulse. Manual payers face a 
      "decision point" every billing cycle.
    ======================================================================*/
    if index(upcase(PaymentMethod), 'AUTOMATIC') > 0 then Auto_Pay = 1;
    else Auto_Pay = 0;
    
    label Auto_Pay = "Uses Automatic Payment (0/1)";
    
    /*======================================================================
      FEATURE 7: STREAMING BUNDLE (Entertainment Engagement)
      
      WHY: Streaming services represent ongoing engagement with the 
      platform beyond basic connectivity.
      
      CHURN INFLUENCE: Customers using streaming are actively consuming
      content through the platform, creating habitual usage.
    ======================================================================*/
    Streaming_Count = 0;
    if upcase(strip(StreamingTV))     = 'YES' then Streaming_Count + 1;
    if upcase(strip(StreamingMovies)) = 'YES' then Streaming_Count + 1;
    
    Has_Streaming = (Streaming_Count > 0);
    
    label Streaming_Count = "Number of Streaming Services (0-2)"
          Has_Streaming   = "Uses Any Streaming Service (0/1)";
    
    /*======================================================================
      FEATURE 8: PROTECTION BUNDLE (Security Engagement)
      
      WHY: Security/protection services indicate a customer who values
      the platform's ecosystem beyond basic service.
      
      CHURN INFLUENCE: These customers have invested in protecting their
      digital life through the platform — high switching cost.
    ======================================================================*/
    Protection_Count = 0;
    if upcase(strip(OnlineSecurity))   = 'YES' then Protection_Count + 1;
    if upcase(strip(OnlineBackup))     = 'YES' then Protection_Count + 1;
    if upcase(strip(DeviceProtection)) = 'YES' then Protection_Count + 1;
    
    Has_Protection = (Protection_Count > 0);
    
    label Protection_Count = "Number of Protection Services (0-3)"
          Has_Protection   = "Uses Any Protection Service (0/1)";
    
    /*======================================================================
      FEATURE 9: CONTRACT RISK INDICATOR
      
      WHY: Month-to-month contracts with high charges and low engagement
      represent the highest flight risk combination.
      
      CHURN INFLUENCE: This interaction feature captures the compound
      effect of commitment level and price sensitivity.
    ======================================================================*/
    Contract_Risk = 0;
    if Contract = 'Month-to-month' then Contract_Risk = 2;
    else if Contract = 'One year' then Contract_Risk = 1;
    /* Two year = 0 (lowest risk) */
    
    label Contract_Risk = "Contract Risk Score (0=Low, 2=High)";
    
    /*======================================================================
      FEATURE 10: CUSTOMER VALUE TIER
      
      WHY: Segments customers by revenue contribution, allowing 
      prioritization of retention efforts by business value.
      
      CHURN INFLUENCE: High-value customer churn has greater revenue 
      impact, justifying higher retention investment.
    ======================================================================*/
    length Value_Tier $16;
    if MonthlyCharges >= 80 then Value_Tier = '01. High Value';
    else if MonthlyCharges >= 50 then Value_Tier = '02. Mid Value';
    else Value_Tier = '03. Low Value';
    
    label Value_Tier = "Customer Value Tier by Monthly Revenue";
run;

/*==========================================================================
  VALIDATION: Check engineered features
==========================================================================*/

proc means data=CHURN.features_telco n mean std min max;
    title "Engineered Features — Summary Statistics";
    var Services_Count Support_Level Avg_Monthly_Revenue 
        Price_Change_Ratio Activity_Score Auto_Pay 
        Streaming_Count Protection_Count Contract_Risk;
run;

proc freq data=CHURN.features_telco;
    title "Engineered Features — Categorical Distributions";
    tables Tenure_Group Engagement_Level Activity_Level Value_Tier / nocum;
run;

/* Verify features by churn status */
proc means data=CHURN.features_telco mean;
    title "Engineered Features — Mean Values by Churn Status";
    class Churn;
    var Services_Count Activity_Score Auto_Pay Has_Support 
        Has_Streaming Has_Protection Contract_Risk;
run;

proc contents data=CHURN.features_telco varnum;
    title "Features Dataset — Full Variable List";
run;

title;
