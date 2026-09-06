from rest_framework import views, viewsets, status, permissions
from rest_framework.response import Response
from django.utils import timezone
from django.db.models import Sum
from datetime import datetime

from .models import ActivityRecord, SleepRecord, WaterRecord, MealRecord, MeditationRecord
from .serializers import (
    ActivityRecordSerializer,
    SleepRecordSerializer,
    WaterRecordSerializer,
    MealRecordSerializer,
    MeditationRecordSerializer,
)
from profiles.models import HealthProfile
from ai_engine.user_profiler import UserProfiler


class HealthOverviewView(views.APIView):
    """
    GET /api/health/ - Consolidated health overview for today.
    """
    permission_classes = [permissions.IsAuthenticated]

    def get(self, request):
        today = timezone.localdate() if timezone.is_aware(timezone.now()) else timezone.now().date()
        date_str = request.query_params.get('date')
        if date_str:
            try:
                today = datetime.strptime(date_str, '%Y-%m-%d').date()
            except ValueError:
                pass

        user = request.user
        profile = HealthProfile.objects.filter(user=user).first()
        water_target = UserProfiler.calculate_daily_water_target(
            profile.weight if profile else 65.0,
            profile.activity_level if profile else 'MODERATELY_ACTIVE'
        )

        activity = ActivityRecord.objects.filter(user=user, date=today).first()
        sleep = SleepRecord.objects.filter(user=user, date=today).first()
        water_total = WaterRecord.objects.filter(user=user, date=today).aggregate(total=Sum('quantity_ml'))['total'] or 0
        water_records = WaterRecord.objects.filter(user=user, date=today).order_by('-time')[:5]
        meals = MealRecord.objects.filter(user=user, date=today).order_by('time')
        meditations = MeditationRecord.objects.filter(user=user, date=today)

        return Response({
            'date': str(today),
            'activity': ActivityRecordSerializer(activity).data if activity else {
                'steps': 0, 'active_minutes': 0, 'exercise_minutes': 0, 'calories_burned': 0.0
            },
            'sleep': SleepRecordSerializer(sleep).data if sleep else {
                'duration': 0.0, 'quality_rating': 0
            },
            'hydration': {
                'current_ml': water_total,
                'target_ml': water_target,
                'percentage': round(min(100.0, (water_total / water_target) * 100.0), 1) if water_target else 0.0,
                'recent_logs': WaterRecordSerializer(water_records, many=True).data,
            },
            'meals_count': meals.count(),
            'meals': MealRecordSerializer(meals, many=True).data,
            'meditation_minutes': meditations.aggregate(total=Sum('duration'))['total'] or 0,
            'meditations': MeditationRecordSerializer(meditations, many=True).data,
        })


class LogActivityView(views.APIView):
    permission_classes = [permissions.IsAuthenticated]

    def post(self, request):
        today = timezone.localdate() if timezone.is_aware(timezone.now()) else timezone.now().date()
        date_val = request.data.get('date', today)
        steps = int(request.data.get('steps', 0))
        active_mins = int(request.data.get('active_minutes', 0))
        exercise_mins = int(request.data.get('exercise_minutes', 0))
        cals = float(request.data.get('calories_burned', 0.0))

        record, created = ActivityRecord.objects.get_or_create(
            user=request.user,
            date=date_val,
            defaults={
                'steps': steps,
                'active_minutes': active_mins,
                'exercise_minutes': exercise_mins,
                'calories_burned': cals,
            }
        )
        if not created:
            record.steps += steps
            record.active_minutes += active_mins
            record.exercise_minutes += exercise_mins
            record.calories_burned += cals
            record.save()

        return Response({
            'message': 'Activity recorded successfully.',
            'activity': ActivityRecordSerializer(record).data
        }, status=status.HTTP_201_CREATED)


class LogSleepView(views.APIView):
    permission_classes = [permissions.IsAuthenticated]

    def post(self, request):
        today = timezone.localdate() if timezone.is_aware(timezone.now()) else timezone.now().date()
        date_val = request.data.get('date', today)
        start = request.data.get('sleep_start')
        end = request.data.get('sleep_end')
        duration = float(request.data.get('duration', 7.5))
        quality = int(request.data.get('quality_rating', 4))

        if not start:
            start = timezone.now() - timezone.timedelta(hours=duration)
        if not end:
            end = timezone.now()

        record, _ = SleepRecord.objects.update_or_create(
            user=request.user,
            date=date_val,
            defaults={
                'sleep_start': start,
                'sleep_end': end,
                'duration': duration,
                'quality_rating': quality,
            }
        )

        return Response({
            'message': 'Sleep record saved successfully.',
            'sleep': SleepRecordSerializer(record).data
        }, status=status.HTTP_201_CREATED)


class LogWaterView(views.APIView):
    permission_classes = [permissions.IsAuthenticated]

    def get(self, request):
        today = timezone.localdate() if timezone.is_aware(timezone.now()) else timezone.now().date()
        records = WaterRecord.objects.filter(user=request.user, date=today).order_by('-time')
        total = records.aggregate(total=Sum('quantity_ml'))['total'] or 0
        return Response({
            'total_ml': total,
            'records': WaterRecordSerializer(records, many=True).data
        })

    def post(self, request):
        today = timezone.localdate() if timezone.is_aware(timezone.now()) else timezone.now().date()
        date_val = request.data.get('date', today)
        qty = int(request.data.get('quantity_ml', 250))
        t_time = request.data.get('time', timezone.now().time())

        record = WaterRecord.objects.create(
            user=request.user,
            date=date_val,
            quantity_ml=qty,
            time=t_time
        )
        total = WaterRecord.objects.filter(user=request.user, date=date_val).aggregate(total=Sum('quantity_ml'))['total'] or 0

        return Response({
            'message': f"Logged {qty}ml water.",
            'total_today_ml': total,
            'water_record': WaterRecordSerializer(record).data
        }, status=status.HTTP_201_CREATED)


class LogMealView(views.APIView):
    permission_classes = [permissions.IsAuthenticated]

    def post(self, request):
        today = timezone.localdate() if timezone.is_aware(timezone.now()) else timezone.now().date()
        serializer = MealRecordSerializer(data=request.data)
        if serializer.is_valid():
            record = serializer.save(user=request.user, date=request.data.get('date', today))
            return Response({
                'message': 'Meal logged successfully.',
                'meal': MealRecordSerializer(record).data
            }, status=status.HTTP_201_CREATED)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


class LogMeditationView(views.APIView):
    permission_classes = [permissions.IsAuthenticated]

    def post(self, request):
        today = timezone.localdate() if timezone.is_aware(timezone.now()) else timezone.now().date()
        serializer = MeditationRecordSerializer(data=request.data)
        if serializer.is_valid():
            record = serializer.save(user=request.user, date=request.data.get('date', today))
            return Response({
                'message': 'Meditation logged successfully.',
                'meditation': MeditationRecordSerializer(record).data
            }, status=status.HTTP_201_CREATED)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
