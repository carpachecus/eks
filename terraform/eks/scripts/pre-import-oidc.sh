#!/bin/bash

set -euo pipefail

# CONFIG
CLUSTER_NAME="hello-eks"
REGION="us-east-1"

# Obtener información de cuenta
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

# Obtener el OIDC URL desde EKS
OIDC_URL=$(aws eks describe-cluster \
  --name "$CLUSTER_NAME" \
  --region "$REGION" \
  --query "cluster.identity.oidc.issuer" \
  --output text)

# Extraer el ID final del OIDC URL
OIDC_ID=$(echo "$OIDC_URL" | awk -F'/' '{print $NF}')

# Construir el ARN
OIDC_ARN="arn:aws:iam::${ACCOUNT_ID}:oidc-provider/oidc.eks.${REGION}.amazonaws.com/id/${OIDC_ID}"

# Nombre del recurso en Terraform
TF_RESOURCE="module.eks.aws_iam_openid_connect_provider.oidc_provider[0]"

echo "🔍 Verificando si OIDC ya está en el estado de Terraform..."
if terraform state list | grep -q "$TF_RESOURCE"; then
  echo "✅ OIDC provider ya existe en Terraform state: $TF_RESOURCE"
else
  echo "🚀 Importando OIDC provider al estado..."
  terraform import "$TF_RESOURCE" "$OIDC_ARN"
  echo "✅ Importación exitosa."
fi
