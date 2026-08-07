{{- define "thecrowler.fullname" -}}
{{- .Release.Name | trunc 45 | trimSuffix "-" -}}
{{- end }}

{{- define "thecrowler.dbName" -}}
{{- printf "%s-db" (include "thecrowler.fullname" .) | trunc 63 | trimSuffix "-" -}}
{{- end }}

{{- define "thecrowler.dbHeadlessName" -}}
{{- printf "%s-db-headless" (include "thecrowler.fullname" .) | trunc 63 | trimSuffix "-" -}}
{{- end }}

{{- define "thecrowler.apiName" -}}
{{- printf "%s-api" (include "thecrowler.fullname" .) | trunc 63 | trimSuffix "-" -}}
{{- end }}

{{- define "thecrowler.eventsName" -}}
{{- printf "%s-events" (include "thecrowler.fullname" .) | trunc 63 | trimSuffix "-" -}}
{{- end }}

{{- define "thecrowler.engineName" -}}
{{- printf "%s-engine" (include "thecrowler.fullname" .) | trunc 63 | trimSuffix "-" -}}
{{- end }}

{{- define "thecrowler.vdiName" -}}
{{- printf "%s-vdi" (include "thecrowler.fullname" .) | trunc 63 | trimSuffix "-" -}}
{{- end }}

{{- define "thecrowler.jaegerName" -}}
{{- printf "%s-jaeger" (include "thecrowler.fullname" .) | trunc 63 | trimSuffix "-" -}}
{{- end }}

{{- define "thecrowler.pushgatewayName" -}}
{{- printf "%s-push-gateway" (include "thecrowler.fullname" .) | trunc 63 | trimSuffix "-" -}}
{{- end }}

{{- define "thecrowler.labels" -}}
app.kubernetes.io/part-of: thecrowler
app.kubernetes.io/instance: {{ .Release.Name | quote }}
app.kubernetes.io/managed-by: {{ .Release.Service | quote }}
helm.sh/chart: {{ printf "%s-%s" .Chart.Name .Chart.Version | quote }}
{{- end }}

{{- define "thecrowler.selectorLabels" -}}
app.kubernetes.io/instance: {{ .Release.Name | quote }}
{{- end }}

{{- define "thecrowler.configMapName" -}}
{{- if .Values.config.create -}}
{{- printf "%s-config" (include "thecrowler.fullname" .) | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- required "config.existingConfigMap is required when config.create=false" .Values.config.existingConfigMap -}}
{{- end -}}
{{- end }}

{{- define "thecrowler.secretName" -}}
{{- if .Values.secrets.create -}}
{{- printf "%s-secrets" (include "thecrowler.fullname" .) | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- required "secrets.existingSecret is required when secrets.create=false" .Values.secrets.existingSecret -}}
{{- end -}}
{{- end }}

{{- define "thecrowler.databaseHost" -}}
{{- if .Values.database.enabled -}}
{{- include "thecrowler.dbName" . -}}
{{- else -}}
{{- required "database.host is required when database.enabled=false" .Values.database.host -}}
{{- end -}}
{{- end }}

{{- define "thecrowler.configChecksum" -}}
{{- if .Values.config.create -}}
{{- .Values.config.content | sha256sum -}}
{{- else -}}
{{- .Values.config.rolloutToken | sha256sum -}}
{{- end -}}
{{- end }}

{{- define "thecrowler.secretChecksum" -}}
{{- if .Values.secrets.create -}}
{{- toJson .Values.secrets.data | sha256sum -}}
{{- else -}}
{{- .Values.secrets.rolloutToken | sha256sum -}}
{{- end -}}
{{- end }}
