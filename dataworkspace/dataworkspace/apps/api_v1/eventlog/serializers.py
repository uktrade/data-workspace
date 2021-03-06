from rest_framework import serializers

from dataworkspace.apps.datasets.models import (
    DataSet,
    ReferenceDataset,
    VisualisationLink,
)
from dataworkspace.apps.eventlog.models import EventLog
from dataworkspace.apps.applications.models import VisualisationApproval
from dataworkspace.apps.explorer.models import Query


class EventLogDatasetSerializer(serializers.ModelSerializer):
    type = serializers.SerializerMethodField()

    class Meta:
        model = DataSet
        fields = ('id', 'type', 'name')

    def get_type(self, obj):
        return obj.get_type_display()


class EventLogReferenceDatasetSerializer(serializers.ModelSerializer):
    type = serializers.SerializerMethodField()

    class Meta:
        model = ReferenceDataset
        fields = ('id', 'type', 'name')

    def get_type(self, obj):
        return obj.get_type_display()


class EventLogVisualisationApprovalSerialiser(serializers.ModelSerializer):
    type = serializers.SerializerMethodField()
    name = serializers.SerializerMethodField()

    class Meta:
        model = VisualisationApproval
        fields = ('id', 'type', 'name')

    def get_type(self, obj):
        return 'VisualisationApproval'

    def get_name(self, obj):
        return obj.visualisation.name


class EventLogVisualisationLinkSerializer(serializers.ModelSerializer):
    type = serializers.SerializerMethodField()
    name = serializers.SerializerMethodField()

    class Meta:
        model = VisualisationLink
        fields = ('id', 'type', 'name')

    def get_type(self, obj):
        return obj.visualisation_type

    def get_name(self, obj):
        return obj.name


class EventLogDataExplorerQuerySerializer(serializers.ModelSerializer):
    name = serializers.SerializerMethodField()

    class Meta:
        model = Query
        fields = ('id', 'name')

    def get_name(self, obj):
        return obj.title


class EventLogRelatedObjectField(serializers.RelatedField):
    def to_representation(  # pylint: disable=inconsistent-return-statements
        self, value
    ):
        if isinstance(value, DataSet):
            return EventLogDatasetSerializer(value).data
        if isinstance(value, ReferenceDataset):
            return EventLogReferenceDatasetSerializer(value).data
        if isinstance(value, VisualisationApproval):
            return EventLogVisualisationApprovalSerialiser(value).data
        if isinstance(value, VisualisationLink):
            return EventLogVisualisationLinkSerializer(value).data
        if isinstance(value, Query):
            return EventLogDataExplorerQuerySerializer(value).data


class EventLogSerializer(serializers.ModelSerializer):
    related_object = EventLogRelatedObjectField(read_only=True)
    event_type = serializers.SerializerMethodField()

    class Meta:
        model = EventLog
        fields = ('id', 'timestamp', 'event_type', 'user_id', 'related_object', 'extra')

    def get_event_type(self, obj):
        return obj.get_event_type_display()
