{{/*
Expand the name of the chart.
*/}}
{{- define "openclaw.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "openclaw.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "openclaw.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "openclaw.labels" -}}
helm.sh/chart: {{ include "openclaw.chart" . }}
{{ include "openclaw.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "openclaw.selectorLabels" -}}
app.kubernetes.io/name: {{ include "openclaw.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "openclaw.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "openclaw.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Create the name of the config map
*/}}
{{- define "openclaw.configMapName" -}}
{{- include "openclaw.fullname" . }}-config
{{- end }}

{{/*
Create the name of the secret
*/}}
{{- define "openclaw.secretName" -}}
{{- include "openclaw.fullname" . }}-secret
{{- end }}

{{/*
Create the name of the persistent volume claim
*/}}
{{- define "openclaw.pvcName" -}}
{{- include "openclaw.fullname" . }}-data
{{- end }}

{{/*
Generate environment variables from values
Excludes any keys that are provided via existingSecret or secret
*/}}
{{- define "openclaw.envVars" -}}
{{- $secretKeys := dict }}
{{- if .Values.existingSecret.enabled }}
  {{- range .Values.existingSecret.keys }}
    {{- $_ := set $secretKeys .name true }}
  {{- end }}
{{- else if .Values.secret.enabled }}
  {{- range $key, $value := .Values.secret.data }}
    {{- $_ := set $secretKeys $key true }}
  {{- end }}
{{- end }}
{{- range $key, $value := .Values.env }}
{{- if and (ne $value "") (not (hasKey $secretKeys $key)) }}
- name: {{ $key }}
  value: {{ $value | quote }}
{{- end }}
{{- end }}
{{- if .Values.extraEnv }}
{{- toYaml .Values.extraEnv }}
{{- end }}
{{- end }}
