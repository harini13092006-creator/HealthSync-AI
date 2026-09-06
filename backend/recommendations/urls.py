from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import (
    RecommendationHistoryViewSet,
    FoodRecommendationsView,
    ExerciseRecommendationsView,
    MinimumViableTaskView,
    GenerateRecommendationView,
)

router = DefaultRouter()
router.register(r'history', RecommendationHistoryViewSet, basename='recommendation_history')

urlpatterns = [
    path('generate/', GenerateRecommendationView.as_view(), name='generate_recommendation'),
    path('food/', FoodRecommendationsView.as_view(), name='food_recommendations'),
    path('exercise/', ExerciseRecommendationsView.as_view(), name='exercise_recommendations'),
    path('mvt/', MinimumViableTaskView.as_view(), name='minimum_viable_task'),
    path('', include(router.urls)),
]
