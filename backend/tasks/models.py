from django.db import models
from django.conf import settings
from django.utils import timezone


class DailyTask(models.Model):
    class TaskType(models.TextChoices):
        EXERCISE = 'EXERCISE', 'Exercise & Physical Activity'
        MEDITATION = 'MEDITATION', 'Mindfulness & Meditation'
        MEAL = 'MEAL', 'Healthy Meal'
        HYDRATION = 'HYDRATION', 'Water Intake Reminder'
        SLEEP_ROUTINE = 'SLEEP_ROUTINE', 'Sleep Routine & Wind-down'
        BREAK = 'BREAK', 'Rest & Mobility Break'
        CUSTOM = 'CUSTOM', 'Custom Wellness Activity'

    class Priority(models.TextChoices):
        LOW = 'LOW', 'Low'
        MEDIUM = 'MEDIUM', 'Medium'
        HIGH = 'HIGH', 'High'

    class Status(models.TextChoices):
        PENDING = 'PENDING', 'Pending'
        COMPLETED = 'COMPLETED', 'Completed'
        MISSED = 'MISSED', 'Missed'
        SKIPPED = 'SKIPPED', 'Skipped'
        RESCHEDULED = 'RESCHEDULED', 'Rescheduled'

    user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name='daily_tasks')
    task_type = models.CharField(max_length=30, choices=TaskType.choices, default=TaskType.CUSTOM)
    title = models.CharField(max_length=255)
    description = models.TextField(blank=True, default='')
    date = models.DateField(default=timezone.now)
    scheduled_time = models.TimeField(help_text='Scheduled time of day (e.g. 07:30:00)')
    duration = models.PositiveIntegerField(default=15, help_text='Duration in minutes')
    priority = models.CharField(max_length=20, choices=Priority.choices, default=Priority.MEDIUM)
    status = models.CharField(max_length=20, choices=Status.choices, default=Status.PENDING)
    completed_at = models.DateTimeField(null=True, blank=True)
    rescheduled_at = models.DateTimeField(null=True, blank=True)
    original_time = models.TimeField(null=True, blank=True, help_text='Original scheduled time before rescheduling')
    rescheduled_reason = models.TextField(blank=True, default='')
    ai_explanation = models.TextField(blank=True, default='', help_text='Explainable AI rationale for this task')
    created_at = models.DateTimeField(default=timezone.now)

    class Meta:
        ordering = ['date', 'scheduled_time']
        indexes = [
            models.Index(fields=['user', 'date', 'status']),
            models.Index(fields=['user', 'scheduled_time']),
        ]

    def __str__(self):
        return f"[{self.status}] {self.title} @ {self.scheduled_time} ({self.date})"


class BehaviorRecord(models.Model):
    user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name='behavior_records')
    task = models.ForeignKey(DailyTask, on_delete=models.SET_NULL, null=True, blank=True, related_name='behavior_logs')
    task_type = models.CharField(max_length=30, default='EXERCISE')
    scheduled_time = models.TimeField()
    actual_completion_time = models.TimeField(null=True, blank=True)
    completed = models.BooleanField(default=False)
    skipped = models.BooleanField(default=False)
    rescheduled = models.BooleanField(default=False)
    day_of_week = models.IntegerField(help_text='0=Monday, 6=Sunday', default=0)
    created_at = models.DateTimeField(default=timezone.now)

    class Meta:
        ordering = ['-created_at']
        indexes = [
            models.Index(fields=['user', 'task_type', 'day_of_week']),
        ]

    def __str__(self):
        status_str = "Completed" if self.completed else ("Skipped" if self.skipped else ("Rescheduled" if self.rescheduled else "Missed"))
        return f"{self.user.email} - {self.task_type} at {self.scheduled_time}: {status_str}"
