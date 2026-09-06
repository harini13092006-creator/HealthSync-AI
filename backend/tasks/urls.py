from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import DailyTaskViewSet

router = DefaultRouter()
router.register(r'', DailyTaskViewSet, basename='daily_tasks')

urlpatterns = [
    path('', include(router.urls)),
]
