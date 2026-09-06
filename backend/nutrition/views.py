from rest_framework import serializers, viewsets, permissions
from .models import FoodItem


class FoodItemSerializer(serializers.ModelSerializer):
    class Meta:
        model = FoodItem
        fields = '__all__'


class FoodItemViewSet(viewsets.ReadOnlyModelViewSet):
    permission_classes = [permissions.IsAuthenticated]
    serializer_class = FoodItemSerializer
    queryset = FoodItem.objects.all()

    def get_queryset(self):
        qs = FoodItem.objects.all()
        meal_type = self.request.query_params.get('meal_type')
        diet_type = self.request.query_params.get('diet_type')
        if meal_type:
            qs = qs.filter(meal_type=meal_type)
        if diet_type:
            qs = qs.filter(diet_type=diet_type)
        return qs
