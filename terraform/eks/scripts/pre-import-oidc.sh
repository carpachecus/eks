#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

RESOURCE="module.eks.aws_iam_openid_connect_provider.oidc_provider[0]"
REGION="${AWS_REGION:-us-east-1}"

echo "🔍 Verificando si OIDC ya está en el estado de Terraform..."

if terraform state list | grep -q "$RESOURCE"; then
  echo "✅ El OIDC provider YA está gestionado por Terraform. Saltando import..."
  exit 0
fi

echo "🚀 Importando OIDC provider al estado..."

ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
OIDC_URL=$(aws eks describe-cluster --name hello-eks --region "$REGION" --query "cluster.identity.oidc.issuer" --output text)
OIDC_ID=$(echo "$OIDC_URL" | awk -F'/' '{print $NF}')
OIDC_ARN="arn:aws:iam::${ACCOUNT_ID}:oidc-provider/oidc.eks.${REGION}.amazonaws.com/id/${OIDC_ID}"

terraform import "$RESOURCE" "$OIDC_ARN"
