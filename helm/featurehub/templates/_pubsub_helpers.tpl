{{- define "google-pubsub-environment" }}
{{- if .Values.googlepubsub.enabled }}
nats.enabled=false
cloudevents.pubsub.enabled=true
cloudevents.pubsub.project={{ .Values.googlepubsub.project }}

# pubsub has to have a subscription to listen for the original feature update coming from MR, it can't use the original name
cloudevents.enricher.pubsub.subscription-name={{ .Values.googlepubsub.channels.featureEnricher.subscription }}

# when dacha publishes the enriched data, it needs to specify one or more topics to publish on.
cloudevents.enricher.pubsub.channels=webhooks
cloudevents.enricher.pubsub.channel.webhooks={{ .Values.googlepubsub.channels.featureWebhook.topicName }}
# this is "edge" - listening to the cloudevents.mr-edge.pubsub.topic-name
cloudevents.enricher.pubsub.enriched-subscription-name={{ .Values.googlepubsub.channels.featureWebhook.subscription }}

# This is the channel from MR -> Dacha for feature updates
cloudevents.mr-dacha2.pubsub.topic-name={{ .Values.googlepubsub.channels.mrdacha.topicName }}
cloudevents.mr-dacha2.pubsub.subscription-prefix={{ .Values.googlepubsub.channels.mrdacha.dachaPrefix }}

# This is the channel from MR -> Edge for feature updates
cloudevents.mr-edge.pubsub.topic-name={{ .Values.googlepubsub.channels.mredge.topicName }}
cloudevents.mr-edge.pubsub.subscription-prefix={{ .Values.googlepubsub.channels.mredge.edgePrefix }}

# this is the channel from Edge -> MR (Test updates)
cloudevents.edge-mr.pubsub.topic-name={{ .Values.googlepubsub.channels.edgemr.topicName }}
# It comes in via the inbound.channel-names in MR (only)

cloudevents.stats.pubsub.topic-name={{ .Values.googlepubsub.channels.stats.topicName }}
cloudevents.mr-messaging.pubsub.topic-name={{ .Values.googlepubsub.channels.featureChangeMessage.topicName }}


cloudevents.pubsub.min-backoff-delay-seconds={{ .Values.googlepubsub.backOffInSeconds }}

{{- if .Values.googlepubsub.emulator.enabled }}
cloudevents.pubsub.local.host={{ .Values.googlepubsub.emulator.host }}
cloudevents.pubsub.local.topics={{ .Values.googlepubsub.channels.mrdacha.topicName }},{{ .Values.googlepubsub.channels.mredge.topicName }},{{ .Values.googlepubsub.channels.edgemr.topicName }},{{ .Values.googlepubsub.channels.featureWebhook.topicName }},{{ .Values.googlepubsub.channels.mredge.topicName }}
# dacha2 and edge make their own subscribers
cloudevents.pubsub.local.sub-pairs={{ .Values.googlepubsub.channels.featureEnricher.subscription }}={{ .Values.googlepubsub.channels.mredge.topicName }},{{ .Values.googlepubsub.channels.edgemr.subscription }}={{ .Values.googlepubsub.channels.edgemr.topicName }},{{ .Values.googlepubsub.channels.featureWebhook.subscription }}={{ .Values.googlepubsub.channels.featureWebhook.topicName }},{{ .Values.googlepubsub.channels.featureWebhook.subscription }}={{ .Values.googlepubsub.channels.mredge.topicName }}
{{- end }}
{{- end }}
{{- end }}

{{- define "google-pubsub-mr" }}
{{- if .Values.googlepubsub.enabled }}
# these are all the incoming channel data that MR listens to
cloudevents.inbound.channel-names={{ .Values.googlepubsub.channels.edgemr.subscription }}
{{- end }}
{{- end }}

# a duplicate of above
{{- define "google-pubsub-environment-env" }}
{{- if .Values.googlepubsub.enabled }}
nats.enabled: "false"
cloudevents.pubsub.enabled: "true"
cloudevents.pubsub.project: {{ .Values.googlepubsub.project }}

# pubsub has to have a subscription to listen for the original feature update coming from MR, it can't use the original name
cloudevents.enricher.pubsub.subscription-name: {{ .Values.googlepubsub.channels.featureEnricher.subscription }}

# when dacha publishes the enriched data, it needs to specify one or more topics to publish on.
cloudevents.enricher.pubsub.channels: webhooks
cloudevents.enricher.pubsub.channel.webhooks: {{ .Values.googlepubsub.channels.featureWebhook.topicName }}
# this is "edge" - listening to the cloudevents.mr-edge.pubsub.topic-name
cloudevents.enricher.pubsub.enriched-subscription-name: {{ .Values.googlepubsub.channels.featureWebhook.subscription }}

# This is the channel from MR -> Dacha for feature updates
cloudevents.mr-dacha2.pubsub.topic-name: {{ .Values.googlepubsub.channels.mrdacha.topicName }}
cloudevents.mr-dacha2.pubsub.subscription-prefix: {{ .Values.googlepubsub.channels.mrdacha.dachaPrefix }}

# This is the channel from MR -> Edge for feature updates
cloudevents.mr-edge.pubsub.topic-name: {{ .Values.googlepubsub.channels.mredge.topicName }}
cloudevents.mr-edge.pubsub.subscription-prefix: {{ .Values.googlepubsub.channels.mredge.edgePrefix }}

# this is the channel from Edge -> MR (Test updates)
cloudevents.edge-mr.pubsub.topic-name: {{ .Values.googlepubsub.channels.edgemr.topicName }}
# It comes in via the inbound.channel-names in MR (only)

cloudevents.stats.pubsub.topic-name: {{ .Values.googlepubsub.channels.stats.topicName }}
cloudevents.mr-messaging.pubsub.topic-name: {{ .Values.googlepubsub.channels.featureChangeMessage.topicName }}

cloudevents.pubsub.min-backoff-delay-seconds: {{ .Values.googlepubsub.backOffInSeconds | quote }}

{{- if .Values.googlepubsub.emulator.enabled }}
cloudevents.pubsub.local.host: {{ .Values.googlepubsub.emulator.host }}
cloudevents.pubsub.local.topics: {{ .Values.googlepubsub.channels.mrdacha.topicName }},{{ .Values.googlepubsub.channels.mredge.topicName }},{{ .Values.googlepubsub.channels.edgemr.topicName }},{{ .Values.googlepubsub.channels.featureWebhook.topicName }},{{ .Values.googlepubsub.channels.mredge.topicName }}
# dacha2 and edge make their own subscribers
cloudevents.pubsub.local.sub-pairs: {{ .Values.googlepubsub.channels.featureEnricher.subscription }}={{ .Values.googlepubsub.channels.mredge.topicName }},{{ .Values.googlepubsub.channels.edgemr.subscription }}={{ .Values.googlepubsub.channels.edgemr.topicName }},{{ .Values.googlepubsub.channels.featureWebhook.subscription }}={{ .Values.googlepubsub.channels.featureWebhook.topicName }},{{ .Values.googlepubsub.channels.featureWebhook.subscription }}={{ .Values.googlepubsub.channels.mredge.topicName }}
{{- end }}
{{- end }}
{{- end }}

{{- define "google-pubsub-mr-env" }}
{{- if .Values.googlepubsub.enabled }}
# these are all the incoming channel data that MR listens to
cloudevents.inbound.channel-names: {{ .Values.googlepubsub.channels.edgemr.subscription }}
{{- end }}
{{- end }}
