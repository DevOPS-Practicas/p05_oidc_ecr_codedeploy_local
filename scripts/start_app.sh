#!/bin/bash
set -euo pipefail

# Configuración
AWS_REGION="${AWS_REGION:-us-east-1}"
ECR_REPO_NAME="taller-devops-monorepo"
ACCOUNT_ID="213680573274"
ECR_URI="${ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ECR_REPO_NAME}"
IMAGE_TAG="${IMAGE_TAG:-latest}"

echo "🚀 Iniciando despliegue desde ECR..."
echo "📦 URI: ${ECR_URI}"
echo "🏷️ Tag: ${IMAGE_TAG}"

cd /opt/mi-app

# Verificar credenciales AWS
echo "🔐 Verificando credenciales AWS..."

# Opción 1: Usar variables de entorno
if [ -n "${AWS_ACCESS_KEY_ID:-}" ] && [ -n "${AWS_SECRET_ACCESS_KEY:-}" ]; then
    echo "✅ Usando credenciales de variables de entorno"
    export AWS_ACCESS_KEY_ID="${AWS_ACCESS_KEY_ID}"
    export AWS_SECRET_ACCESS_KEY="${AWS_SECRET_ACCESS_KEY}"
    export AWS_REGION="${AWS_REGION}"

# Opción 2: Usar archivo de credenciales de AWS CLI
elif [ -f "${HOME}/.aws/credentials" ]; then
    echo "✅ Usando credenciales de ~/.aws/credentials"
    export AWS_ACCESS_KEY_ID=$(aws configure get aws_access_key_id)
    export AWS_SECRET_ACCESS_KEY=$(aws configure get aws_secret_access_key)
    export AWS_REGION=$(aws configure get region)

# Opción 3: Usar archivo de credenciales del usuario root
elif [ -f "/root/.aws/credentials" ]; then
    echo "✅ Usando credenciales de /root/.aws/credentials"
    export AWS_ACCESS_KEY_ID=$(sudo aws configure get aws_access_key_id)
    export AWS_SECRET_ACCESS_KEY=$(sudo aws configure get aws_secret_access_key)
    export AWS_REGION=$(sudo aws configure get region)

else
    echo "❌ Error: No se encontraron credenciales AWS"
    echo "🔧 Solución:"
    echo "  1. Ejecuta: aws configure"
    echo "  2. O exporta: export AWS_ACCESS_KEY_ID=... && export AWS_SECRET_ACCESS_KEY=..."
    exit 1
fi

# Verificar que las credenciales funcionan
if ! aws sts get-caller-identity &>/dev/null; then
    echo "❌ Error: Credenciales AWS inválidas"
    echo "🔧 Verifica tus credenciales con: aws sts get-caller-identity"
    exit 1
fi

echo "✅ Credenciales AWS verificadas"
echo "👤 Usuario: $(aws sts get-caller-identity --query Arn --output text)"

# Autenticarse en ECR
echo "🔐 Autenticando en ECR..."
if ! aws ecr get-login-password --region ${AWS_REGION} | \
    docker login --username AWS --password-stdin ${ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com; then
    echo "❌ Error: Falló la autenticación en ECR"
    echo "🔍 Diagnóstico:"
    echo "  - ¿El usuario tiene permisos para ECR?"
    echo "  - ¿Las credenciales son correctas?"
    echo "  - ¿La región es correcta?"
    exit 1
fi

echo "✅ Autenticación exitosa"

# Exportar variables para docker-compose
export ECR_URI="${ECR_URI}"
export IMAGE_TAG="${IMAGE_TAG}"

# Detener contenedores actuales
echo "🛑 Deteniendo contenedores actuales..."
docker compose -f docker-compose.yml down --remove-orphans || true

# Descargar imágenes desde ECR
echo "⬇️ Descargando imágenes desde ECR..."
docker compose -f docker-compose.yml pull

# Levantar contenedores
echo "🔄 Levantando contenedores..."
docker compose -f docker-compose.yml up -d

# Verificar estado
echo "✅ Verificando estado de los contenedores..."
sleep 5
docker compose -f docker-compose.yml ps

# Verificar salud
echo "🏥 Verificando health checks..."
if docker compose -f docker-compose.yml ps --format json | grep -q '"Health":"healthy"'; then
    echo "✅ Todos los servicios están saludables"
else
    echo "⚠️ Algunos servicios pueden no estar saludables. Revisa los logs:"
    docker compose -f docker-compose.yml logs --tail=50
fi

echo "🎉 Despliegue completado exitosamente!"
