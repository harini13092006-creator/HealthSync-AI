"""
HealthSync AI - Feature Engineering & Preprocessing Pipeline
"""

import numpy as np
import pandas as pd
from sklearn.base import BaseEstimator, TransformerMixin
from sklearn.preprocessing import StandardScaler


TASK_TYPE_MAPPING = {
    'EXERCISE': 0,
    'MEDITATION': 1,
    'MEAL': 2,
    'HYDRATION': 3,
    'SLEEP_ROUTINE': 4,
    'BREAK': 5,
    'CUSTOM': 6,
}

ACTIVITY_LEVEL_MAPPING = {
    'SEDENTARY': 0,
    'LIGHTLY_ACTIVE': 1,
    'MODERATELY_ACTIVE': 2,
    'VERY_ACTIVE': 3,
}

PREVIOUS_STATUS_MAPPING = {
    'COMPLETED': 1,
    'SKIPPED': 0,
    'MISSED': 0,
    'RESCHEDULED': 0.5,
    'NONE': 0.5,
}


class TaskFeaturePreprocessor(BaseEstimator, TransformerMixin):
    """
    Transforms raw task, user profile, and behavioral features into a numerical matrix
    suitable for machine learning models.
    """
    def __init__(self):
        self.scaler = StandardScaler()
        self.feature_names = [
            'task_type_enc',
            'scheduled_hour',
            'day_of_week',
            'duration',
            'previous_completion_rate',
            'previous_task_status_enc',
            'activity_level_enc',
            'sleep_duration',
            'user_preference_score',
            'availability_flag',
        ]

    def fit(self, X, y=None):
        df = self._to_dataframe(X)
        features = self._extract_features(df)
        self.scaler.fit(features)
        return self

    def transform(self, X):
        df = self._to_dataframe(X)
        features = self._extract_features(df)
        return self.scaler.transform(features)

    def _to_dataframe(self, X):
        if isinstance(X, pd.DataFrame):
            return X.copy()
        elif isinstance(X, list):
            return pd.DataFrame(X)
        elif isinstance(X, dict):
            return pd.DataFrame([X])
        else:
            return pd.DataFrame(X)

    def _extract_features(self, df):
        task_types = df.get('task_type', 'CUSTOM').map(lambda t: TASK_TYPE_MAPPING.get(str(t).upper(), 6))
        scheduled_hours = df.get('scheduled_hour', 12).astype(float)
        days = df.get('day_of_week', 0).astype(float)
        durations = df.get('duration', 20).astype(float)
        prev_rates = df.get('previous_completion_rate', 0.5).astype(float)
        prev_statuses = df.get('previous_task_status', 'NONE').map(lambda s: PREVIOUS_STATUS_MAPPING.get(str(s).upper(), 0.5))
        activity_levels = df.get('activity_level', 'MODERATELY_ACTIVE').map(lambda a: ACTIVITY_LEVEL_MAPPING.get(str(a).upper(), 2))
        sleep_durations = df.get('sleep_duration', 7.5).astype(float)
        user_prefs = df.get('user_preference', 1.0).astype(float)
        availabilities = df.get('availability', 1).astype(float)

        feature_matrix = np.column_stack([
            task_types,
            scheduled_hours,
            days,
            durations,
            prev_rates,
            prev_statuses,
            activity_levels,
            sleep_durations,
            user_prefs,
            availabilities,
        ])
        return feature_matrix
