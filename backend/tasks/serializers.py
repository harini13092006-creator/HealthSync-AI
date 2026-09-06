from rest_framework import serializers
from .models import DailyTask, BehaviorRecord


class DailyTaskSerializer(serializers.ModelSerializer):
    class Meta:
        model = DailyTask
        fields = (
            'id', 'task_type', 'title', 'description', 'date', 'scheduled_time',
            'duration', 'priority', 'status', 'completed_at', 'rescheduled_at',
            'original_time', 'rescheduled_reason', 'ai_explanation', 'created_at'
        )
        read_only_fields = ('id', 'created_at', 'completed_at', 'rescheduled_at')


class RescheduleTaskSerializer(serializers.Serializer):
    new_time = serializers.TimeField(required=False)
    reason = serializers.CharField(required=False, allow_blank=True, default='User requested reschedule')


class BehaviorRecordSerializer(serializers.ModelSerializer):
    class Meta:
        model = BehaviorRecord
        fields = ('id', 'task', 'task_type', 'scheduled_time', 'actual_completion_time', 'completed', 'skipped', 'rescheduled', 'day_of_week', 'created_at')
        read_only_fields = ('id', 'created_at')
