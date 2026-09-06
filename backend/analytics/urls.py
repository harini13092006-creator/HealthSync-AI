from django.urls import path
from .views import (
    DailyAnalyticsView,
    WeeklyAnalyticsView,
    WellnessScoreView,
    BehaviorAnalyticsView,
)

urlpatterns = [
    path('daily/', DailyAnalyticsView.as_view(), name='daily_analytics'),
    path('weekly/', WeeklyAnalyticsView.as_view(), name='weekly_analytics'),
    path('wellness-score/', WellnessScoreView.as_view(), name='wellness_score'),
    path('behavior/', BehaviorAnalyticsView.as_view(), name='behavior_analytics'),
]
