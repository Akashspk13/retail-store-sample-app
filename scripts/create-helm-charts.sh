#!/bin/bash

SERVICES=("catalog" "cart" "orders" "checkout")
DOCKERHUB_USERNAME="akashspk13"  # CHANGE THIS!

for service in "${SERVICES[@]}"; do
  echo "Creating Helm chart for $service..."
  
  # Determine port based on service
  case $service in
    catalog) PORT=8080 ;;
    cart) PORT=8080 ;;
    orders) PORT=8080 ;;
    checkout) PORT=8080 ;;
  esac
  
  # Create Chart.yaml
  cat > deploy/helm/$service/Chart.yaml <<CHART
apiVersion: v2
name: $service
description: Retail Store ${service^} Service
type: application
version: 1.0.0
appVersion: "1.0.0"
CHART

  # Create values.yaml
  cat > deploy/helm/$service/values.yaml <<VALUES
replicaCount: 1

image:
  repository: ${DOCKERHUB_USERNAME}/retail-store-$service
  tag: latest
  pullPolicy: Always

service:
  type: ClusterIP
  port: $PORT
  targetPort: $PORT

resources:
  limits:
    cpu: 500m
    memory: 512Mi
  requests:
    cpu: 250m
    memory: 256Mi

env: []
VALUES

  # Create templates directory
  mkdir -p deploy/helm/$service/templates
  
  # Create deployment
  cat > deploy/helm/$service/templates/deployment.yaml <<DEPLOYMENT
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ .Release.Name }}-$service
  labels:
    app: $service
spec:
  replicas: {{ .Values.replicaCount }}
  selector:
    matchLabels:
      app: $service
  template:
    metadata:
      labels:
        app: $service
    spec:
      containers:
      - name: $service
        image: "{{ .Values.image.repository }}:{{ .Values.image.tag }}"
        imagePullPolicy: {{ .Values.image.pullPolicy }}
        ports:
        - name: http
          containerPort: {{ .Values.service.targetPort }}
          protocol: TCP
        {{- if .Values.env }}
        env:
        {{- toYaml .Values.env | nindent 8 }}
        {{- end }}
        resources:
          {{- toYaml .Values.resources | nindent 10 }}
DEPLOYMENT

  # Create service
  cat > deploy/helm/$service/templates/service.yaml <<SERVICE
apiVersion: v1
kind: Service
metadata:
  name: {{ .Release.Name }}-$service
  labels:
    app: $service
spec:
  type: {{ .Values.service.type }}
  ports:
    - port: {{ .Values.service.port }}
      targetPort: {{ .Values.service.targetPort }}
      protocol: TCP
      name: http
  selector:
    app: $service
SERVICE

done

echo "✅ All Helm charts created successfully!"
