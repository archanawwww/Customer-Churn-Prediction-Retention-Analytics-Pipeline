/*****************************************************************************
 * Program:     03_eda.sas
 * Section:     7 — Exploratory Data Analysis (EDA)
 * Purpose:     Analyze churn patterns across key business dimensions using
 *              PROC FREQ, PROC MEANS, PROC SQL, and SAS visualizations.
 *              Each analysis includes the business/product insight.
 * Input:       CHURN.clean_telco
 * Output:      ODS reports and charts
 * Author:      [Your Name]
 * Date:        [Date]
 *****************************************************************************/

/* Enable high-quality graphics output */
ods graphics on / width=800px height=500px;

/*==========================================================================
  ANALYSIS 1: CHURN BY TENURE
  
  BUSINESS QUESTION: Are newer customers more likely to churn?
  PRODUCT INSIGHT: If yes → onboarding and early engagement are critical.
  SAS PROCEDURES: PROC MEANS, PROC SGPLOT, PROC SQL
==========================================================================*/

/* 1a. Average tenure by churn status */
proc means data=CHURN.clean_telco mean median std min max;
    title "Tenure Statistics by Churn Status";
    class Churn;
    var tenure;
run;

/* 1b. Tenure distribution by churn — histogram overlay */
proc sgpanel data=CHURN.clean_telco;
    title "Tenure Distribution by Churn Status";
    panelby Churn / layout=columnlattice novarname;
    histogram tenure / binwidth=6 fillattrs=(transparency=0.3);
    colaxis label="Tenure (months)";
    rowaxis label="Count";
run;

/* 1c. Churn rate by tenure groups */
proc sql;
    title "Churn Rate by Tenure Groups";
    select 
        case 
            when tenure <= 12 then '01. 0-12 months'
            when tenure <= 24 then '02. 13-24 months'
            when tenure <= 36 then '03. 25-36 months'
            when tenure <= 48 then '04. 37-48 months'
            when tenure <= 60 then '05. 49-60 months'
            else '06. 61-72 months'
        end as Tenure_Group,
        count(*) as Total_Customers,
        sum(Churn_Flag) as Churned,
        sum(Churn_Flag) / count(*) * 100 as Churn_Rate format=5.1
    from CHURN.clean_telco
    group by calculated Tenure_Group
    order by Tenure_Group;
quit;

/*
  PRODUCT INSIGHT:
  - Expect highest churn in the 0-12 month group (new customers)
  - This suggests the "onboarding window" is critical
  - Product recommendation: Improve first 90-day experience, 
    guided setup, early engagement triggers
  - KPI to monitor: 90-day retention rate
*/

/*==========================================================================
  ANALYSIS 2: CHURN BY CONTRACT TYPE
  
  BUSINESS QUESTION: Does contract length affect churn?
  PRODUCT INSIGHT: If month-to-month churns more → consider incentivizing 
  longer commitments or improving month-to-month value proposition.
==========================================================================*/

proc freq data=CHURN.clean_telco;
    title "Churn Rate by Contract Type";
    tables Contract * Churn / chisq nocum nopercent 
           plots=freqplot(twoway=stacked scale=percent);
run;

/* Detailed churn rate by contract */
proc sql;
    title "Churn Rate by Contract Type — Detail";
    select 
        Contract,
        count(*) as Total,
        sum(Churn_Flag) as Churned,
        count(*) - sum(Churn_Flag) as Retained,
        sum(Churn_Flag) / count(*) * 100 as Churn_Rate format=5.1
    from CHURN.clean_telco
    group by Contract
    order by calculated Churn_Rate desc;
quit;

proc sgplot data=CHURN.clean_telco;
    title "Churn Distribution by Contract Type";
    vbar Contract / group=Churn groupdisplay=cluster stat=percent
         datalabel;
    xaxis label="Contract Type";
    yaxis label="Percentage of Customers";
run;

/*
  PRODUCT INSIGHT:
  - Month-to-month contracts will likely show the highest churn rate
  - This is expected: no switching cost = easy to leave
  - Product recommendation: 
    a) Identify why customers stay on month-to-month (flexibility preference 
       vs. unaware of annual options)
    b) Offer compelling annual/2-year incentives (discount, bonus features)
    c) Improve the month-to-month experience so it's worth staying even 
       without a lock-in
  - KPI: Contract upgrade rate, churn rate by contract type
*/

/*==========================================================================
  ANALYSIS 3: CHURN BY MONTHLY CHARGES
  
  BUSINESS QUESTION: Do higher-paying customers churn more?
  PRODUCT INSIGHT: If yes → customers may perceive poor value-for-money, 
  or high prices attract competitors.
==========================================================================*/

proc means data=CHURN.clean_telco mean median std q1 q3;
    title "Monthly Charges by Churn Status";
    class Churn;
    var MonthlyCharges;
run;

proc sgplot data=CHURN.clean_telco;
    title "Monthly Charges Distribution by Churn Status";
    vbox MonthlyCharges / category=Churn 
         fillattrs=(transparency=0.2);
    xaxis label="Churn Status";
    yaxis label="Monthly Charges ($)";
