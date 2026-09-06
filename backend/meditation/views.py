from rest_framework import serializers, viewsets, permissions
from .models import MeditationSession


class MeditationSessionSerializer(serializers.ModelSerializer):
    class Meta:
        model = MeditationSession
        fields = '__all__'


class MeditationSessionViewSet(viewsets.ReadOnlyModelViewSet):
    permission_classes = [permissions.IsAuthenticated]
    serializer_class = MeditationSessionSerializer
    queryset = MeditationSession.objects.all()

    def get_queryset(self):
        qs = MeditationSession.objects.all()
        stype = self.request.query_params.get('type')
        if stype:
            qs = qs.filter(session_type=stype)
        return qs
