#!/usr/bin/env bash
set -euo pipefail

CLUSTER_NAME="aiops-lab"

usage() {
  cat <<EOF
Usage:
  $0 [--cluster-name <name>]

This creates a local multi-node Kind cluster for the AIOps labs.
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --cluster-name)
      CLUSTER_NAME="${2:-}"
      shift 2
      ;;
    --help|-h)
      usage
      exit 0
      ;;
    *)
      echo "Unknown argument: $1"
      usage
      exit 1
      ;;
  esac
done

require_command() {
  local name="$1"
  if ! command -v "$name" >/dev/null 2>&1; then
    echo "Required command '$name' was not found in PATH."
    exit 1
  fi
}

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
CONFIG_FILE="$REPO_ROOT/kubernetes-ai-log-analysis-rca-slack-bot/kind-config.yaml"

require_command docker
require_command kind
require_command kubectl
require_command helm

if ! docker info >/dev/null 2>&1; then
  echo "Docker is not running or the current user cannot access Docker."
  exit 1
fi

if kind get clusters | grep -qx "$CLUSTER_NAME"; then
  echo "Kind cluster '$CLUSTER_NAME' already exists."
else
  echo "Creating Kind cluster '$CLUSTER_NAME'..."
  kind create cluster --name "$CLUSTER_NAME" --config "$CONFIG_FILE"
fi

kubectl config use-context "kind-$CLUSTER_NAME" >/dev/null

echo "Waiting for all Kubernetes nodes to become Ready..."
kubectl wait --for=condition=Ready nodes --all --timeout=180s

echo "Cluster nodes:"
kubectl get nodes -o wide

echo
echo "Kind cluster '$CLUSTER_NAME' is ready."
echo "Next step: deploy Lab 1 with the Slack webhook."
