from rest_framework import serializers
from .models import RecommendationHistory


class RecommendationHistorySerializer(serializers.ModelSerializer):
    class Meta:
        model = RecommendationHistory
        fields = ('id', 'recommendation_type', 'title', 'recommendation', 'explanation', 'recommended_time', 'accepted', 'completed', 'feedback', 'created_at')
        read_only_fields = ('id', 'created_at')


class GenerateRecommendationSerializer(serializers.Serializer):
    type = serializers.ChoiceField(choices=['FOOD', 'EXERCISE', 'MEDITATION', 'ROUTINE'], default='FOOD')
    meal_type = serializers.CharField(required=False, default='ANY')
    duration = serializers.IntegerField(required=False, default=20)


class MvtRequestSerializer(serializers.Serializer):
    minutes = serializers.IntegerField(required=False, default=10)
    activity = serializers.CharField(required=False, default='Walking')
