# Section 3: Dataset Guide — IBM Telco Customer Churn

## 3.1 Recommended Dataset

**Name:** IBM Telco Customer Churn
**Source:** [Kaggle — Telco Customer Churn](https://www.kaggle.com/datasets/blastchar/telco-customer-churn)
**File:** `WA_Fn-UseC_-Telco-Customer-Churn.csv`
**Size:** 7,043 rows × 21 columns
**License:** Apache 2.0 (free for commercial and academic use)

### Why This Dataset?

- **Realistic scope**: 7K customers is large enough for meaningful analysis, small enough to run in SAS Studio without performance concerns
- **Rich feature set**: Contains demographics, account details, service subscriptions, and billing — covering multiple churn-driver categories
- **Known class imbalance**: ~26.5% churn rate — realistic enough to model, imbalanced enough to require thoughtful evaluation
- **Well-documented**: Widely used in data science education, so interviewers will likely recognize it
- **Clean but not too clean**: Has a few real-world data quality issues (e.g., `TotalCharges` has blank values for new customers) that let you demonstrate data cleaning skills

---

## 3.2 Complete Variable Dictionary

### Identifier Variable

| Variable | Type | Description |
|----------|------|-------------|
| `customerID` | Character | Unique identifier for each customer. Not used as a predictor. |

### Target Variable

| Variable | Type | Values | Description |
|----------|------|--------|-------------|
| `Churn` | Character (Binary) | `Yes` / `No` | Whether the customer churned (left) in the last month. **This is the variable we predict.** |

### Demographic Variables

| Variable | Type | Values | Description | Churn Relevance |
|----------|------|--------|-------------|-----------------|
| `gender` | Categorical (Nominal) | `Male` / `Female` | Customer's gender | Generally weak predictor; included for completeness |
| `SeniorCitizen` | Binary (Numeric) | `0` / `1` | Whether the customer is a senior citizen (65+) | Seniors may have different usage and churn patterns |
| `Partner` | Categorical (Binary) | `Yes` / `No` | Whether the customer has a partner | Partnered customers may be more stable |
| `Dependents` | Categorical (Binary) | `Yes` / `No` | Whether the customer has dependents | Families may have higher switching costs |

### Account / Tenure Variables

| Variable | Type | Range | Description | Churn Relevance |
|----------|------|-------|-------------|-----------------|
| `tenure` | Numeric (Integer) | 0–72 months | Number of months the customer has been with the company | **Strong predictor** — newer customers churn much more |
| `Contract` | Categorical (Nominal) | `Month-to-month`, `One year`, `Two year` | Type of contract | **Strong predictor** — month-to-month contracts have highest churn |
| `PaperlessBilling` | Categorical (Binary) | `Yes` / `No` | Whether the customer uses paperless billing | Moderately associated with churn |
| `PaymentMethod` | Categorical (Nominal) | `Electronic check`, `Mailed check`, `Bank transfer (automatic)`, `Credit card (automatic)` | How the customer pays | Electronic check payers churn more |

### Service Variables (What the customer subscribes to)

| Variable | Type | Values | Description | Churn Relevance |
|----------|------|--------|-------------|-----------------|
| `PhoneService` | Categorical (Binary) | `Yes` / `No` | Whether the customer has phone service | Low predictor on its own |
| `MultipleLines` | Categorical | `Yes` / `No` / `No phone service` | Whether the customer has multiple phone lines | Moderate — reflects engagement |
| `InternetService` | Categorical (Nominal) | `DSL`, `Fiber optic`, `No` | Type of internet service | **Strong predictor** — Fiber optic customers churn more (potentially due to higher cost or competition) |
| `OnlineSecurity` | Categorical | `Yes` / `No` / `No internet service` | Whether the customer has online security add-on | Customers without add-ons churn more |
| `OnlineBackup` | Categorical | `Yes` / `No` / `No internet service` | Whether the customer has online backup add-on | Customers without add-ons churn more |
| `DeviceProtection` | Categorical | `Yes` / `No` / `No internet service` | Whether the customer has device protection add-on | Customers without add-ons churn more |
| `TechSupport` | Categorical | `Yes` / `No` / `No internet service` | Whether the customer has tech support add-on | **Strong predictor** — no tech support ↔ higher churn |
| `StreamingTV` | Categorical | `Yes` / `No` / `No internet service` | Whether the customer has streaming TV add-on | Moderate engagement signal |
| `StreamingMovies` | Categorical | `Yes` / `No` / `No internet service` | Whether the customer has streaming movies add-on | Moderate engagement signal |

### Financial Variables

| Variable | Type | Range | Description | Churn Relevance |
|----------|------|-------|-------------|-----------------|
| `MonthlyCharges` | Numeric (Continuous) | ~$18–$118 | Monthly amount charged to the customer | **Strong predictor** — higher charges ↔ higher churn |
| `TotalCharges` | Character* (Continuous) | ~$18–$8,685 | Total amount charged over the customer's lifetime | Correlated with tenure; useful for CLV analysis |

> *`TotalCharges` is stored as character in the raw data because some new customers have blank values (tenure = 0). This must be converted to numeric during data cleaning.

---

## 3.3 Variable Classification Summary

### By Role
| Role | Variables |
|------|-----------|
| **Identifier** | `customerID` |
| **Target** | `Churn` |
| **Predictors** | All remaining 19 variables |

### By Data Type
| Type | Count | Variables |
|------|-------|-----------|
| **Numeric** | 3 | `SeniorCitizen`, `tenure`, `MonthlyCharges` |
| **Character (needs conversion)** | 1 | `TotalCharges` (should be numeric) |
| **Categorical (Binary)** | 4 | `gender`, `Partner`, `Dependents`, `PaperlessBilling` |
| **Categorical (Nominal)** | 8 | `Contract`, `PaymentMethod`, `InternetService`, `MultipleLines`, `OnlineSecurity`, `OnlineBackup`, `DeviceProtection`, `TechSupport`, `StreamingTV`, `StreamingMovies` |
| **Identifier** | 1 | `customerID` |
| **Target** | 1 | `Churn` |

### By Expected Predictive Strength (based on domain knowledge)

| Strength | Variables |
|----------|-----------|
| **Strong** | `tenure`, `Contract`, `MonthlyCharges`, `InternetService`, `TechSupport`, `OnlineSecurity` |
| **Moderate** | `PaymentMethod`, `PaperlessBilling`, `OnlineBackup`, `DeviceProtection`, `StreamingTV`, `StreamingMovies`, `Dependents`, `Partner` |
| **Weak** | `gender`, `PhoneService`, `MultipleLines` |

---

## 3.4 Dataset Size and Class Balance

| Metric | Value |
|--------|-------|
| **Total customers** | 7,043 |
| **Churned (Yes)** | ~1,869 (26.5%) |
| **Not churned (No)** | ~5,174 (73.5%) |
| **Imbalance ratio** | ~2.8:1 (Not Churned : Churned) |

**Implications of the class imbalance:**
- The dataset is **moderately imbalanced** — not extreme, but enough that accuracy alone is misleading
- A naïve model predicting "No Churn" for everyone would achieve ~73.5% accuracy — but would be useless
- We must evaluate using **recall, precision, F1, and ROC-AUC** rather than accuracy alone
- We may consider techniques like oversampling, undersampling, or cost-sensitive modeling, though the imbalance here is mild enough that standard logistic regression typically performs well

---

## 3.5 How to Download the Dataset

1. Go to [https://www.kaggle.com/datasets/blastchar/telco-customer-churn](https://www.kaggle.com/datasets/blastchar/telco-customer-churn)
2. Click **"Download"** (requires free Kaggle account)
3. Unzip the downloaded file
4. Rename the file to `telco_churn.csv` for simplicity
5. Place it in your SAS project's `Data/Raw/` folder

> **Alternative (no Kaggle account):** The dataset is also available on IBM's sample data repository and many GitHub mirrors. Search for "WA_Fn-UseC_-Telco-Customer-Churn.csv" on GitHub.
