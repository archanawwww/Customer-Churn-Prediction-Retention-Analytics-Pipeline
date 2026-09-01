# Section 15: Product Recommendations

Moving from data to action requires a structured framework:
**Data → Insight → Product Problem → Recommendation → KPI**

Based on the model drivers (Section 13), here are the product recommendations:

## 1. The Onboarding Problem
* **Data:** Customers with < 12 months tenure have the highest churn probability.
* **Insight:** Customers are not realizing value early in their lifecycle.
* **Product Problem:** Weak onboarding and activation.
* **Recommendation:** Implement a 30-day "Guided Success" onboarding flow. Add in-app checklists for new users to set up auto-pay, add an emergency contact (proxy for dependents), and download the mobile app.
* **KPI to Monitor:** 90-day retention rate, Time-to-First-Value (TTFV).

## 2. The Contract Friction Problem
* **Data:** Month-to-month contracts have a massive positive odds ratio for churn.
* **Insight:** Month-to-month users have zero switching costs and face a renewal decision every 30 days.
* **Product Problem:** Insufficient incentives to commit to annual plans.
* **Recommendation:** Create a "Commit & Save" feature in the billing portal. Show month-to-month users exactly how much they would save by upgrading to 1-year, and allow them to upgrade with one click.
* **KPI to Monitor:** Contract upgrade rate (% of M2M moving to annual).

## 3. The Engagement Gap
* **Data:** Customers with <= 2 services (Low Engagement) have high churn rates.
* **Insight:** The product is not "sticky" for users who only use basic connectivity.
* **Product Problem:** Low cross-sell discovery; users don't know about or value add-ons.
* **Recommendation:** Introduce "Bundle Builder" during checkout and in the user dashboard. Group synergistic services (e.g., Internet + Streaming TV + Online Security) at a slight discount to increase service count.
* **KPI to Monitor:** Average services per customer, Add-on attach rate.

## 4. The Support Deficit
* **Data:** Absence of Tech Support and Online Security are strong churn predictors.
* **Insight:** Customers without support safety nets churn when they encounter issues.
* **Product Problem:** Support is treated as an upsell rather than a retention tool.
* **Recommendation:** Offer a 6-month free trial of Tech Support to "High Risk" month-to-month customers. Evaluate if the retention lift outweighs the cost of providing the support.
* **KPI to Monitor:** Trial conversion rate, Support-related churn reduction.

## 5. The Payment Friction
* **Data:** Electronic check / Manual payment correlates with churn.
* **Insight:** Manual payment creates a monthly opportunity to lapse (involuntary or voluntary).
* **Product Problem:** High friction in the payment experience.
* **Recommendation:** Launch an "Auto-Pay Activation" campaign offering a one-time $10 credit to switch to automatic payments via credit card or bank transfer.
* **KPI to Monitor:** Auto-pay enrollment rate, Payment failure rate.

---

# Section 16: Prioritization Framework

A Product Manager must decide which of the recommendations above to build first. We use the **RICE** (Reach, Impact, Confidence, Effort) framework, tailored for churn reduction.

| Initiative | Reach (Customers affected) | Impact (Expected Churn Reduction) | Confidence (Data backing) | Effort (Engineering weeks) | Priority / Decision |
|------------|----------------------------|-----------------------------------|---------------------------|----------------------------|---------------------|
| **1. "Commit & Save" 1-Click Upgrade** | High (All M2M users) | High (M2M is biggest driver) | High (Clear data link) | Low (Just UI/Billing change) | **#1 (Quick Win)** |
| **2. Auto-Pay $10 Credit Campaign** | Medium (Manual payers) | Medium (Reduces friction) | High (Data shows correlation) | Low (Marketing/Ops task) | **#2 (Low Effort)** |
| **3. 30-Day Guided Onboarding** | Low (Only new users) | High (Fixes the leaky bucket) | Medium (Hard to get right) | High (New UX needed) | **#3 (Strategic Bet)** |
| **4. Bundle Builder UX** | Medium (New & Upgrading users) | Medium (Increases stickiness) | Medium (Assumption on pricing) | Medium (Cart redesign) | **#4 (Backlog)** |
| **5. Free Tech Support Trial** | Low (Only High-Risk users) | Unknown (Needs testing) | Low (Could be causation error) | Medium (Ops scaling) | **#5 (Experiment)** |

---

# Section 17: Experimentation (A/B Testing)

We cannot assume that because Tech Support is correlated with low churn, giving everyone Tech Support will reduce churn (correlation ≠ causation). We must validate interventions through experimentation.

## Example Experiment Design: Tech Support Trial for At-Risk Customers

**1. Hypothesis:**
Offering a free 6-month Tech Support trial to High-Risk, Month-to-Month customers will increase their 6-month retention rate by at least 15% compared to no intervention.

**2. Target Audience:**
Customers identified by the SAS model as `Risk_Level = 'High Risk'` AND `Contract = 'Month-to-month'` AND `Has_Support = 0`.

**3. Test Setup (Randomized Controlled Trial):**
* **Control Group (50%):** Receives standard communications (no intervention).
* **Treatment Group (50%):** Receives an email/in-app offer for 6 months of free Tech Support.

**4. Metrics:**
* **Primary Metric:** 6-Month Retention Rate (Did they stay?)
* **Secondary Metric:** Trial Activation Rate (Did they accept the offer?)
* **Guardrail Metric:** Support Costs (Did they abuse the free support, making the intervention unprofitable?)

**5. Success Criteria:**
The intervention is successful if:
`(Revenue Saved from Retained Treatment Group) > (Cost of Support for Treatment Group)`

**6. Evaluation (Post-Test in SAS):**
```sas
/* Example code to evaluate A/B test results */
proc freq data=experiment_results;
    tables Group * Retained_6mo / chisq expected;
run;
```
If the p-value from the Chi-Square test is < 0.05, the retention lift is statistically significant, proving that the intervention actually caused the reduction in churn.
