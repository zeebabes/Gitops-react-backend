{{- define "frontend-chart.fullname" -}}
{{- printf "%s-%s" .Release.Name .Chart.Name | trunc 63 | trimSuffix "-" -}}
{{- end }}

{{- define "fullname" -}}
{{ include "frontend-chart.fullname" . }}
{{- end }}