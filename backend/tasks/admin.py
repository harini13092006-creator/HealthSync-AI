from django.contrib import admin
from .models import DailyTask, BehaviorRecord


@admin.register(DailyTask)
class DailyTaskAdmin(admin.ModelAdmin):
    list_display = ('id', 'user', 'title', 'task_type', 'date', 'scheduled_time', 'duration', 'priority', 'status')
    list_filter = ('status', 'task_type', 'priority', 'date')
    search_fields = ('title', 'user__email', 'description')
    ordering = ('-date', 'scheduled_time')


@admin.register(BehaviorRecord)
class BehaviorRecordAdmin(admin.ModelAdmin):
    list_display = ('id', 'user', 'task_type', 'scheduled_time', 'completed', 'skipped', 'rescheduled', 'day_of_week', 'created_at')
    list_filter = ('completed', 'skipped', 'rescheduled', 'task_type', 'day_of_week')
    search_fields = ('user__email', 'task_type')
