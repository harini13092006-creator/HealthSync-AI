"""
HealthSync AI - Master URL Configuration
"""

from django.contrib import admin
from django.urls import path, include
from drf_spectacular.views import (
    SpectacularAPIView,
    SpectacularSwaggerView,
    SpectacularRedocView,
)
from profiles.views import UserGoalViewSet
from rest_framework.routers import DefaultRouter



goals_router = DefaultRouter()
goals_router.register(r'', UserGoalViewSet, basename='goals')

from django.contrib import admin
from django.urls import path, include
from django.http import JsonResponse


def home(request):
    return JsonResponse({
        "status": "success",
        "message": "HealthSync AI Backend is running",
        "service": "HealthSync AI",
        "version": "1.0"
    })

urlpatterns = [
    path('', home, name='home'),
    path('admin/', admin.site.urls),

    # OpenAPI / Swagger Documentation
    path('api/schema/', SpectacularAPIView.as_view(), name='schema'),
    path('api/docs/', SpectacularSwaggerView.as_view(url_name='schema'), name='swagger-ui'),
    path('api/redoc/', SpectacularRedocView.as_view(url_name='schema'), name='redoc'),

    # Core REST Endpoints
    path('api/auth/', include('accounts.urls')),
    path('api/profile/', include('profiles.urls')),
    path('api/goals/', include(goals_router.urls)),
    path('api/tasks/', include('tasks.urls')),
    path('api/health/', include('health_monitoring.urls')),
    path('api/nutrition/', include('nutrition.urls')),
    path('api/exercise/', include('exercise.urls')),
    path('api/meditation/', include('meditation.urls')),
    path('api/recommendations/', include('recommendations.urls')),
    path('api/notifications/', include('notifications.urls')),
    path('api/analytics/', include('analytics.urls')),
]
