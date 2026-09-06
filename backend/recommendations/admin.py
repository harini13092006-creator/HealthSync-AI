from django.contrib import admin
from .models import RecommendationHistory


@admin.register(RecommendationHistory)
class RecommendationHistoryAdmin(admin.ModelAdmin):
    list_display = ('user', 'recommendation_type', 'title', 'accepted', 'completed', 'created_at')
    list_filter = ('recommendation_type', 'accepted', 'completed')
    search_fields = ('user__email', 'title', 'explanation')
