#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
kubectl config use-context kind-tractor-tekton >/dev/null
kubectl apply -n tractor-lab -f k8s/pipeline.yaml
NAME="tractor-run-$(date +%s)"
cat <<YAML | kubectl create -n tractor-lab -f -
apiVersion: tekton.dev/v1
kind: PipelineRun
metadata:
  name: $NAME
spec:
  pipelineRef:
    name: tractor-telemetry
  params:
    - name: records
      value: '12'
YAML
echo "PipelineRun: $NAME"
echo "Watch: kubectl get pipelineruns -n tractor-lab -w"
echo "Logs: kubectl logs -n tractor-lab -l tekton.dev/pipelineRun=$NAME --all-containers=true --prefix=true --max-log-requests=10"
for i in $(seq 1 120); do
  CONDITION=$(kubectl get pipelinerun "$NAME" -n tractor-lab -o jsonpath='{.status.conditions[?(@.type=="Succeeded")].status}' 2>/dev/null || true)
  if [[ "$CONDITION" == True ]]; then echo 'SUCCESS: PipelineRun completed'; exit 0; fi
  if [[ "$CONDITION" == False ]]; then echo "FAILED: $NAME"; kubectl describe pipelinerun "$NAME" -n tractor-lab; exit 1; fi
  sleep 5
done
echo "Timed out waiting for $NAME"; exit 1
