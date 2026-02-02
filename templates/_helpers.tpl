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
{{- if .Values.existingSecret.name }}
  {{- range $envVarName, $secretKey := .Values.existingSecret.keys }}
    {{- $_ := set $secretKeys $envVarName true }}
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

{{/*
Get replica-specific resources
Merges default resources with replica-specific overrides
*/}}
{{- define "openclaw.replicaResources" -}}
{{- $replicaIndex := .replicaIndex | default "0" | toString }}
{{- $defaultResources := .Values.resources }}
{{- $replicaOverride := index .Values.replicaOverrides $replicaIndex }}
{{- if $replicaOverride.resources }}
{{- toYaml $replicaOverride.resources }}
{{- else }}
{{- toYaml $defaultResources }}
{{- end }}
{{- end }}

{{/*
Get replica-specific environment variables
Merges default env vars with replica-specific overrides
*/}}
{{- define "openclaw.replicaEnvVars" -}}
{{- $replicaIndex := .replicaIndex | default "0" | toString }}
{{- $replicaOverride := index .Values.replicaOverrides $replicaIndex }}
{{- if $replicaOverride.env }}
{{- range $key, $value := $replicaOverride.env }}
- name: {{ $key }}
  value: {{ $value | quote }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Get replica-specific node selector
Merges default nodeSelector with replica-specific overrides
*/}}
{{- define "openclaw.replicaNodeSelector" -}}
{{- $replicaIndex := .replicaIndex | default "0" | toString }}
{{- $defaultSelector := .Values.nodeSelector }}
{{- $replicaOverride := index .Values.replicaOverrides $replicaIndex }}
{{- if $replicaOverride.nodeSelector }}
{{- toYaml $replicaOverride.nodeSelector }}
{{- else if $defaultSelector }}
{{- toYaml $defaultSelector }}
{{- end }}
{{- end }}

{{/*
Get replica-specific tolerations
*/}}
{{- define "openclaw.replicaTolerations" -}}
{{- $replicaIndex := .replicaIndex | default "0" | toString }}
{{- $defaultTolerations := .Values.tolerations }}
{{- $replicaOverride := index .Values.replicaOverrides $replicaIndex }}
{{- if $replicaOverride.tolerations }}
{{- toYaml $replicaOverride.tolerations }}
{{- else if $defaultTolerations }}
{{- toYaml $defaultTolerations }}
{{- end }}
{{- end }}

{{/*
Get replica-specific affinity
*/}}
{{- define "openclaw.replicaAffinity" -}}
{{- $replicaIndex := .replicaIndex | default "0" | toString }}
{{- $defaultAffinity := .Values.affinity }}
{{- $replicaOverride := index .Values.replicaOverrides $replicaIndex }}
{{- if $replicaOverride.affinity }}
{{- toYaml $replicaOverride.affinity }}
{{- else if $defaultAffinity }}
{{- toYaml $defaultAffinity }}
{{- end }}
{{- end }}

{{/*
Gateway config JSON for openclaw.json. OpenClaw expects gateway (controlUi only) and channels at the top level.
Used by the gateway ConfigMap; merged into ~/.openclaw/openclaw.json at runtime.
*/}}
{{- define "openclaw.gatewayJson" -}}
{{- $controlUi := .Values.gateway.controlUi | default dict }}
{{- $channels := .Values.channels | default dict }}
{{- $gateway := dict "controlUi" $controlUi }}
{{- $root := dict "gateway" $gateway "channels" $channels }}
{{- $root | toJson }}
{{- end }}
