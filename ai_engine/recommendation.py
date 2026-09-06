"""
HealthSync AI - Unified Recommendation Coordinator
Integrates content-based food & exercise recommenders, meditation guidance,
and explainable ML suggestions.
"""

from pathlib import Path
import json

try:
    from ai_engine.food_recommender import FoodRecommender
    from ai_engine.exercise_recommender import ExerciseRecommender
    from ai_engine.scheduling import AdaptiveRoutinePlanner
    from ai_engine.predict import CompletionPredictor
    from ai_engine.behavior_analysis import BehaviorAnalyzer
except ImportError:
    from food_recommender import FoodRecommender
    from exercise_recommender import ExerciseRecommender
    from scheduling import AdaptiveRoutinePlanner
    from predict import CompletionPredictor
    from behavior_analysis import BehaviorAnalyzer


class HealthSyncRecommender:
    """
    Central hub for generating explainable recommendations across food,
    exercise, mindfulness, and adaptive scheduling.
    """

    def __init__(self):
        base_dir = Path(__file__).resolve().parent.parent
        self.dataset_dir = base_dir / 'dataset'

        # Load seed datasets
        foods = self._load_json(self.dataset_dir / 'foods.json')
        exercises = self._load_json(self.dataset_dir / 'exercises.json')
        meditations = self._load_json(self.dataset_dir / 'meditations.json')

        self.food_engine = FoodRecommender(foods)
        self.exercise_engine = ExerciseRecommender(exercises)
        self.meditation_sessions = meditations or []
        self.predictor = CompletionPredictor()
        self.planner = AdaptiveRoutinePlanner(self.predictor)

    def _load_json(self, path):
        if path.exists():
            try:
                with open(path, 'r', encoding='utf-8') as f:
                    return json.load(f)
            except Exception:
                return []
        return []

    def get_food_recommendations(self, diet_type='VEGETARIAN', preferences=None, cuisine='South Indian', goal='HEALTHY_EATING', meal_type=None, limit=5):
        return self.food_engine.recommend(
            user_diet_type=diet_type,
            user_preferences=preferences,
            cuisine=cuisine,
            goal=goal,
            meal_type=meal_type,
            top_k=limit
        )

    def get_exercise_recommendations(self, fitness_level='BEGINNER', preferred_categories=None, duration=30, activity_level='MODERATELY_ACTIVE', goal='FITNESS', limit=5):
        return self.exercise_engine.recommend(
            fitness_level=fitness_level,
            preferred_categories=preferred_categories,
            available_minutes=duration,
            activity_level=activity_level,
            goal=goal,
            top_k=limit
        )

    def get_minimum_viable_task(self, minutes=10, activity='Walking'):
        return self.exercise_engine.generate_minimum_viable_task(target_minutes=minutes, preferred_activity=activity)

    def get_meditation_recommendation(self, target_time='Morning', available_minutes=10):
        candidates = []
        for m in self.meditation_sessions:
            score = 1.0
            if abs(m.get('duration', 10) - available_minutes) <= 5:
                score += 1.5
            if target_time.lower() in m.get('target_time_of_day', '').lower() or 'anytime' in m.get('target_time_of_day', '').lower():
                score += 2.0
            candidates.append((score, m))

        candidates.sort(key=lambda x: x[0], reverse=True)
        if candidates:
            best = dict(candidates[0][1])
            best['explanation'] = (
                f"Selected {best['title']} because it fits your {available_minutes}-minute timeframe "
                f"and is optimized for {target_time.lower()} stress reduction."
            )
            return best
        return None

    def plan_routine(self, user_profile, goals=None, availability=None, food_pref=None, exercise_pref=None):
        return self.planner.generate_daily_routine(
            user_profile=user_profile,
            goals=goals,
            availability=availability,
            food_pref=food_pref,
            exercise_pref=exercise_pref
        )

    def suggest_reschedule(self, task, blocked_intervals, existing_tasks, user_history_summary=None):
        return self.planner.find_best_reschedule_slot(
            task=task,
            blocked_intervals=blocked_intervals,
            existing_tasks=existing_tasks,
            user_history_summary=user_history_summary
        )
