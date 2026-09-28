#!/bin/bash
set -euo pipefail

# Configuración
AWS_REGION="us-east-1"
ACCOUNT_ID="213680573274"
ECR_REPO_NAME="taller-devops-monorepo"
ECR_URI="${ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ECR_REPO_NAME}"
IMAGE_TAG="${1:-latest}"

echo "🚀 Construyendo y subiendo imágenes a ECR..."
echo "📦 URI: ${ECR_URI}"
echo "🏷️  Tag: ${IMAGE_TAG}"
echo ""

# Autenticarse en ECR
echo "🔐 Autenticando en ECR..."
aws ecr get-login-password --region ${AWS_REGION} | \
  docker login --username AWS --password-stdin ${ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com

# Construir backend
echo "🏗️ Construyendo backend..."
cd /home/jonatan-hernandez/Taller-DevOps-Monorepo-CodeDeploy-OnPremise
docker build -t taller-devops-monorepo-backend:${IMAGE_TAG} ./backend

# Construir frontend
echo "🏗️ Construyendo frontend..."
docker build -t taller-devops-monorepo-frontend:${IMAGE_TAG} ./frontend

# Etiquetar para ECR
echo "🏷️ Etiquetando imágenes para ECR..."

# Backend - usar el formato correcto
docker tag taller-devops-monorepo-backend:${IMAGE_TAG} ${ECR_URI}:backend-${IMAGE_TAG}
docker tag taller-devops-monorepo-backend:${IMAGE_TAG} ${ECR_URI}:backend-latest

# Frontend - usar el formato correcto
docker tag taller-devops-monorepo-frontend:${IMAGE_TAG} ${ECR_URI}:frontend-${IMAGE_TAG}
docker tag taller-devops-monorepo-frontend:${IMAGE_TAG} ${ECR_URI}:frontend-latest

# Subir imágenes
echo "⬆️ Subiendo imágenes a ECR..."

# Subir backend
echo "  → Subiendo backend..."
docker push ${ECR_URI}:backend-${IMAGE_TAG}
docker push ${ECR_URI}:backend-latest

# Subir frontend
echo "  → Subiendo frontend..."
docker push ${ECR_URI}:frontend-${IMAGE_TAG}
docker push ${ECR_URI}:frontend-latest

echo ""
echo "✅ Imágenes subidas exitosamente!"
echo ""
echo "📋 Imágenes disponibles:"
echo "  - ${ECR_URI}:backend-${IMAGE_TAG}"
echo "  - ${ECR_URI}:backend-latest"
echo "  - ${ECR_URI}:frontend-${IMAGE_TAG}"
echo "  - ${ECR_URI}:frontend-latest"
