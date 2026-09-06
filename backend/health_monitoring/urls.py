from django.urls import path
from .views import (
    HealthOverviewView,
    LogActivityView,
    LogSleepView,
    LogWaterView,
    LogMealView,
    LogMeditationView,
)

urlpatterns = [
    path('', HealthOverviewView.as_view(), name='health_overview'),
    path('activity/', LogActivityView.as_view(), name='log_activity'),
    path('sleep/', LogSleepView.as_view(), name='log_sleep'),
    path('water/', LogWaterView.as_view(), name='log_water'),
    path('meal/', LogMealView.as_view(), name='log_meal'),
    path('meditation/', LogMeditationView.as_view(), name='log_meditation'),
]
