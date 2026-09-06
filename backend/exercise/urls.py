from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import ExerciseItemViewSet

router = DefaultRouter()
router.register(r'items', ExerciseItemViewSet, basename='exercise_items')

urlpatterns = [
    path('', include(router.urls)),
]
