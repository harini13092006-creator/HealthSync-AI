from rest_framework import viewsets, status, permissions
from rest_framework.decorators import action
from rest_framework.response import Response
from django.utils import timezone
from datetime import datetime

from .models import DailyTask, BehaviorRecord
from .serializers import DailyTaskSerializer, RescheduleTaskSerializer, BehaviorRecordSerializer
from profiles.models import HealthProfile, UserGoal, FoodPreference, ExercisePreference, DailyAvailability
from ai_engine.scheduling import AdaptiveRoutinePlanner, ScheduleConflictDetector
from ai_engine.user_profiler import UserProfiler


class DailyTaskViewSet(viewsets.ModelViewSet):
    permission_classes = [permissions.IsAuthenticated]
    serializer_class = DailyTaskSerializer

    def get_queryset(self):
        qs = DailyTask.objects.filter(user=self.request.user)
        date_str = self.request.query_params.get('date')
        if date_str:
            try:
                date_val = datetime.strptime(date_str, '%Y-%m-%d').date()
                qs = qs.filter(date=date_val)
            except ValueError:
                pass
        return qs

    def perform_create(self, serializer):
        serializer.save(user=self.request.user)

    @action(detail=False, methods=['get'])
    def today(self, request):
        today = timezone.localdate() if timezone.is_aware(timezone.now()) else timezone.now().date()
        tasks = DailyTask.objects.filter(user=request.user, date=today).order_by('scheduled_time')

        # If no tasks exist for today, automatically generate a personalized routine!
        if not tasks.exists():
            self._generate_routine_for_user(request.user, today)
            tasks = DailyTask.objects.filter(user=request.user, date=today).order_by('scheduled_time')

        serializer = self.get_serializer(tasks, many=True)
        return Response(serializer.data)

    @action(detail=False, methods=['post'], url_path='generate-routine')
    def generate_routine(self, request):
        today = timezone.localdate() if timezone.is_aware(timezone.now()) else timezone.now().date()
        date_str = request.data.get('date')
        target_date = today
        if date_str:
            try:
                target_date = datetime.strptime(date_str, '%Y-%m-%d').date()
            except ValueError:
                pass

        # Clear existing uncompleted tasks if re-generating
        DailyTask.objects.filter(user=request.user, date=target_date, status=DailyTask.Status.PENDING).delete()
        created_count = self._generate_routine_for_user(request.user, target_date)
        tasks = DailyTask.objects.filter(user=request.user, date=target_date).order_by('scheduled_time')
        serializer = self.get_serializer(tasks, many=True)
        return Response({
            'message': f"Generated {created_count} personalized tasks for {target_date}.",
            'tasks': serializer.data
        })

    def _generate_routine_for_user(self, user, target_date):
        profile, _ = HealthProfile.objects.get_or_create(user=user)
        goals = list(UserGoal.objects.filter(user=user, is_active=True).values_list('goal_type', flat=True))
        food_pref = FoodPreference.objects.filter(user=user).first()
        ex_pref = ExercisePreference.objects.filter(user=user).first()

        weekday = target_date.weekday()
        avail = DailyAvailability.objects.filter(user=user, day=weekday).first()
        avail_dict = {
            'start_time': str(avail.start_time) if avail else '07:00:00',
            'end_time': str(avail.end_time) if avail else '22:00:00',
            'unavailable_periods': avail.unavailable_periods if avail else []
        }

        planner = AdaptiveRoutinePlanner()
        routine_items = planner.generate_daily_routine(
            user_profile={
                'wake_time': str(profile.wake_time),
                'sleep_time': str(profile.sleep_time),
                'activity_level': profile.activity_level,
            },
            goals=goals or ['FITNESS', 'HEALTHY_EATING', 'HYDRATION'],
            availability=avail_dict,
            food_pref={
                'cuisine': food_pref.cuisine if food_pref else 'South Indian',
                'diet_type': food_pref.diet_type if food_pref else 'VEGETARIAN',
            },
            exercise_pref={
                'preferred_exercises': ex_pref.preferred_exercises if ex_pref else ['Walking'],
                'preferred_duration': ex_pref.preferred_duration if ex_pref else 30,
            }
        )

        count = 0
        for item in routine_items:
            t_time = datetime.strptime(item['scheduled_time'], '%H:%M:%S').time()
            DailyTask.objects.create(
                user=user,
                title=item['title'],
                task_type=item['task_type'],
                description=item.get('description', ''),
                date=target_date,
                scheduled_time=t_time,
                duration=item.get('duration', 15),
                priority=item.get('priority', DailyTask.Priority.MEDIUM),
                status=DailyTask.Status.PENDING,
                ai_explanation=item.get('ai_explanation', '')
            )
            count += 1
        return count

    @action(detail=True, methods=['put'])
    def complete(self, request, pk=None):
        task = self.get_object()
        task.status = DailyTask.Status.COMPLETED
        now = timezone.now()
        task.completed_at = now
        task.save()

        # Log behavior
        BehaviorRecord.objects.create(
            user=request.user,
            task=task,
            task_type=task.task_type,
            scheduled_time=task.scheduled_time,
            actual_completion_time=now.time(),
            completed=True,
            skipped=False,
            rescheduled=False,
            day_of_week=task.date.weekday()
        )

        return Response({
            'message': 'Task marked as completed.',
            'task': self.get_serializer(task).data
        })

    @action(detail=True, methods=['put'])
    def skip(self, request, pk=None):
        task = self.get_object()
        task.status = DailyTask.Status.SKIPPED
        task.save()

        BehaviorRecord.objects.create(
            user=request.user,
            task=task,
            task_type=task.task_type,
            scheduled_time=task.scheduled_time,
            completed=False,
            skipped=True,
            rescheduled=False,
            day_of_week=task.date.weekday()
        )

        return Response({
            'message': 'Task marked as skipped.',
            'task': self.get_serializer(task).data
        })

    @action(detail=True, methods=['put'])
    def reschedule(self, request, pk=None):
        task = self.get_object()
        serializer = RescheduleTaskSerializer(data=request.data)
        if not serializer.is_valid():
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

        new_time = serializer.validated_data.get('new_time')
        reason = serializer.validated_data.get('reason', 'Rescheduled by user')

        if not new_time:
            # Intelligent recommendation requested
            weekday = task.date.weekday()
            avail = DailyAvailability.objects.filter(user=request.user, day=weekday).first()
            blocked = []
            if avail and avail.unavailable_periods:
                for p in avail.unavailable_periods:
                    blocked.append((UserProfiler.parse_time_to_minutes(p['start']), UserProfiler.parse_time_to_minutes(p['end']), p.get('label', 'Busy')))

            existing_tasks = list(DailyTask.objects.filter(
                user=request.user,
                date=task.date
            ).exclude(id=task.id).values('scheduled_time', 'duration', 'title'))

            planner = AdaptiveRoutinePlanner()
            rec_result = planner.find_best_reschedule_slot(
                task={'task_type': task.task_type, 'duration': task.duration},
                blocked_intervals=blocked,
                existing_tasks=existing_tasks
            )

            rec_time_str = rec_result['recommended_time']
            new_time = datetime.strptime(rec_time_str, '%H:%M:%S').time()
            explanation = rec_result.get('explanation', '')
        else:
            explanation = f"Rescheduled to {new_time.strftime('%H:%M')} upon your request."

        if not task.original_time:
            task.original_time = task.scheduled_time

        task.scheduled_time = new_time
        task.status = DailyTask.Status.RESCHEDULED
        task.rescheduled_at = timezone.now()
        task.rescheduled_reason = reason
        task.ai_explanation = explanation
        task.save()

        # Log behavior
        BehaviorRecord.objects.create(
            user=request.user,
            task=task,
            task_type=task.task_type,
            scheduled_time=task.original_time or new_time,
            completed=False,
            skipped=False,
            rescheduled=True,
            day_of_week=task.date.weekday()
        )

        return Response({
            'message': 'Task rescheduled successfully.',
            'task': self.get_serializer(task).data,
            'ai_explanation': explanation
        })
