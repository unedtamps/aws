#!/usr/bin/env bash
#
# generate_inventory.sh
#
# Generate an Ansible YAML inventory (deploy/inventory/hosts.yaml) from the
# OpenTofu output of the provision/ stack.
#
# Mapping:
#   ec2-ans-0  -> control group
#   everyone else (ec2-ans-1, ec2-ans-2, ...) -> workers group
#
# Usage:
#   ./deploy/scripts/generate_inventory.sh
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/../.." && pwd)"
PROVISION_DIR="${ROOT_DIR}/provision"
INVENTORY_FILE="${ROOT_DIR}/deploy/inventory/hosts.yaml"
CONTROL_HOST="ec2-ans-0"

if ! command -v tofu >/dev/null 2>&1; then
  echo "error: tofu not found in PATH" >&2
  exit 1
fi
if ! command -v python3 >/dev/null 2>&1; then
  echo "error: python3 not found in PATH" >&2
  exit 1
fi

echo "Reading 'ips' output from ${PROVISION_DIR} ..."
IPS_JSON="$(tofu -chdir="${PROVISION_DIR}" output -json ips)"

TMP_FILE="$(mktemp)"
trap 'rm -f "${TMP_FILE}"' EXIT

CONTROL_HOST="${CONTROL_HOST}" IPS_JSON="${IPS_JSON}" python3 - > "${TMP_FILE}" <<'PY'
import json
import os
import sys

control = os.environ["CONTROL_HOST"]
ips = json.loads(os.environ["IPS_JSON"])

if not isinstance(ips, dict) or not ips:
    sys.exit("error: tofu output 'ips' is empty or not an object")

if control not in ips:
    sys.exit(f"error: control host '{control}' not found in tofu output keys: {sorted(ips)}")

workers = sorted(name for name in ips if name != control)

lines = ["all:", "  children:", "    control:", "      hosts:"]
lines.append(f"        {control}:")
lines.append(f"          ansible_host: {ips[control]}")
lines.append("    workers:")
lines.append("      hosts:")
for name in workers:
    lines.append(f"        {name}:")
    lines.append(f"          ansible_host: {ips[name]}")

print("\n".join(lines))
PY

mv "${TMP_FILE}" "${INVENTORY_FILE}"
trap - EXIT

echo "Wrote ${INVENTORY_FILE}:"
cat "${INVENTORY_FILE}"
