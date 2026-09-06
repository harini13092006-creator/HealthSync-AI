from rest_framework import views, viewsets, status, permissions
from rest_framework.response import Response
from django.utils import timezone

from .models import RecommendationHistory
from .serializers import (
    RecommendationHistorySerializer,
    GenerateRecommendationSerializer,
    MvtRequestSerializer,
)
from profiles.models import HealthProfile, UserGoal, FoodPreference, ExercisePreference
from nutrition.models import FoodItem
from exercise.models import ExerciseItem
from ai_engine.recommendation import HealthSyncRecommender


class RecommendationHistoryViewSet(viewsets.ModelViewSet):
    permission_classes = [permissions.IsAuthenticated]
    serializer_class = RecommendationHistorySerializer

    def get_queryset(self):
        return RecommendationHistory.objects.filter(user=self.request.user)

    def perform_create(self, serializer):
        serializer.save(user=self.request.user)


class FoodRecommendationsView(views.APIView):
    permission_classes = [permissions.IsAuthenticated]

    def get(self, request):
        user = request.user
        meal_type = request.query_params.get('meal_type', 'ANY')

        food_pref = FoodPreference.objects.filter(user=user).first()
        diet_type = food_pref.diet_type if food_pref else 'VEGETARIAN'
        prefs = food_pref.preferences if food_pref else []
        cuisine = food_pref.cuisine if food_pref else 'South Indian'

        goals = list(UserGoal.objects.filter(user=user, is_active=True).values_list('goal_type', flat=True))
        goal = goals[0] if goals else 'HEALTHY_EATING'

        # Fetch foods from database
        all_foods = list(FoodItem.objects.values())
        recommender = HealthSyncRecommender()
        recommender.food_engine.food_items = all_foods
        recommender.food_engine._fit_vectorizer()

        recommendations = recommender.get_food_recommendations(
            diet_type=diet_type,
            preferences=prefs,
            cuisine=cuisine,
            goal=goal,
            meal_type=meal_type,
            limit=6
        )

        return Response({
            'diet_type': diet_type,
            'cuisine': cuisine,
            'meal_type': meal_type,
            'recommendations': recommendations
        })


class ExerciseRecommendationsView(views.APIView):
    permission_classes = [permissions.IsAuthenticated]

    def get(self, request):
        user = request.user
        duration = int(request.query_params.get('duration', 30))

        ex_pref = ExercisePreference.objects.filter(user=user).first()
        profile = HealthProfile.objects.filter(user=user).first()

        fitness_level = ex_pref.fitness_level if ex_pref else 'BEGINNER'
        preferred_cats = ex_pref.preferred_exercises if ex_pref else ['Walking']
        activity_level = profile.activity_level if profile else 'MODERATELY_ACTIVE'

        goals = list(UserGoal.objects.filter(user=user, is_active=True).values_list('goal_type', flat=True))
        goal = goals[0] if goals else 'FITNESS'

        all_exercises = list(ExerciseItem.objects.values())
        recommender = HealthSyncRecommender()
        recommender.exercise_engine.exercise_items = all_exercises

        recommendations = recommender.get_exercise_recommendations(
            fitness_level=fitness_level,
            preferred_categories=preferred_cats,
            duration=duration,
            activity_level=activity_level,
            goal=goal,
            limit=6
        )

        return Response({
            'fitness_level': fitness_level,
            'available_minutes': duration,
            'recommendations': recommendations
        })


class MinimumViableTaskView(views.APIView):
    permission_classes = [permissions.IsAuthenticated]

    def post(self, request):
        serializer = MvtRequestSerializer(data=request.data)
        if not serializer.is_valid():
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

        minutes = serializer.validated_data.get('minutes', 10)
        activity = serializer.validated_data.get('activity', 'Walking')

        recommender = HealthSyncRecommender()
        mvt = recommender.get_minimum_viable_task(minutes=minutes, activity=activity)

        # Log to RecommendationHistory
        RecommendationHistory.objects.create(
            user=request.user,
            recommendation_type=RecommendationHistory.RecType.EXERCISE,
            title=mvt['title'],
            recommendation=mvt,
            explanation=mvt['explanation'],
            recommended_time=timezone.now()
        )

        return Response(mvt, status=status.HTTP_200_OK)


class GenerateRecommendationView(views.APIView):
    """
    POST /api/recommendations/generate/
    """
    permission_classes = [permissions.IsAuthenticated]

    def post(self, request):
        serializer = GenerateRecommendationSerializer(data=request.data)
        if not serializer.is_valid():
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

        rtype = serializer.validated_data.get('type', 'FOOD')
        recommender = HealthSyncRecommender()

        if rtype == 'FOOD':
            food_pref = FoodPreference.objects.filter(user=request.user).first()
            diet = food_pref.diet_type if food_pref else 'VEGETARIAN'
            recs = recommender.get_food_recommendations(diet_type=diet, limit=3)
            result = recs[0] if recs else {}
            title = result.get('name', 'Healthy Meal')
            explanation = result.get('explanation', 'Matches your dietary preference.')
        elif rtype == 'EXERCISE':
            ex_pref = ExercisePreference.objects.filter(user=request.user).first()
            fit = ex_pref.fitness_level if ex_pref else 'BEGINNER'
            recs = recommender.get_exercise_recommendations(fitness_level=fit, limit=3)
            result = recs[0] if recs else {}
            title = result.get('name', 'Movement Routine')
            explanation = result.get('explanation', 'Suits your physical stamina.')
        elif rtype == 'MEDITATION':
            result = recommender.get_meditation_recommendation(target_time='Morning', available_minutes=10) or {}
            title = result.get('title', 'Mindfulness Breathing')
            explanation = result.get('explanation', 'Centers your focus.')
        else:
            result = {'routine': 'Daily schedule updated'}
            title = 'Adaptive Daily Routine'
            explanation = 'Optimized around your wake and sleep schedule.'

        history = RecommendationHistory.objects.create(
            user=request.user,
            recommendation_type=rtype,
            title=title,
            recommendation=result,
            explanation=explanation,
            recommended_time=timezone.now()
        )

        return Response({
            'message': 'Recommendation generated successfully.',
            'recommendation': RecommendationHistorySerializer(history).data
        }, status=status.HTTP_201_CREATED)
