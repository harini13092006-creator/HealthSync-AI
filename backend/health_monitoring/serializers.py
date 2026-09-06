from rest_framework import serializers
from .models import ActivityRecord, SleepRecord, WaterRecord, MealRecord, MeditationRecord


class ActivityRecordSerializer(serializers.ModelSerializer):
    class Meta:
        model = ActivityRecord
        fields = ('id', 'date', 'steps', 'active_minutes', 'exercise_minutes', 'calories_burned', 'created_at')
        read_only_fields = ('id', 'created_at')


class SleepRecordSerializer(serializers.ModelSerializer):
    class Meta:
        model = SleepRecord
        fields = ('id', 'date', 'sleep_start', 'sleep_end', 'duration', 'quality_rating', 'created_at')
        read_only_fields = ('id', 'created_at')


class WaterRecordSerializer(serializers.ModelSerializer):
    class Meta:
        model = WaterRecord
        fields = ('id', 'date', 'quantity_ml', 'time', 'created_at')
        read_only_fields = ('id', 'created_at')


class MealRecordSerializer(serializers.ModelSerializer):
    class Meta:
        model = MealRecord
        fields = ('id', 'date', 'meal_type', 'food', 'calories', 'notes', 'time', 'created_at')
        read_only_fields = ('id', 'created_at')


class MeditationRecordSerializer(serializers.ModelSerializer):
    class Meta:
        model = MeditationRecord
        fields = ('id', 'date', 'type', 'duration', 'notes', 'created_at')
        read_only_fields = ('id', 'created_at')
