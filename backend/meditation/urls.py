from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import MeditationSessionViewSet

router = DefaultRouter()
router.register(r'sessions', MeditationSessionViewSet, basename='meditation_sessions')

urlpatterns = [
    path('', include(router.urls)),
]
