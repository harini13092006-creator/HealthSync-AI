from django.db import models
from django.conf import settings
from django.utils import timezone


class ActivityRecord(models.Model):
    user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name='activity_records')
    date = models.DateField(default=timezone.now)
    steps = models.PositiveIntegerField(default=0)
    active_minutes = models.PositiveIntegerField(default=0)
    exercise_minutes = models.PositiveIntegerField(default=0)
    calories_burned = models.FloatField(default=0.0)
    created_at = models.DateTimeField(default=timezone.now)

    class Meta:
        ordering = ['-date']
        unique_together = ('user', 'date')

    def __str__(self):
        return f"{self.user.email} - {self.date}: {self.steps} steps, {self.active_minutes}m active"


class SleepRecord(models.Model):
    user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name='sleep_records')
    date = models.DateField(default=timezone.now, help_text='Date the sleep ended')
    sleep_start = models.DateTimeField(help_text='When user went to bed')
    sleep_end = models.DateTimeField(help_text='When user woke up')
    duration = models.FloatField(help_text='Sleep duration in hours', default=7.5)
    quality_rating = models.PositiveSmallIntegerField(default=4, help_text='Rating 1 (Poor) to 5 (Restful)')
    created_at = models.DateTimeField(default=timezone.now)

    class Meta:
        ordering = ['-date']
        unique_together = ('user', 'date')

    def __str__(self):
        return f"{self.user.email} - {self.date}: {self.duration}h sleep (rating: {self.quality_rating}/5)"


class WaterRecord(models.Model):
    user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name='water_records')
    date = models.DateField(default=timezone.now)
    quantity_ml = models.PositiveIntegerField(default=250, help_text='Quantity in ml')
    time = models.TimeField(default=timezone.now)
    created_at = models.DateTimeField(default=timezone.now)

    class Meta:
        ordering = ['-date', '-time']
        indexes = [
            models.Index(fields=['user', 'date']),
        ]

    def __str__(self):
        return f"{self.user.email} - {self.date} @ {self.time}: {self.quantity_ml}ml"


class MealRecord(models.Model):
    class MealType(models.TextChoices):
        BREAKFAST = 'BREAKFAST', 'Breakfast'
        LUNCH = 'LUNCH', 'Lunch'
        SNACK = 'SNACK', 'Snack'
        DINNER = 'DINNER', 'Dinner'

    user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name='meal_records')
    date = models.DateField(default=timezone.now)
    meal_type = models.CharField(max_length=20, choices=MealType.choices, default=MealType.LUNCH)
    food = models.CharField(max_length=255)
    calories = models.FloatField(default=350.0)
    notes = models.TextField(blank=True, default='')
    time = models.TimeField(default=timezone.now)
    created_at = models.DateTimeField(default=timezone.now)

    class Meta:
        ordering = ['-date', '-time']

    def __str__(self):
        return f"{self.user.email} - {self.date} ({self.meal_type}): {self.food}"


class MeditationRecord(models.Model):
    user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name='meditation_records')
    date = models.DateField(default=timezone.now)
    type = models.CharField(max_length=100, default='Mindfulness Breathing')
    duration = models.PositiveIntegerField(default=10, help_text='Duration in minutes')
    notes = models.TextField(blank=True, default='')
    created_at = models.DateTimeField(default=timezone.now)

    class Meta:
        ordering = ['-date', '-created_at']

    def __str__(self):
        return f"{self.user.email} - {self.date}: {self.type} ({self.duration}m)"
