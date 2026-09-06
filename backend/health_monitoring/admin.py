from django.contrib import admin
from .models import ActivityRecord, SleepRecord, WaterRecord, MealRecord, MeditationRecord


@admin.register(ActivityRecord)
class ActivityRecordAdmin(admin.ModelAdmin):
    list_display = ('user', 'date', 'steps', 'active_minutes', 'exercise_minutes', 'calories_burned')
    list_filter = ('date',)
    search_fields = ('user__email',)


@admin.register(SleepRecord)
class SleepRecordAdmin(admin.ModelAdmin):
    list_display = ('user', 'date', 'duration', 'quality_rating', 'sleep_start', 'sleep_end')
    list_filter = ('date', 'quality_rating')
    search_fields = ('user__email',)


@admin.register(WaterRecord)
class WaterRecordAdmin(admin.ModelAdmin):
    list_display = ('user', 'date', 'quantity_ml', 'time')
    list_filter = ('date',)
    search_fields = ('user__email',)


@admin.register(MealRecord)
class MealRecordAdmin(admin.ModelAdmin):
    list_display = ('user', 'date', 'meal_type', 'food', 'calories', 'time')
    list_filter = ('date', 'meal_type')
    search_fields = ('user__email', 'food')


@admin.register(MeditationRecord)
class MeditationRecordAdmin(admin.ModelAdmin):
    list_display = ('user', 'date', 'type', 'duration', 'created_at')
    list_filter = ('date', 'type')
    search_fields = ('user__email',)
