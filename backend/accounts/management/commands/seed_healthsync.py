import json
from pathlib import Path
from django.core.management.base import BaseCommand
from django.utils import timezone
from datetime import time, timedelta, datetime

from accounts.models import User
from profiles.models import HealthProfile, UserGoal, FoodPreference, ExercisePreference, DailyAvailability
from nutrition.models import FoodItem
from exercise.models import ExerciseItem
from meditation.models import MeditationSession
from tasks.models import DailyTask, BehaviorRecord
from health_monitoring.models import ActivityRecord, SleepRecord, WaterRecord, MealRecord, MeditationRecord
from analytics.models import DailyWellnessScore


class Command(BaseCommand):
    help = 'Seed HealthSync AI initial datasets, items, and demonstration data'

    def handle(self, *args, **options):
        self.stdout.write(self.style.NOTICE('Beginning HealthSync AI database seed...'))

        base_dir = Path(__file__).resolve().parent.parent.parent.parent.parent
        dataset_dir = base_dir / 'dataset'

        # 1. Seed Foods
        foods_file = dataset_dir / 'foods.json'
        if foods_file.exists():
            with open(foods_file, 'r', encoding='utf-8') as f:
                foods_data = json.load(f)
            count = 0
            for item in foods_data:
                _, created = FoodItem.objects.update_or_create(
                    name=item['name'],
                    defaults={
                        'meal_type': item['meal_type'],
                        'diet_type': item['diet_type'],
                        'calories': item['calories'],
                        'protein': item['protein'],
                        'carbohydrates': item['carbohydrates'],
                        'fat': item['fat'],
                        'ingredients': item.get('ingredients', []),
                        'cuisine': item.get('cuisine', 'Indian'),
                        'tags': item.get('tags', []),
                        'description': item.get('description', ''),
                    }
                )
                if created:
                    count += 1
            self.stdout.write(self.style.SUCCESS(f"Loaded {len(foods_data)} food items ({count} new)."))

        # 2. Seed Exercises
        exercises_file = dataset_dir / 'exercises.json'
        if exercises_file.exists():
            with open(exercises_file, 'r', encoding='utf-8') as f:
                exercises_data = json.load(f)
            count = 0
            for item in exercises_data:
                _, created = ExerciseItem.objects.update_or_create(
                    name=item['name'],
                    defaults={
                        'category': item['category'],
                        'difficulty': item['difficulty'],
                        'duration': item['duration'],
                        'equipment': item['equipment'],
                        'tags': item.get('tags', []),
                        'instructions': item.get('instructions', ''),
                        'calories_burned_est': item.get('calories_burned_est', 80.0),
                    }
                )
                if created:
                    count += 1
            self.stdout.write(self.style.SUCCESS(f"Loaded {len(exercises_data)} exercises ({count} new)."))

        # 3. Seed Meditations
        meditations_file = dataset_dir / 'meditations.json'
        if meditations_file.exists():
            with open(meditations_file, 'r', encoding='utf-8') as f:
                meditations_data = json.load(f)
            count = 0
            for item in meditations_data:
                _, created = MeditationSession.objects.update_or_create(
                    title=item['title'],
                    defaults={
                        'session_type': item['session_type'],
                        'duration': item['duration'],
                        'description': item.get('description', ''),
                        'guide_steps': item.get('guide_steps', []),
                        'target_time_of_day': item.get('target_time_of_day', 'Anytime'),
                    }
                )
                if created:
                    count += 1
            self.stdout.write(self.style.SUCCESS(f"Loaded {len(meditations_data)} meditation sessions ({count} new)."))

        # 4. Seed Demo User
        demo_email = 'demo@healthsync.ai'
        user, created = User.objects.get_or_create(
            email=demo_email,
            defaults={'name': 'Harini Demo User', 'is_staff': True}
        )
        if created:
            user.set_password('HealthSync@2026')
            user.save()
            self.stdout.write(self.style.SUCCESS(f"Created demo user: {demo_email} with password: HealthSync@2026"))
        else:
            user.set_password('HealthSync@2026')
            user.save()
            self.stdout.write(self.style.NOTICE(f"Updated demo user password: {demo_email}"))

        # Profile
        HealthProfile.objects.update_or_create(
            user=user,
            defaults={
                'age': 20,
                'height': 165.0,
                'weight': 58.0,
                'activity_level': HealthProfile.ActivityLevel.MODERATELY_ACTIVE,
                'wake_time': time(6, 30),
                'sleep_time': time(22, 30),
            }
        )

        # Goals
        UserGoal.objects.update_or_create(
            user=user,
            goal_type=UserGoal.GoalType.FITNESS,
            defaults={'target': 'Maintain active 8000 daily steps and regular stretching'}
        )
        UserGoal.objects.update_or_create(
            user=user,
            goal_type=UserGoal.GoalType.HEALTHY_EATING,
            defaults={'target': 'Eat balanced vegetarian meals with adequate protein'}
        )
        UserGoal.objects.update_or_create(
            user=user,
            goal_type=UserGoal.GoalType.HYDRATION,
            defaults={'target': 'Drink 2500ml water daily'}
        )

        # Food Preference
        FoodPreference.objects.update_or_create(
            user=user,
            defaults={
                'diet_type': FoodPreference.DietType.VEGETARIAN,
                'preferences': ['South Indian', 'Idli', 'Sambar', 'Lentils', 'Fresh Fruits'],
                'allergies': ['Peanuts'],
                'cuisine': 'South Indian'
            }
        )

        # Exercise Preference
        ExercisePreference.objects.update_or_create(
            user=user,
            defaults={
                'preferred_exercises': ['Walking', 'Yoga', 'Stretching'],
                'preferred_duration': 30,
                'fitness_level': ExercisePreference.FitnessLevel.BEGINNER
            }
        )

        # Availability (Monday through Sunday)
        for day_idx in range(7):
            DailyAvailability.objects.update_or_create(
                user=user,
                day=day_idx,
                defaults={
                    'start_time': time(7, 0),
                    'end_time': time(22, 0),
                    'unavailable_periods': [
                        {'start': '09:00', 'end': '16:00', 'label': 'College/Classes'},
                        {'start': '16:00', 'end': '17:00', 'label': 'Travel/Commute'}
                    ] if day_idx < 5 else [
                        {'start': '14:00', 'end': '16:00', 'label': 'Weekend Study'}
                    ]
                }
            )

        # Today's Tasks
        today = timezone.localdate() if timezone.is_aware(timezone.now()) else timezone.now().date()
        DailyTask.objects.filter(user=user, date=today).delete()

        sample_tasks = [
            {'title': 'Morning Box Breathing & Reset', 'type': DailyTask.TaskType.MEDITATION, 'time': time(7, 0), 'duration': 10, 'priority': DailyTask.Priority.HIGH, 'status': DailyTask.Status.COMPLETED, 'expl': 'Scheduled right after your 6:30 AM wake-up for morning alertness.'},
            {'title': 'Brisk Morning Walk', 'type': DailyTask.TaskType.EXERCISE, 'time': time(7, 30), 'duration': 30, 'priority': DailyTask.Priority.HIGH, 'status': DailyTask.Status.COMPLETED, 'expl': 'Scheduled before college hours to kickstart your daily metabolic rate.'},
            {'title': 'Nutritious Breakfast - Steamed Idli & Sambar', 'type': DailyTask.TaskType.MEAL, 'time': time(8, 15), 'duration': 30, 'priority': DailyTask.Priority.HIGH, 'status': DailyTask.Status.COMPLETED, 'expl': 'Matches your South Indian vegetarian preference with easily digestible complex carbs.'},
            {'title': 'Mid-Morning Hydration Refresher', 'type': DailyTask.TaskType.HYDRATION, 'time': time(10, 30), 'duration': 5, 'priority': DailyTask.Priority.MEDIUM, 'status': DailyTask.Status.COMPLETED, 'expl': 'Optimal hydration window during morning lectures.'},
            {'title': 'Wholesome Lunch - Brown Rice & Moong Dal', 'type': DailyTask.TaskType.MEAL, 'time': time(13, 0), 'duration': 30, 'priority': DailyTask.Priority.HIGH, 'status': DailyTask.Status.COMPLETED, 'expl': 'Balanced complete plant protein to prevent afternoon lethargy.'},
            {'title': 'Afternoon Hydration Boost', 'type': DailyTask.TaskType.HYDRATION, 'time': time(15, 0), 'duration': 5, 'priority': DailyTask.Priority.MEDIUM, 'status': DailyTask.Status.COMPLETED, 'expl': 'Keeps energy steady during study sessions.'},
            {'title': 'Evening Post-College Walk & Mobility', 'type': DailyTask.TaskType.EXERCISE, 'time': time(17, 30), 'duration': 25, 'priority': DailyTask.Priority.HIGH, 'status': DailyTask.Status.PENDING, 'expl': 'Scheduled after 17:00 commute finishes, before evening dinner.'},
            {'title': 'Light Balanced Dinner - Roti & Palak Paneer', 'type': DailyTask.TaskType.MEAL, 'time': time(20, 0), 'duration': 30, 'priority': DailyTask.Priority.HIGH, 'status': DailyTask.Status.PENDING, 'expl': 'Light dinner scheduled 2.5 hours prior to bed for restful digestion.'},
            {'title': 'Sleep Wind-down & Progressive Relaxation', 'type': DailyTask.TaskType.SLEEP_ROUTINE, 'time': time(21, 30), 'duration': 15, 'priority': DailyTask.Priority.MEDIUM, 'status': DailyTask.Status.PENDING, 'expl': 'Prepares nervous system for planned 22:30 sleep schedule.'},
        ]

        for t in sample_tasks:
            DailyTask.objects.create(
                user=user,
                title=t['title'],
                task_type=t['type'],
                date=today,
                scheduled_time=t['time'],
                duration=t['duration'],
                priority=t['priority'],
                status=t['status'],
                completed_at=timezone.now() if t['status'] == DailyTask.Status.COMPLETED else None,
                ai_explanation=t['expl']
            )

        # Health records for today
        ActivityRecord.objects.update_or_create(
            user=user,
            date=today,
            defaults={
                'steps': 6420,
                'active_minutes': 45,
                'exercise_minutes': 30,
                'calories_burned': 240.0
            }
        )

        SleepRecord.objects.update_or_create(
            user=user,
            date=today,
            defaults={
                'sleep_start': timezone.now() - timedelta(hours=8, minutes=30),
                'sleep_end': timezone.now() - timedelta(hours=1),
                'duration': 7.5,
                'quality_rating': 4
            }
        )

        # Water records (1750 ml logged today)
        WaterRecord.objects.filter(user=user, date=today).delete()
        WaterRecord.objects.create(user=user, date=today, quantity_ml=500, time=time(7, 15))
        WaterRecord.objects.create(user=user, date=today, quantity_ml=250, time=time(9, 30))
        WaterRecord.objects.create(user=user, date=today, quantity_ml=500, time=time(12, 45))
        WaterRecord.objects.create(user=user, date=today, quantity_ml=500, time=time(15, 10))

        # Daily Wellness Score calculation
        DailyWellnessScore.objects.update_or_create(
            user=user,
            date=today,
            defaults={
                'total_score': 82.0,
                'task_adherence_score': 20.0,
                'activity_score': 18.0,
                'hydration_score': 18.0,
                'sleep_score': 18.0,
                'meditation_score': 8.0,
                'summary_text': 'Great progress today! You completed 6/9 tasks, drank 1750ml water, and had 7.5 hours of restful sleep.'
            }
        )

        # Behavior Records for ML pattern detection:
        # e.g. Shows user consistently completes evening workouts around 17:30-19:30 and misses 06:00 AM workouts
        BehaviorRecord.objects.filter(user=user).delete()
        for d in range(14):
            day_date = today - timedelta(days=d)
            weekday = day_date.weekday()
            # 6:00 AM exercise - missed/skipped 80% of time
            BehaviorRecord.objects.create(
                user=user,
                task_type='EXERCISE',
                scheduled_time=time(6, 0),
                completed=False,
                skipped=True,
                rescheduled=False,
                day_of_week=weekday,
                created_at=timezone.now() - timedelta(days=d, hours=18)
            )
            # 17:30 / 19:30 evening exercise - completed 90% of time
            BehaviorRecord.objects.create(
                user=user,
                task_type='EXERCISE',
                scheduled_time=time(17, 30) if weekday % 2 == 0 else time(19, 30),
                actual_completion_time=time(17, 35) if weekday % 2 == 0 else time(19, 35),
                completed=True,
                skipped=False,
                rescheduled=False,
                day_of_week=weekday,
                created_at=timezone.now() - timedelta(days=d, hours=6)
            )

        self.stdout.write(self.style.SUCCESS("HealthSync AI seed completed successfully!"))
