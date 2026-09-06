from django.contrib import admin
from .models import HealthProfile, UserGoal, FoodPreference, ExercisePreference, DailyAvailability


@admin.register(HealthProfile)
class HealthProfileAdmin(admin.ModelAdmin):
    list_display = ('user', 'age', 'height', 'weight', 'activity_level', 'wake_time', 'sleep_time')
    search_fields = ('user__email', 'user__name')


@admin.register(UserGoal)
class UserGoalAdmin(admin.ModelAdmin):
    list_display = ('user', 'goal_type', 'target', 'is_active', 'created_at')
    list_filter = ('goal_type', 'is_active')
    search_fields = ('user__email',)


@admin.register(FoodPreference)
class FoodPreferenceAdmin(admin.ModelAdmin):
    list_display = ('user', 'diet_type', 'cuisine', 'updated_at')
    list_filter = ('diet_type',)
    search_fields = ('user__email',)


@admin.register(ExercisePreference)
class ExercisePreferenceAdmin(admin.ModelAdmin):
    list_display = ('user', 'fitness_level', 'preferred_duration', 'updated_at')
    list_filter = ('fitness_level',)
    search_fields = ('user__email',)


@admin.register(DailyAvailability)
class DailyAvailabilityAdmin(admin.ModelAdmin):
    list_display = ('user', 'day', 'start_time', 'end_time')
    list_filter = ('day',)
    search_fields = ('user__email',)
