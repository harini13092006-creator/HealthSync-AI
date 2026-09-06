from rest_framework import serializers
from .models import HealthProfile, UserGoal, FoodPreference, ExercisePreference, DailyAvailability


class HealthProfileSerializer(serializers.ModelSerializer):
    bmi = serializers.FloatField(read_only=True)

    class Meta:
        model = HealthProfile
        fields = ('id', 'age', 'height', 'weight', 'activity_level', 'wake_time', 'sleep_time', 'bmi', 'created_at', 'updated_at')
        read_only_fields = ('id', 'created_at', 'updated_at', 'bmi')


class UserGoalSerializer(serializers.ModelSerializer):
    class Meta:
        model = UserGoal
        fields = ('id', 'goal_type', 'target', 'is_active', 'created_at')
        read_only_fields = ('id', 'created_at')


class FoodPreferenceSerializer(serializers.ModelSerializer):
    class Meta:
        model = FoodPreference
        fields = ('id', 'diet_type', 'preferences', 'allergies', 'cuisine', 'updated_at')
        read_only_fields = ('id', 'updated_at')


class ExercisePreferenceSerializer(serializers.ModelSerializer):
    class Meta:
        model = ExercisePreference
        fields = ('id', 'preferred_exercises', 'preferred_duration', 'fitness_level', 'updated_at')
        read_only_fields = ('id', 'updated_at')


class DailyAvailabilitySerializer(serializers.ModelSerializer):
    class Meta:
        model = DailyAvailability
        fields = ('id', 'day', 'start_time', 'end_time', 'unavailable_periods')
        read_only_fields = ('id',)


class CompleteOnboardingSerializer(serializers.Serializer):
    age = serializers.IntegerField(required=False, default=25)
    height = serializers.FloatField(required=False, default=170.0)
    weight = serializers.FloatField(required=False, default=65.0)
    activity_level = serializers.CharField(required=False, default='MODERATELY_ACTIVE')
    wake_time = serializers.TimeField(required=False, default='06:30:00')
    sleep_time = serializers.TimeField(required=False, default='22:30:00')

    goals = serializers.ListField(child=serializers.CharField(), required=False, default=list)
    diet_type = serializers.CharField(required=False, default='VEGETARIAN')
    food_preferences = serializers.ListField(child=serializers.CharField(), required=False, default=list)
    allergies = serializers.ListField(child=serializers.CharField(), required=False, default=list)
    cuisine = serializers.CharField(required=False, default='South Indian')

    preferred_exercises = serializers.ListField(child=serializers.CharField(), required=False, default=list)
    preferred_duration = serializers.IntegerField(required=False, default=30)
    fitness_level = serializers.CharField(required=False, default='BEGINNER')

    availability_start = serializers.TimeField(required=False, default='07:00:00')
    availability_end = serializers.TimeField(required=False, default='22:00:00')
    unavailable_periods = serializers.ListField(required=False, default=list)
