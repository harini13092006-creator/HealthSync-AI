import unittest
from ai_engine.preprocessing import TaskFeaturePreprocessor
from ai_engine.predict import CompletionPredictor
from ai_engine.food_recommender import FoodRecommender
from ai_engine.exercise_recommender import ExerciseRecommender
from ai_engine.behavior_analysis import BehaviorAnalyzer
from ai_engine.scheduling import AdaptiveRoutinePlanner, ScheduleConflictDetector
from ai_engine.user_profiler import UserProfiler


class AIEngineUnitTests(unittest.TestCase):
    def test_preprocessor_matrix_dimensions(self):
        pre = TaskFeaturePreprocessor()
        data = [
            {'task_type': 'EXERCISE', 'scheduled_hour': 18, 'day_of_week': 1, 'duration': 30, 'previous_completion_rate': 0.8, 'previous_task_status': 'COMPLETED', 'activity_level': 'MODERATELY_ACTIVE', 'sleep_duration': 7.5, 'user_preference': 1.0, 'availability': 1},
            {'task_type': 'MEDITATION', 'scheduled_hour': 7, 'day_of_week': 2, 'duration': 10, 'previous_completion_rate': 0.9, 'previous_task_status': 'COMPLETED', 'activity_level': 'LIGHTLY_ACTIVE', 'sleep_duration': 8.0, 'user_preference': 1.0, 'availability': 1}
        ]
        transformed = pre.fit_transform(data)
        self.assertEqual(transformed.shape, (2, 10))

    def test_completion_prediction_bounds(self):
        predictor = CompletionPredictor()
        prob = predictor.predict_completion_probability(
            task_type='EXERCISE',
            scheduled_hour=18,
            duration=30,
            previous_completion_rate=0.85
        )
        self.assertGreaterEqual(prob, 0.0)
        self.assertLessEqual(prob, 1.0)

    def test_food_recommender_diet_filter_and_explanation(self):
        foods = [
            {'name': 'Chicken Salad', 'diet_type': 'NON_VEGETARIAN', 'cuisine': 'Continental', 'meal_type': 'LUNCH', 'tags': ['protein'], 'ingredients': ['Chicken']},
            {'name': 'Idli Sambar', 'diet_type': 'VEGETARIAN', 'cuisine': 'South Indian', 'meal_type': 'BREAKFAST', 'tags': ['steamed'], 'ingredients': ['Rice', 'Dal']},
            {'name': 'Tofu Stir Fry', 'diet_type': 'VEGAN', 'cuisine': 'Asian', 'meal_type': 'DINNER', 'tags': ['vegan'], 'ingredients': ['Tofu', 'Vegetables']},
        ]
        rec = FoodRecommender(foods)
        results = rec.recommend(user_diet_type='VEGETARIAN', cuisine='South Indian', meal_type='BREAKFAST')
        self.assertEqual(len(results), 1)
        self.assertEqual(results[0]['name'], 'Idli Sambar')
        self.assertIn('explanation', results[0])
        self.assertIn('South Indian', results[0]['explanation'])

    def test_exercise_recommender_and_mvt(self):
        exercises = [
            {'name': 'Brisk Walk', 'category': 'WALKING', 'difficulty': 'BEGINNER', 'duration': 30, 'equipment': 'NONE', 'tags': []},
            {'name': 'Marathon Training', 'category': 'RUNNING', 'difficulty': 'ADVANCED', 'duration': 60, 'equipment': 'NONE', 'tags': []},
        ]
        rec = ExerciseRecommender(exercises)
        results = rec.recommend(fitness_level='BEGINNER', preferred_categories=['WALKING'], available_minutes=30)
        self.assertEqual(results[0]['name'], 'Brisk Walk')

        # Test Minimum Viable Task generator
        mvt = rec.generate_minimum_viable_task(target_minutes=10, preferred_activity='Walking')
        self.assertTrue(mvt['is_mvt'])
        self.assertEqual(mvt['total_duration'], 10)
        self.assertEqual(len(mvt['breakdown']), 3)

    def test_behavior_pattern_detection(self):
        # 4 records: 2 morning missed exercise, 2 evening completed exercise
        records = [
            {'task_type': 'EXERCISE', 'scheduled_time': '06:00:00', 'completed': False, 'skipped': True, 'rescheduled': False},
            {'task_type': 'EXERCISE', 'scheduled_time': '06:00:00', 'completed': False, 'skipped': True, 'rescheduled': False},
            {'task_type': 'EXERCISE', 'scheduled_time': '18:00:00', 'completed': True, 'skipped': False, 'rescheduled': False},
            {'task_type': 'EXERCISE', 'scheduled_time': '19:00:00', 'completed': True, 'skipped': False, 'rescheduled': False},
        ]
        analysis = BehaviorAnalyzer.analyze_records(records)
        self.assertEqual(analysis['completion_rate'], 0.5)
        self.assertIn('evening', analysis['patterns'][0].lower())

    def test_schedule_conflict_detection(self):
        blocked = [(9 * 60, 16 * 60, 'College')]
        # 10:00 is within 09:00 - 16:00
        avail, reason = ScheduleConflictDetector.is_slot_available(10 * 60, 30, blocked)
        self.assertFalse(avail)
        self.assertEqual(reason, 'College')

        # 17:00 is free
        avail_free, _ = ScheduleConflictDetector.is_slot_available(17 * 60, 30, blocked)
        self.assertTrue(avail_free)


if __name__ == '__main__':
    unittest.main()
