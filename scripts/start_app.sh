#!/bin/bash
set -euo pipefail

cd /opt/mi-app

# Construye las imágenes localmente a partir del código fuente desplegado
docker compose -f docker-compose.yml build

# Detiene los contenedores actuales y levanta los nuevos
docker compose -f docker-compose.yml down --remove-orphans
docker compose -f docker-compose.yml up -d

# Limpia imágenes y caché de build antiguos para no llenar el disco
docker image prune -f
docker builder prune -f