run;

/* Churn rate by charge brackets */
proc sql;
    title "Churn Rate by Monthly Charges Bracket";
    select 
        case 
            when MonthlyCharges < 30 then '01. < $30'
            when MonthlyCharges < 50 then '02. $30-49'
            when MonthlyCharges < 70 then '03. $50-69'
            when MonthlyCharges < 90 then '04. $70-89'
            else '05. $90+'
        end as Charge_Bracket,
        count(*) as Total,
        sum(Churn_Flag) as Churned,
        sum(Churn_Flag) / count(*) * 100 as Churn_Rate format=5.1
    from CHURN.clean_telco
    group by calculated Charge_Bracket
    order by Charge_Bracket;
quit;

/*
  PRODUCT INSIGHT:
  - Higher monthly charges typically correlate with higher churn
  - These customers have more services (fiber, add-ons) = higher expectations
  - High-paying churners represent the biggest revenue loss per customer
  - Product recommendation:
    a) Ensure premium customers receive premium experience
    b) Proactive outreach for high-value at-risk customers
    c) Price sensitivity analysis — are charges above value threshold?
  - KPI: Revenue-weighted churn rate, ARPU trends by segment
*/

/*==========================================================================
  ANALYSIS 4: CHURN BY CUSTOMER ENGAGEMENT (SERVICE ADD-ONS)
  
  BUSINESS QUESTION: Do customers using more services churn less?
  PRODUCT INSIGHT: Service stickiness — more features used = harder to leave.
==========================================================================*/

/* Create an engagement score: count of add-on services */
data _eda_engagement;
    set CHURN.clean_telco;
    
    /* Count services subscribed to */
    Services_Count = 0;
    if upcase(strip(PhoneService))     = 'YES' then Services_Count + 1;
    if upcase(strip(MultipleLines))    = 'YES' then Services_Count + 1;
    if InternetService not in ('No', 'no')      then Services_Count + 1;
    if upcase(strip(OnlineSecurity))   = 'YES' then Services_Count + 1;
    if upcase(strip(OnlineBackup))     = 'YES' then Services_Count + 1;
    if upcase(strip(DeviceProtection)) = 'YES' then Services_Count + 1;
    if upcase(strip(TechSupport))      = 'YES' then Services_Count + 1;
    if upcase(strip(StreamingTV))      = 'YES' then Services_Count + 1;
    if upcase(strip(StreamingMovies))  = 'YES' then Services_Count + 1;
run;

proc sql;
    title "Churn Rate by Number of Services Subscribed";
    select 
        Services_Count,
        count(*) as Total,
        sum(Churn_Flag) as Churned,
        sum(Churn_Flag) / count(*) * 100 as Churn_Rate format=5.1
    from _eda_engagement
    group by Services_Count
    order by Services_Count;
quit;

proc sgplot data=_eda_engagement;
    title "Churn Rate by Number of Services";
    vbar Services_Count / response=Churn_Flag stat=mean datalabel 
         datalabelfitpolicy=none;
    xaxis label="Number of Services Subscribed" integer;
    yaxis label="Churn Rate" values=(0 to 1 by 0.1);
run;

/*
  PRODUCT INSIGHT:
  - Customers using more services tend to have lower churn (stickiness effect)
  - BUT direction of causation is unclear — do more services prevent churn, 
    or do loyal customers simply adopt more services?
  - Product recommendation:
    a) Drive feature adoption in the first 90 days (guided product tours)
    b) Bundle services to increase switching costs naturally
    c) Track "features activated" as a leading indicator of churn risk
  - KPI: Features adopted per customer, time-to-second-service
*/

/*==========================================================================
  ANALYSIS 5: CHURN BY PAYMENT METHOD
  
  BUSINESS QUESTION: Does payment method predict churn?
  PRODUCT INSIGHT: Payment friction may cause involuntary churn 
  or signal customer disengagement.
==========================================================================*/

proc freq data=CHURN.clean_telco;
    title "Churn Rate by Payment Method";
    tables PaymentMethod * Churn / chisq nocum nopercent;
run;

proc sql;
    title "Churn Rate by Payment Method — Detail";
    select 
        PaymentMethod,
        count(*) as Total,
        sum(Churn_Flag) as Churned,
        sum(Churn_Flag) / count(*) * 100 as Churn_Rate format=5.1
    from CHURN.clean_telco
    group by PaymentMethod
    order by calculated Churn_Rate desc;
quit;

proc sgplot data=CHURN.clean_telco;
    title "Churn Rate by Payment Method";
    vbar PaymentMethod / response=Churn_Flag stat=mean datalabel
         categoryorder=respdesc;
    xaxis label="Payment Method" discreteorder=data;
    yaxis label="Churn Rate";
run;

/*
  PRODUCT INSIGHT:
  - Electronic check typically shows the highest churn rate
  - This may indicate: less commitment (no auto-billing), payment friction,
    or demographics that correlate with both payment choice and churn risk
  - Automatic payment methods (bank transfer, credit card) show lower churn
  - Product recommendation:
    a) Nudge users toward automatic payment (reduce friction)
    b) Offer small discount for auto-pay enrollment
    c) Investigate if electronic check users have worse experience
  - KPI: Auto-pay enrollment rate, payment failure rate
*/

