"""
HealthSync AI - Exercise Recommendation and Minimum Viable Task (MVT) Engine
Provides accessible movement routines and quick fallback micro-workouts.
NOTICE: General wellness physical activities; NOT prescribed medical exercise therapy.
"""


class ExerciseRecommender:
    """
    Ranks physical wellness routines and generates adaptive Minimum Viable Tasks (MVT).
    """

    def __init__(self, exercise_items=None):
        self.exercise_items = exercise_items or []

    def recommend(self, fitness_level='BEGINNER', preferred_categories=None, available_minutes=30, activity_level='MODERATELY_ACTIVE', goal='FITNESS', top_k=5):
        preferred_categories = [p.upper() for p in (preferred_categories or [])]

        ranked = []
        for item in self.exercise_items:
            item_cat = item.get('category', '').upper()
            item_diff = item.get('difficulty', '').upper()
            item_dur = item.get('duration', 20)

            score = 1.0

            # Preference alignment
            if any(p in item_cat or item_cat in p for p in preferred_categories):
                score += 2.0

            # Fitness level alignment
            if item_diff == fitness_level.upper():
                score += 1.5
            elif fitness_level.upper() == 'BEGINNER' and item_diff == 'ADVANCED':
                score -= 1.0  # Avoid overwhelming beginners

            # Duration fit
            duration_diff = abs(item_dur - available_minutes)
            if duration_diff == 0:
                score += 1.5
            elif duration_diff <= 10:
                score += 0.5
            else:
                score -= (duration_diff / 20.0)

            explanation = self._generate_explanation(item, fitness_level, available_minutes, preferred_categories)

            item_copy = dict(item)
            item_copy['recommendation_score'] = round(score, 2)
            item_copy['explanation'] = explanation
            ranked.append(item_copy)

        ranked.sort(key=lambda x: x['recommendation_score'], reverse=True)
        return ranked[:top_k]

    def generate_minimum_viable_task(self, target_minutes=10, preferred_activity='Walking'):
        """
        Generates an adaptive Minimum Viable Task (MVT) when user has constrained time.
        Example for 10 minutes: 2 min warm-up, 6 min moderate walking, 2 min stretching.
        """
        minutes = max(5, min(target_minutes, 20))
        warmup_m = max(1, int(round(minutes * 0.2)))
        cooldown_m = max(1, int(round(minutes * 0.2)))
        main_m = minutes - warmup_m - cooldown_m

        breakdown = [
            {
                'phase': 'Warm-Up',
                'duration_minutes': warmup_m,
                'activity': 'Gentle joint circles, shoulder shrugs, and deep nasal breathing',
                'instructions': 'Wake up your joints and elevate your core temperature smoothly.'
            },
            {
                'phase': 'Main Movement',
                'duration_minutes': main_m,
                'activity': f"Paced {preferred_activity.lower()} or brisk marching in place",
                'instructions': f"Keep a steady, rhythmic pace. Perfect for busy days to maintain daily movement consistency."
            },
            {
                'phase': 'Cool-Down & Stretch',
                'duration_minutes': cooldown_m,
                'activity': 'Calf stretches, hamstring lengthening, and gentle spinal twists',
                'instructions': 'Release physical tension and normalize your breathing rate.'
            }
        ]

        return {
            'title': f"{minutes}-Minute Quick Reset ({preferred_activity})",
            'total_duration': minutes,
            'is_mvt': True,
            'breakdown': breakdown,
            'explanation': (
                f"Generated as a Minimum Viable Task: When your schedule is tight, doing {minutes} focused minutes "
                f"maintains your habit momentum and cardiovascular wellness far better than skipping entirely."
            )
        }

    def _generate_explanation(self, item, fitness_level, available_minutes, preferred_categories):
        reasons = []
        item_cat = item.get('category', '').title()
        if any(p in item_cat.upper() for p in preferred_categories):
            reasons.append(f"matches your preferred movement style ({item_cat})")
        if item.get('difficulty', '').upper() == fitness_level.upper():
            reasons.append(f"suits your {fitness_level.lower()} fitness pace")
        if abs(item.get('duration', 20) - available_minutes) <= 5:
            reasons.append(f"comfortably fits into your {available_minutes}-minute daily routine window")

        if not reasons:
            reasons.append("promotes balanced mobility and cardiovascular health")

        return f"Recommended because it " + ", and ".join(reasons) + "."
