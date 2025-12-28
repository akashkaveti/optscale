{{/*
Expand the name of the chart.
*/}}
{{- define "optscale.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
*/}}
{{- define "optscale.fullname" -}}
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
{{- define "optscale.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "optscale.labels" -}}
helm.sh/chart: {{ include "optscale.chart" . }}
{{ include "optscale.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "optscale.selectorLabels" -}}
app.kubernetes.io/name: {{ include "optscale.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Get image with registry
*/}}
{{- define "optscale.image" -}}
{{- $registry := .global.imageRegistry -}}
{{- $repository := .image.repository -}}
{{- $tag := default .global.imageTag .image.tag -}}
{{- if $registry -}}
{{- printf "%s/%s:%s" $registry $repository $tag -}}
{{- else -}}
{{- printf "%s:%s" $repository $tag -}}
{{- end -}}
{{- end }}

{{/*
Wait for service init container
*/}}
{{- define "optscale.waitForService" -}}
- name: wait-{{ .name }}
  image: busybox:1.36
  imagePullPolicy: IfNotPresent
  command: ['sh', '-c', 'until nc -z {{ .service }}.{{ .namespace }}.svc.cluster.local {{ .port }} -w 2; do echo "Waiting for {{ .service }}..."; sleep 2; done']
{{- end }}

{{/*
Wait for MariaDB init container
*/}}
{{- define "optscale.waitForMariadb" -}}
- name: wait-mariadb
  image: {{ include "optscale.image" (dict "global" .Values.global "image" .Values.mariadb.image) }}
  imagePullPolicy: {{ .Values.global.imagePullPolicy }}
  env:
  - name: MYSQL_ROOT_PASSWORD
    valueFrom:
      secretKeyRef:
        name: {{ include "optscale.fullname" . }}-mariadb
        key: password
  command: ['sh', '-c', 'until mysql --connect-timeout=2 -h mariadb.{{ .Release.Namespace }}.svc.cluster.local -p$MYSQL_ROOT_PASSWORD -e "SELECT 1"; do echo "Waiting for MariaDB..."; sleep 2; done']
{{- end }}

{{/*
Readiness probe
*/}}
{{- define "optscale.readinessProbe" -}}
readinessProbe:
  tcpSocket:
    port: {{ .port }}
  initialDelaySeconds: 5
  periodSeconds: 10
{{- end }}

{{/*
Liveness probe
*/}}
{{- define "optscale.livenessProbe" -}}
livenessProbe:
  tcpSocket:
    port: {{ .port }}
  initialDelaySeconds: 15
  periodSeconds: 20
{{- end }}

{{/*
Common environment variables
*/}}
{{- define "optscale.commonEnv" -}}
- name: HX_ETCD_HOST
  value: etcd
- name: HX_ETCD_PORT
  value: "2379"
- name: REQUESTS_CA_BUNDLE
  value: /etc/ssl/certs/ca-certificates.crt
{{- end }}