/*==========================================================================
  ANALYSIS 6: CHURN BY SUPPORT-RELATED SERVICES (Tech Support, Security)
  
  BUSINESS QUESTION: Do customers without support services churn more?
  PRODUCT INSIGHT: Support acts as a retention mechanism.
==========================================================================*/

proc freq data=CHURN.clean_telco;
    title "Churn Rate by Tech Support Status";
    tables TechSupport * Churn / chisq nocum nopercent;
run;

proc freq data=CHURN.clean_telco;
    title "Churn Rate by Online Security Status";
    tables OnlineSecurity * Churn / chisq nocum nopercent;
run;

proc sql;
    title "Churn Rate by Support Services";
    select 
        TechSupport,
        OnlineSecurity,
        count(*) as Total,
        sum(Churn_Flag) as Churned,
        sum(Churn_Flag) / count(*) * 100 as Churn_Rate format=5.1
    from CHURN.clean_telco
    group by TechSupport, OnlineSecurity
    order by calculated Churn_Rate desc;
quit;

/*
  PRODUCT INSIGHT:
  - Customers WITHOUT tech support and online security churn significantly more
  - This could mean:
    a) These services genuinely add value (retention through better experience)
    b) Customers who don't buy add-ons are less invested in the platform
    c) Some customers may not know these services exist
  - Product recommendation:
    a) Include basic tech support in all plans (reduce churn structurally)
    b) Promote security features during onboarding
    c) A/B test offering free trial of tech support to at-risk customers
  - KPI: Add-on adoption rate, support-related churn reduction
*/

/*==========================================================================
  ANALYSIS 7: OTHER IMPORTANT CHURN DRIVERS
==========================================================================*/

/* 7a. Churn by Internet Service Type */
proc sql;
    title "Churn Rate by Internet Service Type";
    select 
        InternetService,
        count(*) as Total,
        sum(Churn_Flag) as Churned,
        sum(Churn_Flag) / count(*) * 100 as Churn_Rate format=5.1,
        avg(MonthlyCharges) as Avg_Monthly format=6.2
    from CHURN.clean_telco
    group by InternetService
    order by calculated Churn_Rate desc;
quit;

/* 7b. Churn by Demographics */
proc sql;
    title "Churn Rate by Senior Citizen Status";
    select 
        SeniorCitizen,
        count(*) as Total,
        sum(Churn_Flag) as Churned,
        sum(Churn_Flag) / count(*) * 100 as Churn_Rate format=5.1
    from CHURN.clean_telco
    group by SeniorCitizen;
quit;

proc sql;
    title "Churn Rate by Partner and Dependent Status";
    select 
        Partner, 
        Dependents,
        count(*) as Total,
        sum(Churn_Flag) as Churned,
        sum(Churn_Flag) / count(*) * 100 as Churn_Rate format=5.1
    from CHURN.clean_telco
    group by Partner, Dependents
    order by calculated Churn_Rate desc;
quit;

/* 7c. Churn by Paperless Billing */
proc freq data=CHURN.clean_telco;
    title "Churn Rate by Paperless Billing";
    tables PaperlessBilling * Churn / chisq nocum nopercent;
run;

/* 7d. Correlation heatmap — numeric variables */
proc corr data=CHURN.clean_telco nosimple noprob;
    title "Correlation Matrix — Numeric Variables with Churn Flag";
    var Churn_Flag tenure MonthlyCharges TotalCharges 
        SeniorCitizen Partner_Flag Dependents_Flag 
        PaperlessBilling_Flag;
run;

/* 7e. Scatter plot — Monthly Charges vs Tenure colored by Churn */
proc sgplot data=CHURN.clean_telco;
    title "Monthly Charges vs Tenure by Churn Status";
    scatter x=tenure y=MonthlyCharges / group=Churn 
            transparency=0.5
            markerattrs=(symbol=circlefilled size=5);
    xaxis label="Tenure (months)";
    yaxis label="Monthly Charges ($)";
run;

/*==========================================================================
  EDA INSIGHTS SUMMARY
  
  After running all analyses, compile your key findings:
  
  1. TENURE: New customers (0-12 months) have the highest churn rate
  2. CONTRACT: Month-to-month contracts churn dramatically more
  3. CHARGES: Higher monthly charges associate with higher churn
  4. ENGAGEMENT: Fewer services = higher churn (stickiness effect)
  5. PAYMENT: Electronic check users churn the most
  6. SUPPORT: No tech support / no security = much higher churn
  7. INTERNET: Fiber optic customers may churn more than DSL
  8. DEMOGRAPHICS: Seniors, single, no dependents = higher churn
  
  KEY THEME: Churn is driven by a combination of low commitment 
  (month-to-month, electronic check) + low engagement (few services, 
  no support) + early lifecycle (low tenure) + high price sensitivity 
  (high monthly charges without perceived value).
==========================================================================*/

/* Clean up temp datasets */
proc delete data=_eda_engagement; run;

ods graphics off;
title;
