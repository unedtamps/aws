#!/usr/bin/env bash

set -euo pipefail

readonly RELEASE_NAME="${RELEASE_NAME:-external-secrets}"
readonly CHART="${CHART:-external-secrets/external-secrets}"
readonly NAMESPACE="${NAMESPACE:-external-secrets}"
readonly SERVICE_ACCOUNT="${SERVICE_ACCOUNT:-external-secrets}"
readonly CHART_VERSION="${ESO_CHART_VERSION:-}"

helm repo add external-secrets \
  https://charts.external-secrets.io \
  --force-update

helm repo update

helm_args=(
  upgrade
  --install
  "${RELEASE_NAME}"
  "${CHART}"
  --namespace "${NAMESPACE}"
  --create-namespace
  --wait
  --timeout 5m
  --set installCRDs=true
  --set serviceAccount.create=true
  --set "serviceAccount.name=${SERVICE_ACCOUNT}"
)

if [[ -n "${CHART_VERSION}" ]]; then
  helm_args+=(--version "${CHART_VERSION}")
fi

helm "${helm_args[@]}"

kubectl wait \
  --for=condition=Established \
  crd/externalsecrets.external-secrets.io \
  --timeout=2m

kubectl wait \
  --for=condition=Established \
  crd/secretstores.external-secrets.io \
  --timeout=2m

kubectl rollout status \
  deployment/"${RELEASE_NAME}" \
  --namespace "${NAMESPACE}" \
  --timeout=5m

kubectl get serviceaccount "${SERVICE_ACCOUNT}" \
  --namespace "${NAMESPACE}"

kubectl get pods \
  --namespace "${NAMESPACE}"
