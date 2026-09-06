from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import (
    HealthProfileView,
    UserGoalViewSet,
    FoodPreferenceView,
    ExercisePreferenceView,
    DailyAvailabilityViewSet,
    CompleteOnboardingView,
)

router = DefaultRouter()
router.register(r'goals', UserGoalViewSet, basename='user_goals')
router.register(r'availability', DailyAvailabilityViewSet, basename='daily_availability')

urlpatterns = [
    path('', HealthProfileView.as_view(), name='profile_detail'),
    path('food-preferences/', FoodPreferenceView.as_view(), name='food_preferences'),
    path('exercise-preferences/', ExercisePreferenceView.as_view(), name='exercise_preferences'),
    path('onboarding/', CompleteOnboardingView.as_view(), name='complete_onboarding'),
    path('', include(router.urls)),
]
