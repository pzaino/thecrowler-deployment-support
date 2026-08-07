{{- define "thecrowler.name" -}}
thecrowler
{{- end }}

{{- define "thecrowler.fullname" -}}
{{- printf "%s" .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- end }}

{{- define "thecrowler.labels" -}}
app.kubernetes.io/part-of: thecrowler
app.kubernetes.io/managed-by: {{ .Release.Service }}
helm.sh/chart: {{ printf "%s-%s" .Chart.Name .Chart.Version | quote }}
{{- end }}

{{- define "thecrowler.configMapName" -}}
{{- if .Values.config.create -}}
{{ printf "%s-config" (include "thecrowler.fullname" .) }}
{{- else -}}
{{ .Values.config.existingConfigMap }}
{{- end -}}
{{- end }}

{{- define "thecrowler.secretName" -}}
{{- if .Values.secrets.create -}}
{{ printf "%s-secrets" (include "thecrowler.fullname" .) }}
{{- else -}}
{{ .Values.secrets.existingSecret }}
{{- end -}}
{{- end }}
