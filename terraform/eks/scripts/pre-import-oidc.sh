#!/bin/bash
set -euo pipefail

OIDC_PROVIDER_ARN=$(aws eks describe-cluster \
  --name "$CLUSTER_NAME" \
  --region "$AWS_REGION" \
  --query "cluster.identity.oidc.issuer" \
  --output text | sed 's/^https:\/\///')

TF_ADDRESS="module.eks.aws_iam_openid_connect_provider.oidc_provider[0]"

echo "🔍 Verificando si OIDC ya está en el estado de Terraform..."

if terraform state list | grep -q "$TF_ADDRESS"; then
  echo "✅ OIDC ya está gestionado por Terraform. No se necesita importar."
else
  echo "🚀 Importando OIDC al estado..."
  terraform import "$TF_ADDRESS" "arn:aws:iam::$AWS_ACCOUNT_ID:oidc-provider/${OIDC_PROVIDER_ARN}"
fi

