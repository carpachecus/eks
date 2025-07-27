#!/usr/bin/env bash
set -euo pipefail

# Ruta base del módulo EKS
cd "$(dirname "$0")/.."

# Parámetros y constantes
RESOURCE="module.eks.aws_iam_openid_connect_provider.oidc_provider[0]"
REGION="${AWS_REGION:-us-east-1}"

echo "🔍 Verificando si OIDC ya está en el estado de Terraform..."

# Verifica si el recurso ya está presente en el estado
if terraform state list | grep -q "$RESOURCE"; then
  echo "✅ El OIDC provider ya está gestionado por Terraform. No es necesario importarlo."
else
  echo "🚀 Importando OIDC provider al estado..."

  # Obtiene el ID de cuenta y el ID del OIDC issuer desde Terraform outputs
  ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
  OIDC_ID=$(terraform output -raw cluster_oidc_issuer_id)

  if [[ -z "$OIDC_ID" ]]; then
    echo "❌ No se pudo obtener el OIDC ID desde los outputs de Terraform. Asegúrate de tener un output 'cluster_oidc_issuer_id'."
    exit 1
  fi

  terraform import "$RESOURCE" \
    "arn:aws:iam::${ACCOUNT_ID}:oidc-provider/oidc.eks.${REGION}.amazonaws.com/id/${OIDC_ID}"
fi
