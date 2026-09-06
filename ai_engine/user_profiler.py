"""
HealthSync AI - User Profiling and Lifestyle Constraint Parser
"""

from datetime import datetime, time, timedelta


class UserProfiler:
    """
    Parses user attributes, lifestyle timings, and daily constraints
    for personalized routine generation and recommendation filtering.
    """

    @staticmethod
    def calculate_daily_water_target(weight_kg, activity_level='MODERATELY_ACTIVE'):
        """
        Calculates non-medical recommended daily water intake in ml based on weight and activity.
        Standard baseline: ~35ml per kg of body weight + activity adjustment.
        """
        weight = weight_kg if (weight_kg and weight_kg > 30) else 65.0
        base_ml = weight * 35.0

        multiplier = {
            'SEDENTARY': 1.0,
            'LIGHTLY_ACTIVE': 1.1,
            'MODERATELY_ACTIVE': 1.2,
            'VERY_ACTIVE': 1.35
        }.get(activity_level, 1.15)

        recommended = int(round(base_ml * multiplier / 250.0) * 250)
        return max(2000, min(recommended, 3800))

    @staticmethod
    def parse_time_to_minutes(t):
        """Converts datetime.time or 'HH:MM:SS' / 'HH:MM' string to minutes from midnight."""
        if isinstance(t, str):
            parts = [int(p) for p in t.split(':')[:2]]
            return parts[0] * 60 + parts[1]
        elif isinstance(t, (time, datetime)):
            return t.hour * 60 + t.minute
        return 0

    @staticmethod
    def minutes_to_time(minutes):
        """Converts integer minutes from midnight back to datetime.time."""
        minutes = int(minutes) % (24 * 60)
        h = minutes // 60
        m = minutes % 60
        return time(h, m)

    @classmethod
    def get_waking_window(cls, wake_time, sleep_time):
        """
        Returns (wake_minutes, sleep_minutes, total_waking_minutes).
        """
        wake_m = cls.parse_time_to_minutes(wake_time)
        sleep_m = cls.parse_time_to_minutes(sleep_time)

        if sleep_m <= wake_m:
            # Spans past midnight
            waking_duration = (24 * 60 - wake_m) + sleep_m
        else:
            waking_duration = sleep_m - wake_m

        return wake_m, sleep_m, waking_duration
