from django.db import models


class ExerciseItem(models.Model):
    class Category(models.TextChoices):
        WALKING = 'WALKING', 'Brisk Walking'
        RUNNING = 'RUNNING', 'Running & Jogging'
        YOGA = 'YOGA', 'Yoga & Asanas'
        STRETCHING = 'STRETCHING', 'Stretching & Flexibility'
        MOBILITY = 'MOBILITY', 'Joint Mobility'
        STRENGTH = 'STRENGTH', 'Light Strength & Bodyweight'
        BREATHING = 'BREATHING', 'Pranayama & Breathwork'

    class Difficulty(models.TextChoices):
        BEGINNER = 'BEGINNER', 'Beginner'
        INTERMEDIATE = 'INTERMEDIATE', 'Intermediate'
        ADVANCED = 'ADVANCED', 'Advanced'

    class Equipment(models.TextChoices):
        NONE = 'NONE', 'None (Bodyweight)'
        YOGA_MAT = 'YOGA_MAT', 'Yoga Mat'
        DUMBBELLS = 'DUMBBELLS', 'Light Dumbbells'
        RESISTANCE_BAND = 'RESISTANCE_BAND', 'Resistance Band'
        CHAIR = 'CHAIR', 'Chair'

    name = models.CharField(max_length=255, db_index=True)
    category = models.CharField(max_length=30, choices=Category.choices, default=Category.WALKING)
    difficulty = models.CharField(max_length=20, choices=Difficulty.choices, default=Difficulty.BEGINNER)
    duration = models.PositiveIntegerField(default=20, help_text='Standard duration in minutes')
    equipment = models.CharField(max_length=30, choices=Equipment.choices, default=Equipment.NONE)
    tags = models.JSONField(default=list, blank=True, help_text='Keywords e.g. ["low-impact", "home-friendly"]')
    instructions = models.TextField(blank=True, default='')
    calories_burned_est = models.FloatField(default=80.0, help_text='Estimated calories burned')

    class Meta:
        ordering = ['name']
        indexes = [
            models.Index(fields=['category', 'difficulty']),
        ]

    def __str__(self):
        return f"{self.name} ({self.category} - {self.difficulty} - {self.duration}m)"
