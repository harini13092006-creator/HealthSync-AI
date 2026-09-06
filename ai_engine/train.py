"""
HealthSync AI - Machine Learning Training Pipeline
Trains and compares Logistic Regression, Decision Tree, and Random Forest models
to predict task completion probability based on timing, user habits, and lifestyle context.
"""

import sys
import os
from pathlib import Path

# Ensure root directory is on Python path
root_dir = str(Path(__file__).resolve().parent.parent)
if root_dir not in sys.path:
    sys.path.insert(0, root_dir)

import json
import joblib
import numpy as np
import pandas as pd
from sklearn.ensemble import RandomForestClassifier
from sklearn.linear_model import LogisticRegression
from sklearn.metrics import accuracy_score, precision_score, recall_score, f1_score, confusion_matrix
from sklearn.model_selection import train_test_split
from sklearn.tree import DecisionTreeClassifier

from ai_engine.preprocessing import TaskFeaturePreprocessor


def generate_synthetic_behavior_dataset(output_path=None, num_samples=1200, random_seed=42):
    """
    Generates a realistic synthetic behavioral dataset with clear lifestyle signals:
    - User has high completion for morning meditation (07:00) and evening exercise (17:30 - 19:30).
    - User has low completion during work/college hours (09:00 - 16:00).
    - Sleep deprivation (<6h) reduces probability of exercise completion.
    - Long duration (>45 min) reduces probability for beginners.
    Clearly designated as SYNTHETIC DEVELOPMENT DATA.
    """
    np.random.seed(random_seed)

    task_types = ['EXERCISE', 'MEDITATION', 'MEAL', 'HYDRATION', 'SLEEP_ROUTINE', 'BREAK']
    activity_levels = ['SEDENTARY', 'LIGHTLY_ACTIVE', 'MODERATELY_ACTIVE', 'VERY_ACTIVE']
    previous_statuses = ['COMPLETED', 'SKIPPED', 'MISSED', 'RESCHEDULED', 'NONE']

    rows = []
    for _ in range(num_samples):
        ttype = np.random.choice(task_types, p=[0.25, 0.15, 0.25, 0.15, 0.1, 0.1])
        sched_hour = np.random.randint(6, 23)
        day_of_week = np.random.randint(0, 7)
        duration = np.random.choice([10, 15, 20, 30, 45, 60], p=[0.15, 0.2, 0.3, 0.2, 0.1, 0.05])
        prev_rate = round(np.random.uniform(0.3, 0.95), 2)
        prev_status = np.random.choice(previous_statuses)
        act_level = np.random.choice(activity_levels)
        sleep_dur = round(np.random.normal(7.2, 1.2), 1)
        sleep_dur = max(4.0, min(10.0, sleep_dur))
        user_pref = 1.0 if ttype in ['EXERCISE', 'MEDITATION', 'HYDRATION'] else 0.7

        # Availability: 09:00 to 16:00 is busy college/work on weekdays (0-4)
        is_busy = (day_of_week < 5 and 9 <= sched_hour < 16)
        availability = 0 if is_busy else 1

        prob = 0.5
        if availability == 0:
            prob -= 0.45

        if ttype == 'MEDITATION':
            if sched_hour in [6, 7, 8, 21, 22]:
                prob += 0.35
            else:
                prob -= 0.15
        elif ttype == 'EXERCISE':
            if sched_hour in [17, 18, 19]:
                prob += 0.38
            elif sched_hour in [6, 7]:
                prob -= 0.15
            elif sched_hour in [12, 13, 14]:
                prob -= 0.35
        elif ttype == 'MEAL':
            if sched_hour in [8, 9, 13, 14, 20, 21]:
                prob += 0.40
            else:
                prob -= 0.20
        elif ttype == 'HYDRATION':
            prob += 0.25

        prob += (prev_rate - 0.5) * 0.4
        if sleep_dur < 6.0:
            prob -= 0.20
        elif sleep_dur >= 7.5:
            prob += 0.10

        if duration > 40:
            prob -= 0.15

        prob = max(0.05, min(0.95, prob))
        completed = 1 if np.random.rand() < prob else 0

        rows.append({
            'task_type': ttype,
            'scheduled_hour': sched_hour,
            'day_of_week': day_of_week,
            'duration': duration,
            'previous_completion_rate': prev_rate,
            'previous_task_status': prev_status,
            'activity_level': act_level,
            'sleep_duration': sleep_dur,
            'user_preference': user_pref,
            'availability': availability,
            'completed': completed,
            'data_source': 'SYNTHETIC_DEVELOPMENT_SAMPLE'
        })

    df = pd.DataFrame(rows)
    if output_path:
        os.makedirs(os.path.dirname(output_path), exist_ok=True)
        df.to_csv(output_path, index=False)
        print(f"Synthetic behavior dataset saved to: {output_path} ({len(df)} rows)")
    return df


