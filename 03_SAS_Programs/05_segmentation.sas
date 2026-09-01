/*****************************************************************************
 * Program:     05_segmentation.sas
 * Section:     9 — Customer Segmentation
 * Purpose:     Create meaningful customer segments using k-means clustering 
 *              (PROC FASTCLUS) to support differentiated product strategies.
 * Input:       CHURN.features_telco
 * Output:      CHURN.segmented_telco (dataset with cluster assignments)
 * Author:      [Your Name]
 * Date:        [Date]
 *
 * METHODOLOGY:
 * We use k-means clustering (PROC FASTCLUS) because:
 * 1. It's well-supported in SAS 9.4 and SAS Studio
 * 2. It works well with the dataset size (~7K records)
 * 3. It produces interpretable, non-overlapping segments
 * 4. It handles numeric variables efficiently
 *****************************************************************************/

/*==========================================================================
  STEP 1: SELECT AND PREPARE VARIABLES FOR CLUSTERING
  
  WHICH VARIABLES TO USE:
  We select variables that capture customer VALUE and BEHAVIOR:
  - tenure: Loyalty / relationship length
  - MonthlyCharges: Revenue contribution / value tier
  - Services_Count: Engagement breadth
  - Activity_Score: Composite engagement metric
  - Contract_Risk: Commitment level
  
  WHY NOT the target variable (Churn_Flag)?
  We DO NOT include Churn_Flag in clustering because:
  - Segmentation should describe customer BEHAVIOR, not outcome
  - We want segments that are useful for both churned and active customers
  - Including churn would make segmentation circular
  
  HOW TO PREPARE:
  Variables must be STANDARDIZED (z-score) before clustering because 
  k-means uses Euclidean distance. Without standardization, variables 
  with larger scales (e.g., MonthlyCharges in $) would dominate over 
  variables with smaller scales (e.g., Contract_Risk in 0-2).
==========================================================================*/

/* 1a. Standardize clustering variables */
proc standard data=CHURN.features_telco 
              out=_cluster_input 
              mean=0 std=1;
    var tenure MonthlyCharges Services_Count Activity_Score Contract_Risk;
run;

/*==========================================================================
  STEP 2: DETERMINE THE OPTIMAL NUMBER OF SEGMENTS
  
  HOW: Run k-means for k = 2 to 8 clusters and compare the 
  Pseudo F-Statistic (also called Calinski-Harabasz Index).
  Higher Pseudo F = better separation between clusters.
  
  Also consider business interpretability — too many clusters are hard 
  to act on; too few lose meaningful distinctions.
==========================================================================*/

/* Run k-means for k=2 through k=8 */
%macro test_clusters;
    %do k = 2 %to 8;
        proc fastclus data=_cluster_input 
                      maxclusters=&k 
                      out=_clust_k&k 
                      maxiter=100
                      noprint;
            var tenure MonthlyCharges Services_Count Activity_Score Contract_Risk;
        run;
    %end;
%mend;
%test_clusters;

/* 
  INTERPRETATION GUIDE:
  - Review the Pseudo F-Statistic in the output for each k
  - Look for the "elbow" — where adding more clusters stops 
    providing meaningful improvement
  - For business use, 3-5 clusters is typically optimal:
    * 2 clusters is too coarse
    * 6+ clusters is too granular for actionable strategies
  - Start with k=4 as the working hypothesis (see Step 3)
*/

/*==========================================================================
  STEP 3: RUN FINAL CLUSTERING WITH CHOSEN k
  
  We use k=4 as a practical starting point. This typically produces 
  segments like:
  - High-value / High-engagement (loyal)
  - High-value / Low-engagement (at-risk)
  - Low-value / High-engagement (growth potential)
  - Low-value / Low-engagement (deprioritize or nurture)
  
  IMPORTANT: Do not pre-define what the segments "should" look like.
  Let the data determine the cluster characteristics. The labels 
  above are hypotheses that must be validated from actual output.
==========================================================================*/

proc fastclus data=_cluster_input 
              maxclusters=4 
              out=_clustered 
              outstat=_cluster_stats
              maxiter=100;
    var tenure MonthlyCharges Services_Count Activity_Score Contract_Risk;
    id customerID;
run;

/*==========================================================================
  STEP 4: MERGE CLUSTER ASSIGNMENTS BACK TO FEATURES DATASET
==========================================================================*/

/* Get cluster assignments (CLUSTER variable) */
data _cluster_ids;
    set _clustered (keep=customerID CLUSTER);
    rename CLUSTER = Segment_ID;
run;

/* Merge with features dataset */
proc sql;
    create table CHURN.segmented_telco as
    select a.*, b.Segment_ID
    from CHURN.features_telco as a
    left join _cluster_ids as b
    on a.customerID = b.customerID;
quit;

/*==========================================================================
  STEP 5: PROFILE AND INTERPRET EACH SEGMENT
  
  HOW TO INTERPRET:
  - Compare the mean of each variable across segments
  - Name each segment based on its dominant characteristics
  - Identify which segments have the highest churn rates
  
  This is where you translate cluster numbers into business names.
==========================================================================*/

