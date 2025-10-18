{{/*
################################################################################
# Helper Template Definitions — Ollama Helm Chart
# ------------------------------------------------------------------------------
# These helpers define reusable functions for consistent naming, labeling, and 
# chart management across all resources.
################################################################################
*/}}

{{/*
Expand the base name of the chart.
Used as a fallback for resource names.
*/}}
{{- define "ollama.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Generate a fully qualified name for resources.
Includes Helm release name to ensure uniqueness in shared clusters.
*/}}
{{- define "ollama.fullname" -}}
{{- if .Values.fullnameOverride -}}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s" .Release.Name (include "ollama.name" .) | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}

{{/*
Standardized labels for Kubernetes resources.
Follows Helm recommended label schema.
*/}}
{{- define "ollama.labels" -}}
app.kubernetes.io/name: {{ include "ollama.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end -}}
