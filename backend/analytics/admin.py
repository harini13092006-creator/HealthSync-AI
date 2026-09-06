from django.contrib import admin
from .models import DailyWellnessScore


@admin.register(DailyWellnessScore)
class DailyWellnessScoreAdmin(admin.ModelAdmin):
    list_display = ('user', 'date', 'total_score', 'task_adherence_score', 'activity_score', 'hydration_score', 'sleep_score', 'meditation_score')
    list_filter = ('date',)
    search_fields = ('user__email',)
