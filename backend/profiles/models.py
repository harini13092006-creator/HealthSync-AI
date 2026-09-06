from django.db import models
from django.conf import settings
from django.utils import timezone


class HealthProfile(models.Model):
    class ActivityLevel(models.TextChoices):
        SEDENTARY = 'SEDENTARY', 'Sedentary (Little or no exercise)'
        LIGHTLY_ACTIVE = 'LIGHTLY_ACTIVE', 'Lightly Active (Exercise 1-3 days/week)'
        MODERATELY_ACTIVE = 'MODERATELY_ACTIVE', 'Moderately Active (Exercise 3-5 days/week)'
        VERY_ACTIVE = 'VERY_ACTIVE', 'Very Active (Hard exercise 6-7 days/week)'

    user = models.OneToOneField(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name='health_profile')
    age = models.PositiveIntegerField(default=25)
    height = models.FloatField(help_text='Height in centimeters', default=170.0)
    weight = models.FloatField(help_text='Weight in kilograms', default=65.0)
    activity_level = models.CharField(max_length=30, choices=ActivityLevel.choices, default=ActivityLevel.MODERATELY_ACTIVE)
    wake_time = models.TimeField(default='06:30:00')
    sleep_time = models.TimeField(default='22:30:00')
    created_at = models.DateTimeField(default=timezone.now)
    updated_at = models.DateTimeField(auto_now=True)

    def __str__(self):
        return f"Health Profile for {self.user.email}"

    @property
    def bmi(self):
        if self.height and self.height > 0:
            height_m = self.height / 100.0
            return round(self.weight / (height_m * height_m), 1)
        return 0.0


class UserGoal(models.Model):
    class GoalType(models.TextChoices):
        FITNESS = 'FITNESS', 'General Fitness'
        HEALTHY_EATING = 'HEALTHY_EATING', 'Healthy Eating'
        BETTER_SLEEP = 'BETTER_SLEEP', 'Better Sleep'
        HYDRATION = 'HYDRATION', 'Hydration'
        MEDITATION = 'MEDITATION', 'Mindfulness & Meditation'
        PHYSICAL_ACTIVITY = 'PHYSICAL_ACTIVITY', 'Physical Activity'

    user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name='goals')
    goal_type = models.CharField(max_length=30, choices=GoalType.choices)
    target = models.CharField(max_length=255, blank=True, default='')
    is_active = models.BooleanField(default=True)
    created_at = models.DateTimeField(default=timezone.now)

    class Meta:
        ordering = ['-created_at']

    def __str__(self):
        return f"{self.user.email} - {self.goal_type} ({self.target})"


class FoodPreference(models.Model):
    class DietType(models.TextChoices):
        VEGETARIAN = 'VEGETARIAN', 'Vegetarian'
        VEGAN = 'VEGAN', 'Vegan'
        NON_VEGETARIAN = 'NON_VEGETARIAN', 'Non-Vegetarian'
        EGGETARIAN = 'EGGETARIAN', 'Eggetarian'
        PESCATARIAN = 'PESCATARIAN', 'Pescatarian'

    user = models.OneToOneField(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name='food_preference')
    diet_type = models.CharField(max_length=30, choices=DietType.choices, default=DietType.VEGETARIAN)
    preferences = models.JSONField(default=list, blank=True, help_text='List of preferred food items/categories')
    allergies = models.JSONField(default=list, blank=True, help_text='List of food allergies or intolerances')
    cuisine = models.CharField(max_length=100, default='South Indian', help_text='Preferred cuisine, e.g. South Indian, North Indian, Continental')
    updated_at = models.DateTimeField(auto_now=True)

    def __str__(self):
        return f"{self.user.email} - {self.diet_type} ({self.cuisine})"


class ExercisePreference(models.Model):
    class FitnessLevel(models.TextChoices):
        BEGINNER = 'BEGINNER', 'Beginner'
        INTERMEDIATE = 'INTERMEDIATE', 'Intermediate'
        ADVANCED = 'ADVANCED', 'Advanced'

    user = models.OneToOneField(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name='exercise_preference')
    preferred_exercises = models.JSONField(default=list, blank=True, help_text='e.g. ["Walking", "Yoga", "Stretching"]')
    preferred_duration = models.PositiveIntegerField(default=30, help_text='Preferred duration in minutes (10, 20, 30, 45, 60)')
    fitness_level = models.CharField(max_length=30, choices=FitnessLevel.choices, default=FitnessLevel.BEGINNER)
    updated_at = models.DateTimeField(auto_now=True)

    def __str__(self):
        return f"{self.user.email} - {self.fitness_level} ({self.preferred_duration} mins)"


class DailyAvailability(models.Model):
    user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name='availabilities')
    day = models.IntegerField(choices=[(i, day_name) for i, day_name in enumerate(['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'])], default=0)
    start_time = models.TimeField(default='07:00:00')
    end_time = models.TimeField(default='22:00:00')
    unavailable_periods = models.JSONField(default=list, blank=True, help_text='List of {"start": "09:00", "end": "16:00", "label": "College/Work"}')

    class Meta:
        unique_together = ('user', 'day')
        ordering = ['day']

    def __str__(self):
        return f"{self.user.email} - Day {self.day} ({self.start_time} - {self.end_time})"
