from rest_framework import serializers
from .models import DailyWellnessScore


class DailyWellnessScoreSerializer(serializers.ModelSerializer):
    class Meta:
        model = DailyWellnessScore
        fields = (
            'id', 'date', 'total_score', 'task_adherence_score', 'activity_score',
            'hydration_score', 'sleep_score', 'meditation_score', 'summary_text', 'calculated_at'
        )
        read_only_fields = ('id', 'calculated_at')
