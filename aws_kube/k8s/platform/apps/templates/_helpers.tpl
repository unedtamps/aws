{{- define "platform-apps.labels" -}}
app.kubernetes.io/name: {{ .Chart.Name }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/part-of: platform
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end -}}
