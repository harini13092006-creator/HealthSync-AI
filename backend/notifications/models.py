from django.db import models
from django.conf import settings
from django.utils import timezone


class Notification(models.Model):
    class NotificationType(models.TextChoices):
        TASK_REMINDER = 'TASK_REMINDER', 'Task Reminder'
        HYDRATION = 'HYDRATION', 'Hydration Reminder'
        MEAL = 'MEAL', 'Meal Reminder'
        EXERCISE = 'EXERCISE', 'Exercise Reminder'
        MEDITATION = 'MEDITATION', 'Meditation Reminder'
        SLEEP = 'SLEEP', 'Sleep Wind-Down'
        MISSED_TASK = 'MISSED_TASK', 'Missed Task Alert'
        RESCHEDULE = 'RESCHEDULE', 'Schedule Recommendation'
        WEEKLY_PROGRESS = 'WEEKLY_PROGRESS', 'Weekly Progress Report'

    user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name='notifications')
    title = models.CharField(max_length=255)
    message = models.TextField()
    scheduled_time = models.DateTimeField(default=timezone.now)
    notification_type = models.CharField(max_length=30, choices=NotificationType.choices, default=NotificationType.TASK_REMINDER)
    is_read = models.BooleanField(default=False)
    read_at = models.DateTimeField(null=True, blank=True)
    created_at = models.DateTimeField(default=timezone.now)

    class Meta:
        ordering = ['-created_at']
        indexes = [
            models.Index(fields=['user', 'is_read']),
            models.Index(fields=['user', 'scheduled_time']),
        ]

    def __str__(self):
        return f"{self.user.email} - [{self.notification_type}] {self.title} (Read: {self.is_read})"
