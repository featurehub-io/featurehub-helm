{{/*
Maintenance windows and the Redis fallback for Dacha2.

See https://docs.featurehub.io/featurehub/latest/maintenance.html

The modes are used in this order: disabled -> warm -> active -> shutdown -> post -> disabled

disabled - normal operation, the maintenance responder is not deployed
warm     - the maintenance responder is deployed, but the ingress does not route traffic to it
active   - the maintenance responder takes all non-edge ingress traffic and Edge blocks feature updates. MR is still
           running, this is when the admin calls MR's maintenance publish-all, so the caches (Dacha2 and Redis) match
           the database before it goes away.
shutdown - as active, and MR (the only service using the database) is scaled to 0 for the database work
post     - MR is scaled back up but the maintenance responder still takes all non-edge ingress traffic
*/}}

{{- define "featurehub.maintenanceResponder.name" -}}
{{- printf "%s-%s" (include "featurehub.fullname" .) "maintenance-responder" }}
{{- end }}

{{- define "featurehub.maintenanceResponder.selectorLabels" -}}
app.kubernetes.io/name: {{ include "featurehub.maintenanceResponder.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{- define "featurehub.maintenanceResponder.labels" -}}
helm.sh/chart: {{ include "featurehub.chart" . }}
{{ include "featurehub.maintenanceResponder.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{- define "featurehub.maintenanceResponder.serviceAccountName" -}}
{{- if .Values.maintenance.responder.serviceAccount.create }}
{{- default (include "featurehub.maintenanceResponder.name" .) .Values.maintenance.responder.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.maintenance.responder.serviceAccount.name }}
{{- end }}
{{- end }}

{{/* "true" if the maintenance responder should be deployed (any mode except disabled) */}}
{{- define "featurehub.maintenance.responderEnabled" -}}
{{- if ne .Values.maintenance.mode "disabled" }}true{{ end }}
{{- end }}

{{/* "true" if non-edge ingress traffic is routed to the maintenance responder (and Edge blocks feature updates) */}}
{{- define "featurehub.maintenance.routesTraffic" -}}
{{- if has .Values.maintenance.mode (list "active" "shutdown" "post") }}true{{ end }}
{{- end }}

{{/* "true" if the services using the database (MR) are scaled to 0 */}}
{{- define "featurehub.maintenance.stopsDatabaseServices" -}}
{{- if eq .Values.maintenance.mode "shutdown" }}true{{ end }}
{{- end }}

{{/*
The maintenance.* env vars, as container env entries. They are only set when all three are set, which lets you announce
a window to Admin users (with the mode still disabled) ahead of time.
*/}}
{{- define "featurehub.maintenance.envs" -}}
{{- with .Values.maintenance }}
{{- if and .start .end .message }}
- name: maintenance.start
  value: {{ .start | quote }}
- name: maintenance.end
  value: {{ .end | quote }}
- name: maintenance.message
  value: {{ .message | quote }}
{{- end }}
{{- end }}
{{- end }}

{{/*
The Retry-After value Edge sends while feature updates are blocked: the end of the window as an HTTP date (as the
maintenance responder sends), or 60 seconds if there is none. maintenance.end has been validated as a UTC timestamp.
*/}}
{{- define "featurehub.maintenance.retryAfter" -}}
{{- if .Values.maintenance.end -}}
{{- dateInZone "Mon, 02 Jan 2006 15:04:05 GMT" (toDate "2006-01-02T15:04:05Z07:00" .Values.maintenance.end) "UTC" -}}
{{- else -}}
60
{{- end -}}
{{- end }}

{{/*
Fails the render if the maintenance or redis values are invalid. The maintenance times are passed as-is to the services
(which parse them with Java's Instant.parse) and to Edge's Retry-After, so they must be ISO-8601 UTC timestamps
with an explicit Z, e.g. 2026-11-17T10:15:30Z.
*/}}
{{- define "featurehub.maintenance.validate" -}}
{{- $m := .Values.maintenance }}
{{- $modes := list "disabled" "warm" "active" "shutdown" "post" }}
{{- if not (has $m.mode $modes) }}
{{- fail (printf "maintenance.mode must be one of %s, not %q" (join ", " $modes) (toString $m.mode)) }}
{{- end }}
{{- range $name := list "start" "end" }}
{{- $value := get $m $name }}
{{- if $value }}
{{- if not (regexMatch "^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}(\\.[0-9]{1,9})?Z$" (toString $value)) }}
{{- fail (printf "maintenance.%s must be an ISO-8601 UTC timestamp ending in Z (e.g. 2026-11-17T10:15:30Z), not %q" $name (toString $value)) }}
{{- end }}
{{- if (toDate "2006-01-02T15:04:05Z07:00" (toString $value)).IsZero }}
{{- fail (printf "maintenance.%s is not a real date: %q" $name (toString $value)) }}
{{- end }}
{{- end }}
{{- end }}
{{- if and (ne $m.mode "disabled") (not (and $m.start $m.end $m.message)) }}
{{- fail (printf "maintenance.mode %s requires maintenance.start, maintenance.end and maintenance.message to be set" $m.mode) }}
{{- end }}
{{- with .Values.redis }}
{{- if not (has .mode (list "standalone" "sentinel" "cluster")) }}
{{- fail (printf "redis.mode must be one of standalone, sentinel, cluster, not %q" (toString .mode)) }}
{{- end }}
{{- if and .url (eq .mode "sentinel") (not .sentinelMaster) }}
{{- fail "redis.sentinelMaster is required when redis.mode is sentinel" }}
{{- end }}
{{- if and .password .existingSecret }}
{{- fail "set only one of redis.password and redis.existingSecret" }}
{{- end }}
{{- end }}
{{- end }}

{{/* "true" if MR should write to Redis */}}
{{- define "featurehub.redis.mrEnabled" -}}
{{- if and .Values.redis.url .Values.redis.managementRepository.enabled }}true{{ end }}
{{- end }}

{{/* "true" if Dacha2 should fall back to Redis */}}
{{- define "featurehub.redis.dachaEnabled" -}}
{{- if and .Values.redis.url .Values.redis.dacha.enabled }}true{{ end }}
{{- end }}

{{- define "featurehub.redis.mrName" -}}
{{- printf "%s-%s" (include "featurehub.fullname" .) "mr-redis" }}
{{- end }}

{{/* fixed name - see dacha/configmap-redis.yaml */}}
{{- define "featurehub.redis.dachaName" -}}
{{- printf "%s-%s" (include "featurehub.fullname" .) "dacha-redis" }}
{{- end }}

{{/* the Secret holding the redis password (and for Dacha2, redis.properties) */}}
{{- define "featurehub.redis.mrSecretName" -}}
{{- default (include "featurehub.redis.mrName" .) .Values.redis.existingSecret }}
{{- end }}

{{- define "featurehub.redis.dachaSecretName" -}}
{{- default (include "featurehub.redis.dachaName" .) .Values.redis.existingSecret }}
{{- end }}

{{/* the CA file is named after its contents, so a CA rotation changes the configured path and Dacha2 reconnects */}}
{{- define "featurehub.redis.caFileName" -}}
{{- printf "ca-%s.pem" (sha256sum .Values.redis.caCert | trunc 12) }}
{{- end }}

{{/* java.util.Properties treats backslash as an escape character */}}
{{- define "featurehub.redis.propertyValue" -}}
{{- toString . | replace "\\" "\\\\" }}
{{- end }}

{{/*
MR's Redis settings, as container env entries. MR holds no cache, so changing these (which rolls MR) is fine.
*/}}
{{- define "featurehub.redis.mrEnvs" -}}
{{- if include "featurehub.redis.mrEnabled" . }}
{{- with .Values.redis }}
- name: redis.url
  value: {{ .url | quote }}
- name: redis.mode
  value: {{ .mode | quote }}
{{- if .keyPrefix }}
- name: redis.key-prefix
  value: {{ .keyPrefix | quote }}
{{- end }}
{{- if .sentinelMaster }}
- name: redis.sentinel.master
  value: {{ .sentinelMaster | quote }}
{{- end }}
{{- if .username }}
- name: redis.username
  value: {{ .username | quote }}
{{- end }}
{{- if .caCert }}
- name: redis.tls.ca-cert
  value: /etc/redis-ca/ca.pem
{{- end }}
{{- end }}
{{- if or .Values.redis.password .Values.redis.existingSecret }}
- name: redis.password
  valueFrom:
    secretKeyRef:
      name: {{ include "featurehub.redis.mrSecretName" . }}
      key: {{ if .Values.redis.existingSecret }}{{ .Values.redis.existingSecretPasswordKey }}{{ else }}password{{ end }}
{{- end }}
{{- end }}
{{- end }}
