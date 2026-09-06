from rest_framework import status, views, viewsets, permissions
from rest_framework.response import Response
from .models import HealthProfile, UserGoal, FoodPreference, ExercisePreference, DailyAvailability
from .serializers import (
    HealthProfileSerializer,
    UserGoalSerializer,
    FoodPreferenceSerializer,
    ExercisePreferenceSerializer,
    DailyAvailabilitySerializer,
    CompleteOnboardingSerializer,
)


class HealthProfileView(views.APIView):
    permission_classes = [permissions.IsAuthenticated]

    def get(self, request):
        profile, _ = HealthProfile.objects.get_or_create(user=request.user)
        serializer = HealthProfileSerializer(profile)
        return Response(serializer.data)

    def put(self, request):
        profile, _ = HealthProfile.objects.get_or_create(user=request.user)
        serializer = HealthProfileSerializer(profile, data=request.data, partial=True)
        if serializer.is_valid():
            serializer.save()
            return Response(serializer.data)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


class UserGoalViewSet(viewsets.ModelViewSet):
    permission_classes = [permissions.IsAuthenticated]
    serializer_class = UserGoalSerializer

    def get_queryset(self):
        return UserGoal.objects.filter(user=self.request.user)

    def perform_create(self, serializer):
        serializer.save(user=self.request.user)


class FoodPreferenceView(views.APIView):
    permission_classes = [permissions.IsAuthenticated]

    def get(self, request):
        pref, _ = FoodPreference.objects.get_or_create(user=request.user)
        return Response(FoodPreferenceSerializer(pref).data)

    def put(self, request):
        pref, _ = FoodPreference.objects.get_or_create(user=request.user)
        serializer = FoodPreferenceSerializer(pref, data=request.data, partial=True)
        if serializer.is_valid():
            serializer.save()
            return Response(serializer.data)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


class ExercisePreferenceView(views.APIView):
    permission_classes = [permissions.IsAuthenticated]

    def get(self, request):
        pref, _ = ExercisePreference.objects.get_or_create(user=request.user)
        return Response(ExercisePreferenceSerializer(pref).data)

    def put(self, request):
        pref, _ = ExercisePreference.objects.get_or_create(user=request.user)
        serializer = ExercisePreferenceSerializer(pref, data=request.data, partial=True)
        if serializer.is_valid():
            serializer.save()
            return Response(serializer.data)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


class DailyAvailabilityViewSet(viewsets.ModelViewSet):
    permission_classes = [permissions.IsAuthenticated]
    serializer_class = DailyAvailabilitySerializer

    def get_queryset(self):
        return DailyAvailability.objects.filter(user=self.request.user)

    def perform_create(self, serializer):
        serializer.save(user=self.request.user)


class CompleteOnboardingView(views.APIView):
    permission_classes = [permissions.IsAuthenticated]

    def post(self, request):
        serializer = CompleteOnboardingSerializer(data=request.data)
        if not serializer.is_valid():
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

        data = serializer.validated_data
        user = request.user

        # 1. HealthProfile
        HealthProfile.objects.update_or_create(
            user=user,
            defaults={
                'age': data.get('age', 25),
                'height': data.get('height', 170.0),
                'weight': data.get('weight', 65.0),
                'activity_level': data.get('activity_level', 'MODERATELY_ACTIVE'),
                'wake_time': data.get('wake_time', '06:30:00'),
                'sleep_time': data.get('sleep_time', '22:30:00'),
            }
        )

        # 2. Goals
        for g in data.get('goals', []):
            UserGoal.objects.update_or_create(
                user=user,
                goal_type=g,
                defaults={'is_active': True, 'target': f"Target for {g}"}
            )

        # 3. FoodPreference
        FoodPreference.objects.update_or_create(
            user=user,
            defaults={
                'diet_type': data.get('diet_type', 'VEGETARIAN'),
                'preferences': data.get('food_preferences', []),
                'allergies': data.get('allergies', []),
                'cuisine': data.get('cuisine', 'South Indian'),
            }
        )

        # 4. ExercisePreference
        ExercisePreference.objects.update_or_create(
            user=user,
            defaults={
                'preferred_exercises': data.get('preferred_exercises', ['Walking']),
                'preferred_duration': data.get('preferred_duration', 30),
                'fitness_level': data.get('fitness_level', 'BEGINNER'),
            }
        )

        # 5. Availability (populate 7 days)
        unavail = data.get('unavailable_periods', [])
        for day_idx in range(7):
            DailyAvailability.objects.update_or_create(
                user=user,
                day=day_idx,
                defaults={
                    'start_time': data.get('availability_start', '07:00:00'),
                    'end_time': data.get('availability_end', '22:00:00'),
                    'unavailable_periods': unavail if day_idx < 5 else []
                }
            )

        return Response({'message': 'Onboarding profile saved successfully.'}, status=status.HTTP_200_OK)
