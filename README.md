# Tractor Telemetry — Tekton + Apache Kafka Hands-on Lab

## What you build

A **real Kubernetes Tekton Pipeline** with three sequential tasks:

1. **prepare-topic** — create Kafka topic `tractor.telemetry.raw` with 3 partitions.
2. **produce-telemetry** — Python generates 12 realistic JSON telemetry events for 3 tractors, keyed by tractor ID, and publishes them to Kafka.
3. **consume-and-analyze** — independent Python Kafka consumer reads events from the beginning, validates count, identifies high engine temperature events, and prints summary.

This uses an **actual Apache Kafka broker**, not a mock. Kafka runs as a single-node KRaft broker. This is an educational lab, not a fault-tolerant production Kafka deployment.

## Architecture

```
Mac + Docker Desktop
  -> kind Kubernetes cluster (tractor-tekton)
      -> Tekton PipelineRun
           -> prepare-topic (Kafka CLI) ---> Kafka topic tractor.telemetry.raw
           -> produce-telemetry (Python producer) ---> Kafka topic
           -> consume-and-analyze (Python consumer) <--- Kafka topic
      -> Kafka 3.9.1 broker (KRaft, single node)
```

## Prerequisites

- macOS with Docker Desktop running; recommend >= 6 GB free RAM and ~5 GB disk.
- `docker`, `kind`, `kubectl`, `bash` installed and on PATH.
- Internet connectivity to download container images and Tekton release manifest.
- `kubectl` cluster-admin access to the new local kind cluster.
- No cloud account, registry credentials, GitHub account, or tkn CLI required.

## Run (copy/paste)

From extracted project directory:

```bash
chmod +x scripts/*.sh
./scripts/setup.sh
./scripts/run.sh
```

Setup installs Tekton Pipelines v1.15.0 LTS from official manifest, deploys Apache Kafka and Pipeline. Run creates a fresh PipelineRun and waits up to 10 minutes.

## See results

```bash
kubectl get pipelineruns,taskruns,pods -n tractor-lab
kubectl get pipelineruns -n tractor-lab
kubectl logs -n tractor-lab -l tekton.dev/pipelineRun=$(kubectl get pipelineruns -n tractor-lab -o jsonpath='{.items[-1:].metadata.name}') --all-containers=true --prefix=true --max-log-requests=10
kubectl exec -n tractor-lab deploy/kafka -- /opt/kafka/bin/kafka-topics.sh --bootstrap-server kafka:9092 --describe --topic tractor.telemetry.raw
```

Find individual TaskRun pod logs using `kubectl get pods -n tractor-lab` and `kubectl logs -n tractor-lab POD_NAME -c step-analyze` (or `step-publish`, `step-create-topic`).

## Expected output

```
PRODUCED {"tractor_id": "TRACTOR-001", ...}
CONSUMED {"tractor_id": "TRACTOR-001", ...}
SUMMARY {"total_records": 12, "unique_tractors": 3, "high_temperature_alerts": 4}
SUCCESS: tractor telemetry Kafka integration verified
SUCCESS: PipelineRun completed
```

Alert count depends on generator logic and threshold; the shown example may differ. The total count and number of unique tractors should be 12 and 3 on the first run. On subsequent runs, the consumer intentionally reads from the beginning and will see historical events first; this illustrates Kafka retention but means subsequent runs are **not** scoped to only the latest batch. For a clean demonstration, delete the cluster and set it up again.

## Kafka concepts demonstrated

- Topic: `tractor.telemetry.raw`
- Partitions: 3; keyed events generally keep a given tractor's records together within a partition.
- Producer: Python `KafkaProducer`, emits JSON events.
- Consumer: Python `KafkaConsumer`, explicit partition assignment and offset seek to earliest.
- Offsets: Kafka retains messages; consumer reads from the beginning without committing group offsets.
- Replication factor: 1 for local learning; not production HA.
- Event data: tractor ID, timestamp, speed, engine temperature, fuel percentage, GPS coordinates.

## Troubleshooting

```bash
kubectl get pods -A
kubectl describe pod -n tractor-lab -l app=kafka
kubectl logs -n tractor-lab deployment/kafka --tail=100
kubectl get pipelineruns,taskruns -n tractor-lab
kubectl describe pipelinerun -n tractor-lab PIPELINERUN_NAME
kubectl describe pod -n tractor-lab POD_NAME
```

If the Kafka broker restarts, the lab uses ephemeral storage and existing messages may be lost. If pods are Pending or OOMKilled, increase Docker Desktop memory and retry. Image pulls and pip installs need network access. If the Tekton release URL becomes unavailable, check the official installation page: https://tekton.dev/docs/pipelines/install/ .

## Cleanup

```bash
./scripts/cleanup.sh
```

This removes only the dedicated `tractor-tekton` kind cluster, including its Kafka messages and Tekton resources. It does **not** touch your existing Airflow kind cluster.

## Scope and limitations

This is a CI-style **batch pipeline** demonstrating Kafka provisioning, publishing and consuming. It does not implement a continuously running telemetry ingestion service, Spark, Airflow, Git integration, image build/push, Tekton Triggers, persistent storage, TLS/SASL, or multi-broker Kafka. Those are natural later enhancements.

The archive contains source and scripts; **it has not been executed against a live Docker/Kubernetes cluster in this environment**. The success condition is asserted by the PipelineRun and consumer count, not a claim of prevalidated execution.
