#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
command -v kubectl >/dev/null || { echo 'kubectl required'; exit 1; }
command -v kind >/dev/null || { echo 'kind required'; exit 1; }
command -v docker >/dev/null || { echo 'Docker required'; exit 1; }
docker info >/dev/null || { echo 'Start Docker Desktop first'; exit 1; }
if ! kind get clusters | grep -qx tractor-tekton; then
  kind create cluster --name tractor-tekton --wait 120s
fi
kubectl config use-context kind-tractor-tekton
kubectl apply -f https://infra.tekton.dev/tekton-releases/pipeline/previous/v1.15.0/release.yaml
kubectl rollout status deployment/tekton-pipelines-controller -n tekton-pipelines --timeout=300s
kubectl rollout status deployment/tekton-pipelines-webhook -n tekton-pipelines --timeout=300s
kubectl create namespace tractor-lab --dry-run=client -o yaml | kubectl apply -f -
kubectl apply -n tractor-lab -f k8s/kafka.yaml
kubectl rollout status deployment/kafka -n tractor-lab --timeout=300s
kubectl apply -n tractor-lab -f k8s/pipeline.yaml
echo 'Setup complete. Run: ./scripts/run.sh'
