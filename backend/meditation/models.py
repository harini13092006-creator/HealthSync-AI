from django.db import models


class MeditationSession(models.Model):
    class SessionType(models.TextChoices):
        BREATHING = 'BREATHING', 'Deep Breathing & Pranayama'
        MINDFULNESS = 'MINDFULNESS', 'Mindfulness Meditation'
        RELAXATION = 'RELAXATION', 'Stress Relief & Body Scan'
        SLEEP_RELAXATION = 'SLEEP_RELAXATION', 'Sleep Routine Relaxation'
        SHORT_BREAK = 'SHORT_BREAK', 'Quick Micro-Break (3-5 mins)'

    title = models.CharField(max_length=255, db_index=True)
    session_type = models.CharField(max_length=30, choices=SessionType.choices, default=SessionType.BREATHING)
    duration = models.PositiveIntegerField(default=10, help_text='Duration in minutes')
    description = models.TextField(blank=True, default='')
    guide_steps = models.JSONField(default=list, blank=True, help_text='Step-by-step guidance instructions')
    target_time_of_day = models.CharField(max_length=50, default='Anytime', help_text='e.g. Morning, Afternoon, Evening, Bedtime')

    class Meta:
        ordering = ['duration', 'title']

    def __str__(self):
        return f"{self.title} ({self.session_type} - {self.duration} mins)"
