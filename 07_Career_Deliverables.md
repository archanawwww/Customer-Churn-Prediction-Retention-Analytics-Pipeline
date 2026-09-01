# Career Deliverables

## How to Describe This Project on Your Resume

**AI Product Management Intern | [Your Name/Fictional Company]**
*   **Led an end-to-end churn prediction product initiative**, analyzing 7K+ customer records in SAS to identify behavioral churn drivers, resulting in a prioritized roadmap for retention experiments.
*   **Built a logistic regression model (PROC LOGISTIC) and k-means segmentation pipeline**, achieving [X]% recall, identifying $X in monthly revenue at high risk of churn.
*   **Translated statistical outputs into product strategy**, translating model odds ratios into 5 specific product recommendations (e.g., automated 1-click contract upgrades, onboarding flows) prioritized via the RICE framework.
*   **Designed an operational risk-scoring pipeline and automated KPI dashboard**, bridging the gap between data science outputs and Customer Success intervention workflows.

## 60-Second Interview Pitch

*"In this project, I built an end-to-end customer churn prediction system using SAS. Rather than just treating it as a data science exercise, I approached it as an AI Product Manager.* 

*I started by defining the business problem and determining that 'recall' was our most critical metric because the cost of missing a churner is much higher than the cost of a false alarm.*

*I cleaned the data, engineered behavioral features, and segmented users using k-means clustering. I then built a logistic regression model to score each customer's risk.*

*But the real value was in the translation: I mapped the model's statistical drivers—like month-to-month contracts and lack of tech support—into specific product gaps. I proposed a prioritized roadmap of product interventions, like a 1-click contract upgrade feature, and designed A/B tests to validate if those interventions actually caused retention rather than just correlating with it. Finally, I designed the operational pipeline to feed these risk scores directly to the Customer Success team's CRM."*

## 10 Likely Interview Questions and Strong Answers

**1. Why did you use Logistic Regression instead of a more complex model like XGBoost or a Neural Network?**
*Answer:* "For a business problem like churn, interpretability is often more important than raw accuracy. A neural net might give a slight accuracy bump, but logistic regression gives us odds ratios for every feature. When a PM or Customer Success rep asks *why* a customer is at risk, logistic regression allows me to point to specific drivers (like 'lack of tech support'). Also, with ~7K records, simpler models are less prone to overfitting."

**2. How did you handle the class imbalance in the dataset?**
*Answer:* "The churn rate was about 26.5%, which is a moderate imbalance. Because it wasn't extreme (like 1%), standard logistic regression handled it adequately. However, I handled the business impact of the imbalance by focusing on Recall and Precision rather than Accuracy, and by manually calibrating the risk threshold based on intervention costs rather than accepting the default 0.5 cutoff."

**3. Why did you exclude the target variable (Churn) from your clustering/segmentation?**
*Answer:* "Segmentation should describe customer *behavior* and value, not the outcome. If I include churn, the algorithm just splits the data into 'churners' and 'non-churners'. By clustering on tenure, spend, and engagement without the target variable, I created segments like 'High-Value Loyalists' or 'Disengaged Mainstream'—which is much more actionable for product strategy."

**4. You found that customers without Tech Support churn more. Should we give everyone free Tech Support?**
*Answer:* "Not necessarily. The model identified a *correlation*, not causation. It's possible that customers who buy tech support are inherently more committed to our ecosystem, and giving it away for free to uncommitted customers won't change their behavior. As a PM, my next step would be to run an A/B test—offering a free trial to a control and treatment group—to prove if the intervention actually *causes* a reduction in churn before rolling it out widely."

**5. How would you know if your model starts performing poorly in production?**
*Answer:* "I would monitor two things: Data Drift and Model Decay. For data drift, I'd check if the distributions of our input features change—for example, if a marketing campaign brings in thousands of 0-tenure customers. For model decay, I would do a monthly look-back, comparing last month's predictions to this month's actual churn, monitoring the ROC-AUC and Recall. If they drop below a set threshold, it triggers a retraining."

**6. If the Customer Success team can only call 100 people a week, how do you use this model?**
*Answer:* "I would sort the scored dataset by `Churn_Probability` descending. Then, I would calculate the expected revenue at risk (Probability × Monthly Charges). I would give the CS team the top 100 customers sorted by Expected Revenue at Risk, ensuring they spend their limited time saving the most valuable accounts."

**7. Why is Recall more important than Precision for churn?**
*Answer:* "Because the costs are asymmetric. A false negative (missing a churner) costs the company a customer's entire lifetime value. A false positive (flagging a non-churner) just costs the price of an email or a 5-minute phone call. I'm willing to accept more false positives to ensure I don't miss the actual churners."

**8. What was the most challenging part of the data cleaning process?**
*Answer:* "Handling `TotalCharges`. It was imported as a character variable because some values were blank. I realized those blanks weren't random missing data—they belonged to new customers with 0 tenure who hadn't been billed yet. Instead of deleting those rows, which would bias the model against new customers, I converted the column to numeric and logically imputed a value of $0."

**9. How do you measure the success of this project? (Trick question)**
*Answer:* "Model metrics like ROC-AUC or F1-score measure the *model's* success, but not the *project's* success. The business success metrics are: Did the overall churn rate decrease? Did our retention save rate increase? And did the ROI of our retention interventions go up? A perfect model is useless if it doesn't lead to product or operational changes that actually retain customers."

**10. How did you structure your SAS code for a production environment?**
*Answer:* "I modularized the code into distinct stages (00_import, 01_cleaning, 02_eda, 03_modeling). I used permanent libraries instead of the WORK library so datasets persist. I used macros and standard naming conventions, and thoroughly commented the rationale behind every data decision so an auditor or engineer could easily trace my logic."
