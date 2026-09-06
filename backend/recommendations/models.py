from django.db import models
from django.conf import settings
from django.utils import timezone


class RecommendationHistory(models.Model):
    class RecType(models.TextChoices):
        FOOD = 'FOOD', 'Food & Nutrition'
        EXERCISE = 'EXERCISE', 'Exercise & Movement'
        MEDITATION = 'MEDITATION', 'Mindfulness & Meditation'
        ROUTINE = 'ROUTINE', 'Daily Routine Plan'
        RESCHEDULE = 'RESCHEDULE', 'Adaptive Rescheduling'

    user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name='recommendation_history')
    recommendation_type = models.CharField(max_length=30, choices=RecType.choices, default=RecType.FOOD)
    title = models.CharField(max_length=255, default='Personalized Recommendation')
    recommendation = models.JSONField(default=dict, help_text='Detailed payload of the recommendation')
    explanation = models.TextField(blank=True, default='', help_text='Explainable AI rationale (Why this recommendation?)')
    recommended_time = models.DateTimeField(null=True, blank=True)
    accepted = models.BooleanField(default=False)
    completed = models.BooleanField(default=False)
    feedback = models.TextField(blank=True, default='')
    created_at = models.DateTimeField(default=timezone.now)

    class Meta:
        ordering = ['-created_at']
        indexes = [
            models.Index(fields=['user', 'recommendation_type']),
        ]

    def __str__(self):
        return f"{self.user.email} - {self.recommendation_type}: {self.title} (Accepted: {self.accepted})"