/* 5a. Segment profiles — average values */
proc means data=CHURN.segmented_telco mean median;
    title "Segment Profiles — Average Values";
    class Segment_ID;
    var tenure MonthlyCharges TotalCharges Services_Count 
        Activity_Score Contract_Risk Auto_Pay Has_Support 
        Has_Streaming Churn_Flag;
run;

/* 5b. Segment sizes */
proc freq data=CHURN.segmented_telco;
    title "Segment Distribution";
    tables Segment_ID / nocum;
run;

/* 5c. Churn rate by segment */
proc sql;
    title "Churn Rate and Revenue by Segment";
    select 
        Segment_ID,
        count(*) as Total_Customers,
        sum(Churn_Flag) as Churned,
        sum(Churn_Flag) / count(*) * 100 as Churn_Rate format=5.1,
        avg(MonthlyCharges) as Avg_Monthly format=6.2,
        avg(tenure) as Avg_Tenure format=5.1,
        avg(Services_Count) as Avg_Services format=4.1,
        avg(Activity_Score) as Avg_Activity format=5.1
    from CHURN.segmented_telco
    group by Segment_ID
    order by Segment_ID;
quit;

/* 5d. Contract type distribution by segment */
proc freq data=CHURN.segmented_telco;
    title "Contract Type by Segment";
    tables Segment_ID * Contract / nocum nopercent norow;
run;

/* 5e. Visualize segment profiles */
proc sgplot data=CHURN.segmented_telco;
    title "Monthly Charges vs Tenure — Colored by Segment";
    scatter x=tenure y=MonthlyCharges / group=Segment_ID
            markerattrs=(symbol=circlefilled size=5)
            transparency=0.4;
    xaxis label="Tenure (months)";
    yaxis label="Monthly Charges ($)";
run;

/* 5f. Churn rate by segment — bar chart */
proc sgplot data=CHURN.segmented_telco;
    title "Churn Rate by Customer Segment";
    vbar Segment_ID / response=Churn_Flag stat=mean datalabel
         datalabelfitpolicy=none;
    xaxis label="Segment" integer;
    yaxis label="Churn Rate" values=(0 to 1 by 0.1);
run;

/*==========================================================================
  STEP 6: NAME THE SEGMENTS (manual step after reviewing output)
  
  INSTRUCTIONS:
  After running Steps 5a-5f, examine the output and assign business-
  meaningful names. Below is a TEMPLATE — replace with actual findings.
  
  Example naming based on typical patterns:
  
  | Segment_ID | Typical Profile                        | Suggested Name         |
  |-----------|----------------------------------------|------------------------|
  | 1         | High tenure, high spend, many services | Loyal Champions        |
  | 2         | Low tenure, high spend, month-to-month | High-Value At-Risk     |
  | 3         | Medium tenure, low spend, few services | Disengaged Mainstream  |
  | 4         | Low tenure, low spend, few services    | New & Vulnerable       |
  
  DO NOT use these labels until you've validated them against actual output.
==========================================================================*/

/* Apply segment names (UPDATE THESE after reviewing output) */
data CHURN.segmented_telco;
    set CHURN.segmented_telco;
    
    length Segment_Name $30;
    
    /* PLACEHOLDER — Replace with actual names based on your cluster output */
    select (Segment_ID);
        when (1) Segment_Name = 'Segment 1 (Review Output)';
        when (2) Segment_Name = 'Segment 2 (Review Output)';
        when (3) Segment_Name = 'Segment 3 (Review Output)';
        when (4) Segment_Name = 'Segment 4 (Review Output)';
        otherwise Segment_Name = 'Unknown';
    end;
    
    label Segment_Name = "Customer Segment Name"
          Segment_ID   = "Customer Segment ID (from Clustering)";
run;

/*==========================================================================
  HOW SEGMENTATION SUPPORTS PRODUCT DECISIONS
  
  1. RESOURCE ALLOCATION: Focus retention budget on high-value segments
  2. DIFFERENTIATED STRATEGY: Each segment needs a different intervention
     - Loyal Champions → reward, upsell, advocacy programs
     - High-Value At-Risk → urgent retention, dedicated CSM, discounts
     - Disengaged Mainstream → re-engagement campaigns, feature education
     - New & Vulnerable → onboarding improvement, early support
  3. MEASUREMENT: Track churn rate WITHIN each segment over time
  4. EXPERIMENTATION: Run A/B tests targeted to specific segments
  5. PRIORITIZATION: Fix the segment with highest churn × highest value first
==========================================================================*/

/* Clean up temp datasets */
proc delete data=_cluster_input _clustered _cluster_stats _cluster_ids; run;
%macro del_clusters;
    %do k = 2 %to 8;
        proc delete data=_clust_k&k; run;
    %end;
%mend;
%del_clusters;

title;
