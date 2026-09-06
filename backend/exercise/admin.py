from django.contrib import admin
from .models import ExerciseItem


@admin.register(ExerciseItem)
class ExerciseItemAdmin(admin.ModelAdmin):
    list_display = ('name', 'category', 'difficulty', 'duration', 'equipment', 'calories_burned_est')
    list_filter = ('category', 'difficulty', 'equipment')
    search_fields = ('name', 'tags')
