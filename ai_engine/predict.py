"""
HealthSync AI - Task Completion Probability Predictor
Infers likelihood of task completion given user profile, hour, day, and habit history.
"""

from pathlib import Path
import joblib
import pandas as pd


class CompletionPredictor:
    """
    Inference service for ML-based task completion prediction.
    """

    def __init__(self, model_path=None):
        if model_path is None:
            base_dir = Path(__file__).resolve().parent.parent
            model_path = base_dir / 'ai_engine' / 'models' / 'best_completion_model.joblib'
        self.model_path = Path(model_path)
        self.loaded_data = None
        self._load_model()

    def _load_model(self):
        if self.model_path.exists():
            try:
                self.loaded_data = joblib.load(self.model_path)
            except Exception as e:
                print(f"Warning: Could not load model from {self.model_path}: {e}")
                self.loaded_data = None

    def predict_completion_probability(self, task_type='EXERCISE', scheduled_hour=18, day_of_week=0, duration=20, previous_completion_rate=0.7, previous_task_status='COMPLETED', activity_level='MODERATELY_ACTIVE', sleep_duration=7.5, user_preference=1.0, availability=1):
        """
        Returns probability between 0.0 and 1.0 of the user completing the task.
        Falls back to intelligent rule-based scoring if model is unavailable.
        """
        if self.loaded_data is not None:
            try:
                model = self.loaded_data['model']
                preprocessor = self.loaded_data['preprocessor']

                df = pd.DataFrame([{
                    'task_type': task_type,
                    'scheduled_hour': scheduled_hour,
                    'day_of_week': day_of_week,
                    'duration': duration,
                    'previous_completion_rate': previous_completion_rate,
                    'previous_task_status': previous_task_status,
                    'activity_level': activity_level,
                    'sleep_duration': sleep_duration,
                    'user_preference': user_preference,
                    'availability': availability,
                }])

                X_scaled = preprocessor.transform(df)
                if hasattr(model, 'predict_proba'):
                    probs = model.predict_proba(X_scaled)
                    # Return class 1 probability
                    return round(float(probs[0][1]), 3)
                else:
                    pred = model.predict(X_scaled)
                    return 0.85 if pred[0] == 1 else 0.25
            except Exception as e:
                pass

        # Robust rule-based baseline fallback
        score = 0.5
        if availability == 0:
            score -= 0.4
        if task_type == 'EXERCISE' and 17 <= scheduled_hour <= 20:
            score += 0.3
        elif task_type == 'MEDITATION' and (6 <= scheduled_hour <= 8 or 21 <= scheduled_hour <= 22):
            score += 0.3
        if sleep_duration >= 7.0:
            score += 0.1
        score += (previous_completion_rate - 0.5) * 0.2
        return round(max(0.05, min(0.95, score)), 3)
