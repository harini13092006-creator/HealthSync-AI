from django.test import TestCase
from django.urls import reverse
from rest_framework.test import APIClient
from rest_framework import status
from datetime import time, date

from accounts.models import User
from profiles.models import HealthProfile, UserGoal, FoodPreference, ExercisePreference, DailyAvailability
from tasks.models import DailyTask, BehaviorRecord
from health_monitoring.models import WaterRecord, SleepRecord, ActivityRecord


class HealthSyncBackendTests(TestCase):
    def setUp(self):
        self.client = APIClient()
        self.user1 = User.objects.create_user(
            email='user1@example.com',
            name='User One',
            password='TestPassword123'
        )
        self.user2 = User.objects.create_user(
            email='user2@example.com',
            name='User Two',
            password='TestPassword123'
        )

        # Login user1 to get JWT
        login_res = self.client.post(reverse('auth_login'), {
            'email': 'user1@example.com',
            'password': 'TestPassword123'
        })
        self.user1_token = login_res.data['tokens']['access']
        self.client.credentials(HTTP_AUTHORIZATION=f'Bearer {self.user1_token}')

    def test_user_registration(self):
        client = APIClient()
        res = client.post(reverse('auth_register'), {
            'email': 'newuser@example.com',
            'name': 'New User',
            'password': 'StrongPassword456'
        })
        self.assertEqual(res.status_code, status.HTTP_201_CREATED)
        self.assertIn('tokens', res.data)
        self.assertTrue(User.objects.filter(email='newuser@example.com').exists())

    def test_user_login_invalid_password(self):
        client = APIClient()
        res = client.post(reverse('auth_login'), {
            'email': 'user1@example.com',
            'password': 'WrongPassword'
        })
        self.assertEqual(res.status_code, status.HTTP_401_UNAUTHORIZED)

    def test_profile_update_and_bmi(self):
        res = self.client.put(reverse('profile_detail'), {
            'age': 28,
            'height': 180.0,
            'weight': 75.0,
            'activity_level': 'MODERATELY_ACTIVE',
            'wake_time': '06:00:00',
            'sleep_time': '22:00:00'
        }, format='json')
        self.assertEqual(res.status_code, status.HTTP_200_OK)
        self.assertEqual(res.data['age'], 28)
        self.assertEqual(res.data['bmi'], 23.1)

    def test_complete_onboarding(self):
        res = self.client.post(reverse('complete_onboarding'), {
            'age': 22,
            'height': 168.0,
            'weight': 60.0,
            'activity_level': 'LIGHTLY_ACTIVE',
            'wake_time': '07:00:00',
            'sleep_time': '23:00:00',
            'goals': ['FITNESS', 'HEALTHY_EATING', 'HYDRATION'],
            'diet_type': 'VEGETARIAN',
            'cuisine': 'South Indian',
            'preferred_exercises': ['Walking', 'Yoga'],
            'preferred_duration': 30,
            'fitness_level': 'BEGINNER',
            'availability_start': '07:30:00',
            'availability_end': '22:30:00',
            'unavailable_periods': [{'start': '09:00', 'end': '16:00', 'label': 'College'}]
        }, format='json')
        self.assertEqual(res.status_code, status.HTTP_200_OK)
        self.assertTrue(HealthProfile.objects.filter(user=self.user1).exists())
        self.assertEqual(UserGoal.objects.filter(user=self.user1).count(), 3)

    def test_today_tasks_generation_and_completion(self):
        # GET /api/tasks/today/ should auto-generate routine
        res = self.client.get('/api/tasks/today/')
        self.assertEqual(res.status_code, status.HTTP_200_OK)
        self.assertGreater(len(res.data), 0)

        task_id = res.data[0]['id']

        # Complete task
        complete_res = self.client.put(f'/api/tasks/{task_id}/complete/')
        self.assertEqual(complete_res.status_code, status.HTTP_200_OK)
        self.assertEqual(complete_res.data['task']['status'], 'COMPLETED')
        self.assertTrue(BehaviorRecord.objects.filter(user=self.user1, completed=True).exists())

    def test_task_reschedule_with_ai(self):
        # Create a task for user1
        task = DailyTask.objects.create(
            user=self.user1,
            title='Evening Exercise',
            task_type='EXERCISE',
            date=date.today(),
            scheduled_time=time(18, 0),
            duration=30,
            status='PENDING'
        )

        # Trigger reschedule without explicit new_time to test AI recommendation
        res = self.client.put(f'/api/tasks/{task.id}/reschedule/', {}, format='json')
        self.assertEqual(res.status_code, status.HTTP_200_OK)
        self.assertEqual(res.data['task']['status'], 'RESCHEDULED')
        self.assertIn('ai_explanation', res.data)
        self.assertTrue(len(res.data['ai_explanation']) > 0)

    def test_user_data_isolation(self):
        # User 1 creates task
        task1 = DailyTask.objects.create(
            user=self.user1,
            title='User1 Private Task',
            date=date.today(),
            scheduled_time=time(9, 0),
            status='PENDING'
        )

        # User 2 logs in
        login_res2 = self.client.post(reverse('auth_login'), {
            'email': 'user2@example.com',
            'password': 'TestPassword123'
        })
        user2_token = login_res2.data['tokens']['access']
        client2 = APIClient()
        client2.credentials(HTTP_AUTHORIZATION=f'Bearer {user2_token}')

        # User 2 cannot access or see User 1's tasks
        list_res = client2.get('/api/tasks/')
        task_ids = [t['id'] for t in list_res.data]
        self.assertNotIn(task1.id, task_ids)

        # Direct access to User 1's task by User 2 returns 404
        detail_res = client2.get(f'/api/tasks/{task1.id}/')
        self.assertEqual(detail_res.status_code, status.HTTP_404_NOT_FOUND)

    def test_health_monitoring_logging(self):
        # Log water
        w_res = self.client.post('/api/health/water/', {'quantity_ml': 500}, format='json')
        self.assertEqual(w_res.status_code, status.HTTP_201_CREATED)
        self.assertEqual(w_res.data['water_record']['quantity_ml'], 500)

        # Log activity
        a_res = self.client.post('/api/health/activity/', {
            'steps': 4000,
            'active_minutes': 30,
            'exercise_minutes': 20,
            'calories_burned': 150.0
        }, format='json')
        self.assertEqual(a_res.status_code, status.HTTP_201_CREATED)

        # Health overview
        overview = self.client.get('/api/health/')
        self.assertEqual(overview.status_code, status.HTTP_200_OK)
        self.assertIn('hydration', overview.data)
        self.assertEqual(overview.data['hydration']['current_ml'], 500)

    def test_wellness_score_calculation(self):
        res = self.client.get('/api/analytics/wellness-score/')
        self.assertEqual(res.status_code, status.HTTP_200_OK)
        self.assertIn('score', res.data)
        self.assertIn('Daily Wellness Score (Non-Medical)', res.data['label'])
        self.assertIn('medical_disclaimer', res.data)