def train_and_evaluate_models():
    base_dir = Path(__file__).resolve().parent.parent
    dataset_file = base_dir / 'dataset' / 'synthetic_behavior.csv'
    models_dir = base_dir / 'ai_engine' / 'models'
    os.makedirs(models_dir, exist_ok=True)

    if not dataset_file.exists():
        print("Dataset not found. Generating synthetic behavioral dataset...")
        df = generate_synthetic_behavior_dataset(output_path=str(dataset_file))
    else:
        df = pd.read_csv(dataset_file)
        print(f"Loaded existing behavioral dataset from {dataset_file} ({len(df)} samples)")

    X = df[[
        'task_type',
        'scheduled_hour',
        'day_of_week',
        'duration',
        'previous_completion_rate',
        'previous_task_status',
        'activity_level',
        'sleep_duration',
        'user_preference',
        'availability',
    ]]
    y = df['completed'].values

    X_train, X_test, y_train, y_test = train_test_split(
        X, y, test_size=0.20, random_state=42, stratify=y
    )

    preprocessor = TaskFeaturePreprocessor()
    X_train_scaled = preprocessor.fit_transform(X_train)
    X_test_scaled = preprocessor.transform(X_test)

    models = {
        'LogisticRegression': LogisticRegression(random_state=42, max_iter=1000),
        'DecisionTree': DecisionTreeClassifier(max_depth=6, random_state=42),
        'RandomForest': RandomForestClassifier(n_estimators=100, max_depth=8, random_state=42),
    }

    metrics_report = {}
    best_name = None
    best_f1 = -1.0
    best_estimator = None

    print("\n--- Model Training & Comparison Evaluation ---")
    for name, model in models.items():
        model.fit(X_train_scaled, y_train)
        y_pred = model.predict(X_test_scaled)

        acc = float(accuracy_score(y_test, y_pred))
        prec = float(precision_score(y_test, y_pred, zero_division=0))
        rec = float(recall_score(y_test, y_pred, zero_division=0))
        f1 = float(f1_score(y_test, y_pred, zero_division=0))
        cm = confusion_matrix(y_test, y_pred).tolist()

        metrics_report[name] = {
            'accuracy': round(acc, 4),
            'precision': round(prec, 4),
            'recall': round(rec, 4),
            'f1_score': round(f1, 4),
            'confusion_matrix': cm,
        }

        print(f"[{name}] Accuracy: {acc:.4f} | Precision: {prec:.4f} | Recall: {rec:.4f} | F1: {f1:.4f}")

        if f1 > best_f1:
            best_f1 = f1
            best_name = name
            best_estimator = model

    print(f"\nBest Performing Model: {best_name} (F1 Score: {best_f1:.4f})")

    save_payload = {
        'model_name': best_name,
        'model': best_estimator,
        'preprocessor': preprocessor,
        'metrics': metrics_report[best_name],
    }

    model_path = models_dir / 'best_completion_model.joblib'
    joblib.dump(save_payload, model_path)
    print(f"Saved best model artifact to: {model_path}")

    report_path = models_dir / 'metrics_report.json'
    with open(report_path, 'w', encoding='utf-8') as f:
        json.dump(metrics_report, f, indent=2)
    print(f"Saved evaluation metrics report to: {report_path}")

    return best_name, metrics_report


if __name__ == '__main__':
    train_and_evaluate_models()
