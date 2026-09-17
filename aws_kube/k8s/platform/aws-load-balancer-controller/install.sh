#!/usr/bin/env bash

set -euo pipefail

readonly RELEASE_NAME="${RELEASE_NAME:-aws-load-balancer-controller}"
readonly CHART="${CHART:-eks/aws-load-balancer-controller}"
readonly NAMESPACE="${NAMESPACE:-kube-system}"
readonly CLUSTER_NAME="${CLUSTER_NAME:-lab-eks}"
readonly AWS_REGION="${AWS_REGION:-eu-north-1}"
readonly VPC_ID="${VPC_ID:-vpc-063342a708c4fed04}"

helm repo add eks https://aws.github.io/eks-charts --force-update
helm repo update

helm upgrade --install "${RELEASE_NAME}" \
  "${CHART}" \
  --namespace "${NAMESPACE}" \
  --create-namespace \
  --set "clusterName=${CLUSTER_NAME}" \
  --set "region=${AWS_REGION}" \
  --set "vpcId=${VPC_ID}"
