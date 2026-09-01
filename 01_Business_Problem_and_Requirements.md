# Section 1: Business Problem Definition

## 1.1 What Is Customer Churn?

**Customer churn** (also called customer attrition) is the phenomenon where customers stop doing business with a company — they cancel their subscription, switch to a competitor, or simply stop purchasing. In a subscription-based business (telecom, SaaS, streaming), churn is typically defined as a customer who has terminated their service within a defined observation period.

**Key distinction:**
- **Voluntary churn**: The customer actively decides to leave (e.g., cancels subscription)
- **Involuntary churn**: The customer is removed due to non-payment or policy violation

This project focuses on **voluntary churn**, which is the type a product team can influence.

## 1.2 Why Predict Churn?

Churn prediction matters because:

| Factor | Impact |
|--------|--------|
| **Revenue protection** | Losing customers directly reduces recurring revenue |
| **Acquisition cost** | Acquiring a new customer costs 5–25× more than retaining an existing one |
| **Lifetime value** | Retained customers spend more over time and cost less to serve |
| **Growth math** | Even a 5% improvement in retention can increase profits by 25–95% (Bain & Company) |
| **Product feedback** | Understanding *why* customers leave reveals product gaps |
| **Competitive defense** | Identifying at-risk customers before competitors poach them |

**From a Product Management perspective**, churn prediction transforms a lagging indicator ("we lost 500 customers last month") into a leading indicator ("these 500 customers are likely to leave next month — here's why, and here's what we can do about it").

## 1.3 Prediction Objective

**Objective:** Build a binary classification model that predicts, for each active customer, the probability of churning within the next billing cycle.

**Target variable:** `Churn` (binary)
- `1` = Customer churned (left the service)
- `0` = Customer did not churn (still active)

**Prediction unit:** Individual customer (one row = one customer)

**Prediction horizon:** Next billing cycle (~30 days). This gives the retention team enough lead time to intervene.

## 1.4 Business Success Metrics

These are the metrics the business will use to evaluate whether the churn prediction *product* (not just the model) is successful:

| Metric | Definition | Target Direction |
|--------|-----------|-----------------|
| **Churn rate** | % of customers who left in the period | ↓ Decrease |
| **Retention rate** | % of customers who remained active | ↑ Increase |
| **Save rate** | % of flagged at-risk customers who were retained after intervention | ↑ Increase |
| **Customer Lifetime Value (CLV)** | Total revenue a customer generates over their lifetime | ↑ Increase |
| **Net Revenue Retention (NRR)** | Revenue from existing customers including expansion/contraction | ↑ Increase |
| **Cost per save** | Cost of retention intervention per successfully retained customer | ↓ Decrease |
| **Intervention ROI** | Revenue saved / cost of retention interventions | ↑ Increase |

> **Note:** Model accuracy alone is not a business success metric. A model with 95% accuracy that never triggers a useful intervention is worthless. The business success metrics above measure whether the *product built on top of the model* actually reduces churn.

---

# Section 2: Product Requirements

## 2.1 Stakeholders and Users

| Stakeholder | Role | What They Need |
|-------------|------|----------------|
| **VP of Product** | Strategic sponsor | High-level churn trends, ROI of retention initiatives, product roadmap input |
| **Product Manager** | Primary user | Churn drivers, customer segments, feature-level insights, A/B test designs |
| **Customer Success Manager** | Operational user | Individual customer risk scores, recommended actions, daily/weekly risk lists |
| **Marketing Manager** | Campaign planner | Segment-level profiles for targeted retention campaigns |
| **Data Analyst** | Technical support | Model outputs, data pipelines, report generation |
| **Engineering Lead** | Implementation | Technical integration requirements, API/CRM feed specifications |
| **Finance / Revenue Ops** | Business case owner | Revenue impact estimates, cost-benefit analysis of interventions |

## 2.2 User Needs and Use Cases

### Use Case 1: Proactive Risk Identification
**As a** Customer Success Manager,
**I want to** see a daily list of high-risk customers with their churn probability and key risk drivers,
**so that** I can prioritize outreach and retention interventions before the customer leaves.

### Use Case 2: Product Gap Discovery
**As a** Product Manager,
**I want to** understand which product features, service attributes, or experience gaps drive churn,
**so that** I can prioritize product improvements that will structurally reduce churn.

### Use Case 3: Segment-Level Strategy
**As a** VP of Product,
**I want to** see churn patterns across customer segments (by value, tenure, engagement),
**so that** I can allocate retention resources proportional to segment value.

### Use Case 4: Campaign Targeting
**As a** Marketing Manager,
**I want to** receive customer lists segmented by risk level and churn driver,
**so that** I can design targeted retention campaigns with personalized messaging.

### Use Case 5: Intervention Effectiveness Measurement
**As a** Product Manager,
**I want to** compare churn rates between customers who received an intervention vs. those who didn't,
**so that** I can measure whether our retention actions are actually working.

## 2.3 Functional Requirements

| ID | Requirement | Priority |
|----|-------------|----------|
| FR-01 | System shall ingest customer data from CSV/database source | Must Have |
| FR-02 | System shall clean, validate, and preprocess raw customer data | Must Have |
| FR-03 | System shall compute derived features (tenure groups, engagement scores, etc.) | Must Have |
| FR-04 | System shall segment customers into meaningful behavioral groups | Must Have |
| FR-05 | System shall predict churn probability for each active customer | Must Have |
| FR-06 | System shall classify customers into risk categories (Low/Medium/High) | Must Have |
| FR-07 | System shall identify top churn-driving factors at the population and segment level | Must Have |
| FR-08 | System shall generate a KPI dashboard with churn/retention metrics | Must Have |
| FR-09 | System shall produce an exportable risk-scored customer list | Should Have |
| FR-10 | System shall support model retraining with updated data | Should Have |
| FR-11 | System shall compare multiple model approaches (logistic regression vs. decision tree) | Nice to Have |

## 2.4 Non-Functional Requirements

| ID | Requirement | Details |
|----|-------------|---------|
| NFR-01 | **Interpretability** | Model outputs must be explainable to non-technical stakeholders |
| NFR-02 | **Reproducibility** | All data transformations and model training must be fully scripted in SAS |
| NFR-03 | **Scalability** | Pipeline must handle datasets up to 100K customers without modification |
| NFR-04 | **Auditability** | Every preprocessing decision must be documented with rationale |
| NFR-05 | **Timeliness** | Full pipeline (data → scores) must complete within 30 minutes for 10K records |
| NFR-06 | **Data privacy** | No personally identifiable information (PII) in model outputs or dashboards |

## 2.5 What the Final Product Helps Users Decide

The dashboard and model outputs should help users answer these questions:

1. **"Which customers should we contact this week?"** → Risk-scored customer list sorted by churn probability
2. **"Why are customers leaving?"** → Top churn drivers ranked by statistical significance and business impact
3. **"Which customer segment needs the most attention?"** → Segment-level churn rates and risk distributions
4. **"What product changes would reduce churn the most?"** → Feature-level analysis linking product attributes to churn
5. **"Are our retention efforts working?"** → Before/after churn rate comparison for intervention groups
6. **"How much revenue is at risk?"** → High-risk customer count × average monthly revenue
7. **"Where should we invest next?"** → Prioritized list of product/retention initiatives ranked by impact and effort
