from django.contrib import admin
from .models import MeditationSession


@admin.register(MeditationSession)
class MeditationSessionAdmin(admin.ModelAdmin):
    list_display = ('title', 'session_type', 'duration', 'target_time_of_day')
    list_filter = ('session_type', 'duration')
    search_fields = ('title', 'description')
