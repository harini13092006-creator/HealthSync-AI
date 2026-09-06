from django.db import models
from django.conf import settings
from django.utils import timezone


class DailyWellnessScore(models.Model):
    user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name='wellness_scores')
    date = models.DateField(default=timezone.now)
    total_score = models.FloatField(default=0.0, help_text='Overall Daily Wellness Score (0 to 100)')
    task_adherence_score = models.FloatField(default=0.0, help_text='Max 25 points')
    activity_score = models.FloatField(default=0.0, help_text='Max 25 points')
    hydration_score = models.FloatField(default=0.0, help_text='Max 20 points')
    sleep_score = models.FloatField(default=0.0, help_text='Max 20 points')
    meditation_score = models.FloatField(default=0.0, help_text='Max 10 points')
    summary_text = models.TextField(blank=True, default='')
    calculated_at = models.DateTimeField(default=timezone.now)

    class Meta:
        ordering = ['-date']
        unique_together = ('user', 'date')
        indexes = [
            models.Index(fields=['user', 'date']),
        ]

    def __str__(self):
        return f"{self.user.email} - {self.date}: {self.total_score}/100"
