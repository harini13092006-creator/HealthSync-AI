from rest_framework import views, status, permissions
from rest_framework.response import Response
from django.utils import timezone
from django.db.models import Sum, Avg
from datetime import datetime, timedelta

from .models import DailyWellnessScore
from .serializers import DailyWellnessScoreSerializer
from tasks.models import DailyTask, BehaviorRecord
from health_monitoring.models import ActivityRecord, SleepRecord, WaterRecord, MeditationRecord
from profiles.models import HealthProfile
from ai_engine.user_profiler import UserProfiler
from ai_engine.behavior_analysis import BehaviorAnalyzer


def compute_daily_wellness_score(user, date_val):
    """
    Computes a non-medical Daily Wellness Score (0 to 100).
    Components:
    - Task adherence: 25 pts
    - Physical Activity: 25 pts
    - Hydration: 20 pts
    - Sleep Consistency: 20 pts
    - Mindfulness & Meditation: 10 pts
    """
    profile = HealthProfile.objects.filter(user=user).first()
    water_target = UserProfiler.calculate_daily_water_target(
        profile.weight if profile else 65.0,
        profile.activity_level if profile else 'MODERATELY_ACTIVE'
    )

    # 1. Task adherence (max 25)
    tasks = DailyTask.objects.filter(user=user, date=date_val)
    total_tasks = tasks.count()
    completed_tasks = tasks.filter(status=DailyTask.Status.COMPLETED).count()
    if total_tasks > 0:
        task_score = round((completed_tasks / total_tasks) * 25.0, 1)
    else:
        task_score = 15.0  # neutral starting baseline

    # 2. Activity (max 25)
    activity = ActivityRecord.objects.filter(user=user, date=date_val).first()
    if activity:
        step_pts = min(18.0, (activity.steps / 8000.0) * 18.0)
        active_pts = min(7.0, (activity.active_minutes / 45.0) * 7.0)
        activity_score = round(step_pts + active_pts, 1)
    else:
        activity_score = 5.0

    # 3. Hydration (max 20)
    water_ml = WaterRecord.objects.filter(user=user, date=date_val).aggregate(total=Sum('quantity_ml'))['total'] or 0
    hydration_score = round(min(20.0, (water_ml / float(water_target)) * 20.0), 1)

    # 4. Sleep (max 20)
    sleep = SleepRecord.objects.filter(user=user, date=date_val).first()
    if sleep:
        dur_pts = min(15.0, (sleep.duration / 7.5) * 15.0)
        qual_pts = min(5.0, (sleep.quality_rating / 5.0) * 5.0)
        sleep_score = round(dur_pts + qual_pts, 1)
    else:
        sleep_score = 10.0

    # 5. Meditation (max 10)
    med_mins = MeditationRecord.objects.filter(user=user, date=date_val).aggregate(total=Sum('duration'))['total'] or 0
    meditation_score = round(min(10.0, (med_mins / 10.0) * 10.0), 1)

    total_score = round(task_score + activity_score + hydration_score + sleep_score + meditation_score, 1)
    total_score = max(0.0, min(100.0, total_score))

    summary = (
        f"Daily Wellness Score: {int(total_score)}/100. "
        f"Tasks: {completed_tasks}/{total_tasks} completed ({task_score}/25), "
        f"Activity: {activity.steps if activity else 0} steps ({activity_score}/25), "
        f"Hydration: {water_ml}/{water_target}ml ({hydration_score}/20), "
        f"Sleep: {sleep.duration if sleep else 0}h ({sleep_score}/20), "
        f"Meditation: {med_mins}m ({meditation_score}/10)."
    )

    record, _ = DailyWellnessScore.objects.update_or_create(
        user=user,
        date=date_val,
        defaults={
            'total_score': total_score,
            'task_adherence_score': task_score,
            'activity_score': activity_score,
            'hydration_score': hydration_score,
            'sleep_score': sleep_score,
            'meditation_score': meditation_score,
            'summary_text': summary,
            'calculated_at': timezone.now()
        }
    )
    return record


