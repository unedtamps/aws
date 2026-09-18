#!/usr/bin/env bash

set -euo pipefail

readonly RELEASE_NAME="${RELEASE_NAME:-traefik-crds}"
readonly NAMESPACE="${NAMESPACE:-traefik}"
readonly TRAEFIK_CHART="traefik-crds"
readonly TRAEFIK_CHART_REPOSITORY="https://traefik.github.io/charts"
readonly TRAEFIK_CHART_VERSION="${TRAEFIK_CHART_VERSION:-1.18.0}"
readonly TAKE_OWNERSHIP="${TAKE_OWNERSHIP:-false}"

for required_command in helm kubectl; do
  if ! command -v "${required_command}" >/dev/null 2>&1; then
    printf 'Required command not found: %s\n' "${required_command}" >&2
    exit 1
  fi
done

if kubectl get crd ingressroutes.traefik.io >/dev/null 2>&1 &&
  [[ "${TAKE_OWNERSHIP}" != "true" ]]; then
  printf '%s\n' \
    'Traefik CRDs already exist and may be owned by another Helm release.' \
    'Inspect the current CRDs, then rerun with TAKE_OWNERSHIP=true to adopt them.' >&2
  exit 1
fi

helm_args=(
  upgrade
  --install
  "${RELEASE_NAME}"
  "${TRAEFIK_CHART}"
  --repo "${TRAEFIK_CHART_REPOSITORY}"
  --version "${TRAEFIK_CHART_VERSION}"
  --namespace "${NAMESPACE}"
  --create-namespace
  --set traefik=true
  --set gatewayAPI=false
  --set gatewayAPIExperimental=false
  --set knative=false
  --set hub=false
  --set deleteOnUninstall=false
  --wait
)

if [[ "${TAKE_OWNERSHIP}" == "true" ]]; then
  helm_args+=(--take-ownership)
fi

helm "${helm_args[@]}"

kubectl wait \
  --for=condition=Established \
  --timeout=60s \
  crd/ingressroutes.traefik.io
