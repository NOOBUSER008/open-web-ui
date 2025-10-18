{{/*
################################################################################
# Helper Template Definitions — Open WebUI Helm Chart
# ------------------------------------------------------------------------------
# Provides standardized naming and labeling conventions used across chart
# templates. Following Helm best practices ensures consistent, predictable 
# resource names and metadata.
################################################################################
*/}}

{{/*
Return the base name of the chart.
*/}}
{{- define "openwebui.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Generate a fully qualified name for resources.
Combines release name and chart name for uniqueness across namespaces.
*/}}
{{- define "openwebui.fullname" -}}
{{- if .Values.fullnameOverride -}}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s" .Release.Name (include "openwebui.name" .) | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}

{{/*
Define common Kubernetes labels.
Aligns with Helm's recommended label schema for interoperability.
*/}}
{{- define "openwebui.labels" -}}
app.kubernetes.io/name: {{ include "openwebui.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end -}}