class WellnessScoreView(views.APIView):
    permission_classes = [permissions.IsAuthenticated]

    def get(self, request):
        today = timezone.localdate() if timezone.is_aware(timezone.now()) else timezone.now().date()
        date_str = request.query_params.get('date')
        if date_str:
            try:
                today = datetime.strptime(date_str, '%Y-%m-%d').date()
            except ValueError:
                pass

        score_record = compute_daily_wellness_score(request.user, today)
        return Response({
            'label': 'Daily Wellness Score (Non-Medical)',
            'score': score_record.total_score,
            'components': {
                'task_adherence': {'score': score_record.task_adherence_score, 'max': 25},
                'activity': {'score': score_record.activity_score, 'max': 25},
                'hydration': {'score': score_record.hydration_score, 'max': 20},
                'sleep': {'score': score_record.sleep_score, 'max': 20},
                'meditation': {'score': score_record.meditation_score, 'max': 10},
            },
            'summary': score_record.summary_text,
            'medical_disclaimer': 'This wellness score is an algorithmic habit metric, not a clinical diagnostic assessment.'
        })


class DailyAnalyticsView(views.APIView):
    permission_classes = [permissions.IsAuthenticated]

    def get(self, request):
        today = timezone.localdate() if timezone.is_aware(timezone.now()) else timezone.now().date()
        score_record = compute_daily_wellness_score(request.user, today)

        # Yesterday's score
        yesterday = today - timedelta(days=1)
        yesterday_record = DailyWellnessScore.objects.filter(user=request.user, date=yesterday).first()

        diff = round(score_record.total_score - (yesterday_record.total_score if yesterday_record else score_record.total_score), 1)

        tasks = DailyTask.objects.filter(user=request.user, date=today)
        return Response({
            'date': str(today),
            'wellness_score': score_record.total_score,
            'change_from_yesterday': diff,
            'total_tasks': tasks.count(),
            'completed_tasks': tasks.filter(status=DailyTask.Status.COMPLETED).count(),
            'skipped_tasks': tasks.filter(status=DailyTask.Status.SKIPPED).count(),
            'rescheduled_tasks': tasks.filter(status=DailyTask.Status.RESCHEDULED).count(),
            'score_breakdown': DailyWellnessScoreSerializer(score_record).data
        })


class WeeklyAnalyticsView(views.APIView):
    permission_classes = [permissions.IsAuthenticated]

    def get(self, request):
        today = timezone.localdate() if timezone.is_aware(timezone.now()) else timezone.now().date()
        days_data = []

        for i in range(6, -1, -1):
            d = today - timedelta(days=i)
            # Fetch or compute score
            sc = DailyWellnessScore.objects.filter(user=request.user, date=d).first()
            if not sc and d == today:
                sc = compute_daily_wellness_score(request.user, d)

            act = ActivityRecord.objects.filter(user=request.user, date=d).first()
            slp = SleepRecord.objects.filter(user=request.user, date=d).first()
            wat = WaterRecord.objects.filter(user=request.user, date=d).aggregate(total=Sum('quantity_ml'))['total'] or 0

            days_data.append({
                'date': str(d),
                'day_name': d.strftime('%a'),
                'wellness_score': sc.total_score if sc else 70.0,
                'steps': act.steps if act else 0,
                'sleep_hours': slp.duration if slp else 0.0,
                'water_ml': wat,
            })

        avg_score = round(sum(d['wellness_score'] for d in days_data) / len(days_data), 1)
        total_steps = sum(d['steps'] for d in days_data)

        return Response({
            'start_date': str(today - timedelta(days=6)),
            'end_date': str(today),
            'average_wellness_score': avg_score,
            'total_weekly_steps': total_steps,
            'daily_breakdowns': days_data
        })


class BehaviorAnalyticsView(views.APIView):
    permission_classes = [permissions.IsAuthenticated]

    def get(self, request):
        records = list(BehaviorRecord.objects.filter(user=request.user).values(
            'task_type', 'scheduled_time', 'actual_completion_time',
            'completed', 'skipped', 'rescheduled', 'day_of_week'
        ))

        analysis = BehaviorAnalyzer.analyze_records(records)
        return Response(analysis)
