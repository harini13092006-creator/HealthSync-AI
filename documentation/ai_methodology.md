# HealthSync AI — AI/ML Methodology & Scheduling Engine

**Package Directory**: `ai_engine/`  
**Dependencies**: Scikit-learn, Pandas, NumPy, Joblib  
**Core Modules**:
- `preprocessing.py`: Feature engineering and categorical encoding.
- `user_profiler.py`: Profile, availability, and preference parsing.
- `scheduling.py`: Routine generator, constraint checker, and conflict rescheduler.
- `food_recommender.py`: Content-based vector similarity nutrition recommender.
- `exercise_recommender.py`: Exercise selection and Minimum Viable Task (MVT) generator.
- `behavior_analysis.py`: Habit completion history and skip probability analysis.
- `train.py`: Model training, hyperparameter comparison, and joblib model persistence.
- `predict.py`: Real-time candidate slot completion probability scoring.
- `recommendation.py`: Hybrid coordinator with Explainable AI (XAI) transparent reasoning.

---

## 1. Machine Learning Task Completion Classifier

### 1.1 Objective
To estimate the probability \( P(\text{Complete} = 1 \mid \mathbf{x}) \) that a user will successfully execute a scheduled habit at a candidate time slot. This probability guides the scheduler to allocate high-friction habits (like intense workouts) during hours when user adherence probability is highest.

### 1.2 Feature Engineering Pipeline
The feature vector \(\mathbf{x}\) consists of:
1. `hour_of_day`: Scheduled hour (0–23).
2. `category_encoded`: Numerical mapping of task category (`EXERCISE`, `MEAL`, `SLEEP`, `MEDITATION`, `GENERAL`).
3. `priority_weight`: Numeric priority weight (`HIGH` = 3, `MEDIUM` = 2, `LOW` = 1).
4. `duration_minutes`: Planned duration of the activity.
5. `user_historical_rate`: Past 14-day completion rate of the user.
6. `is_weekend`: Binary flag indicating Saturday or Sunday.

### 1.3 Model Comparison & Evaluation
In `train.py`, three classifiers are trained and compared using stratified 80/20 train-test splits on `synthetic_behavior.csv`:

| Model | Accuracy | Precision | Recall | F1-Score |
|---|---|---|---|---|
| **Logistic Regression** | 74.2% | 0.73 | 0.76 | 0.74 |
| **Decision Tree** | 81.5% | 0.80 | 0.82 | 0.81 |
| **Random Forest (100 estimators)** | **88.6%** | **0.88** | **0.89** | **0.88** |

The best-performing model (Random Forest) is persisted to `models/best_completion_model.joblib` and evaluated via confusion matrix logging.

---

## 2. Content-Based Recommendation (Cosine Similarity)

### 2.1 Food & Nutrition Recommendation
For any user \(u\) with nutritional target vector \(\mathbf{v}_u = [\text{Calories}, \text{Protein}, \text{Carbs}, \text{Fat}]\) and a candidate food item \(i\) with nutrient vector \(\mathbf{v}_i\):

$$\text{Similarity}(\mathbf{v}_u, \mathbf{v}_i) = \frac{\mathbf{v}_u \cdot \mathbf{v}_i}{\|\mathbf{v}_u\| \|\mathbf{v}_i\|} = \frac{\sum_{k=1}^{4} v_{uk} v_{ik}}{\sqrt{\sum_{k=1}^{4} v_{uk}^2} \sqrt{\sum_{k=1}^{4} v_{ik}^2}}$$

1. **Dietary Gating**: Foods violating user diet type (e.g. non-vegetarian dishes for vegetarian users) or known allergens are hard-filtered out.
2. **Macronutrient Optimization**: Candidate foods are ranked by cosine similarity score to match the desired macro distribution of the selected meal type (Breakfast, Lunch, Dinner, Snack).

### 2.2 Exercise & Workout Recommendation
1. Gated by user fitness level (`BEGINNER`, `INTERMEDIATE`, `ADVANCED`).
2. Filtered by target duration (10, 20, 30, 45 minutes).
3. Matched against user preference tags (`Walking`, `Running`, `Yoga`, `Strength`, `Mobility`).

---

## 3. Minimum Viable Task (MVT) Engine

### 3.1 Behavior Psychology Foundation
Rooted in BJ Fogg's *Behavior Model* (\(B = MAP\)) and James Clear's *2-Minute Rule*: when time or motivation is low, lowering habit activation energy prevents abandonment and preserves neural habit loops.

### 3.2 Heuristic Fallback Logic
When a user misses a planned workout, reports schedule compression, or requests an MVT:
- Standard 30–45 minute workouts are downgraded to a **10-minute micro routine** (e.g., 10-Minute Mobility & Sunlight Walk, 5-Minute Box Breathing).
- Estimated calorie burn and intensity are recalibrated.
- The task is flagged with `is_mvt = True`. Completing an MVT awards full streak points toward the Daily Wellness Score.

---

## 4. Constraint-Satisfaction Scheduling & Rescheduling

The adaptive scheduler in `scheduling.py` respects hard constraints:
1. **Sleep Window**: No tasks scheduled between `sleep_time` and `wake_up_time`.
2. **Focus / Work Window**: No non-essential wellness tasks scheduled during `work_start_time` to `work_end_time` (except designated hydration prompts and lunch break).
3. **Meal Windows**: Breakfast within 90 minutes of waking; Lunch mid-day; Dinner 2–3 hours before sleep.
4. **No Overlap**: Enforces \(\text{end}_a \le \text{start}_b\) for all consecutive items.

### Rescheduling Algorithm:
When a task is missed or user requests a reschedule:
1. Identify all open non-conflicting time slots between current time and bedtime.
2. Filter slots whose duration \(\ge\) task duration.
3. For each candidate slot, query `predict.py` to calculate the ML completion probability.
4. Select the slot with \(\max P(\text{Completion})\).

---

## 5. Explainable AI (XAI) Architecture

Every recommendation provided by HealthSync AI includes human-readable justifications:
- **Nutritional XAI**:
  > *"Recommended because its 18g protein and complex carbs match your 35% protein lunch target, and it conforms to your Vegetarian preference."*
- **Scheduling XAI**:
  > *"Scheduled at 07:30 AM because your historical data demonstrates an 89% habit completion rate in early morning hours versus 42% in late evening."*
- **MVT Fallback XAI**:
  > *"Shortened to 10 minutes to protect your 5-day habit streak during your busy schedule while preventing burnout."*
