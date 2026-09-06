from rest_framework import serializers, viewsets, permissions
from .models import ExerciseItem


class ExerciseItemSerializer(serializers.ModelSerializer):
    class Meta:
        model = ExerciseItem
        fields = '__all__'


class ExerciseItemViewSet(viewsets.ReadOnlyModelViewSet):
    permission_classes = [permissions.IsAuthenticated]
    serializer_class = ExerciseItemSerializer
    queryset = ExerciseItem.objects.all()

    def get_queryset(self):
        qs = ExerciseItem.objects.all()
        category = self.request.query_params.get('category')
        diff = self.request.query_params.get('difficulty')
        if category:
            qs = qs.filter(category=category)
        if diff:
            qs = qs.filter(difficulty=diff)
        return qs
