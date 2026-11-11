# Kubernetes Platform and Applications

This folder contains the Kubernetes layer for the AWS EKS lab. The cluster is
managed by Argo CD; the shared platform is installed with Helm; and the
application workloads are delivered from Kustomize overlays in this repository.

The documentation is split into three areas:

1. **Platform** — Argo CD, Traefik, AWS Load Balancer Controller, External
   Secrets, EBS CSI, Strimzi, monitoring, and Headlamp.
2. **goapi apps** — the `goapi-dev` application and its PostgreSQL database.
3. **ontime apps** — the `ontime-dev` services, Kafka, Oracle, and test tools.

The editable tldraw canvas with all three architecture diagrams is here:

[Open the editable tldraw canvas](docs/k8s-architecture.tldraw)

> `kubectl` requires the OpenVPN connection because the EKS public API endpoint
> is disabled. The application hosts are still reachable through the
> internet-facing NLB.

---

## Platform

[![Platform architecture](docs/platform.jpg)](docs/platform.jpg)

The platform is split across four Helm releases:

| Release | Namespace | Chart | Purpose |
|---|---|---|---|
| `platform` | `kube-system` | `platform/core` | Shared cluster services: Argo CD, Traefik, AWS Load Balancer Controller, External Secrets, EBS CSI, and Strimzi. |
| `platform-apps` | `argocd` | `platform/apps` | Argo CD `Application` objects for `goapi-dev` and `ontime-dev`, plus the Traefik `TargetGroupBinding`. |
| `monitoring` | `monitoring` | `platform/monitoring` | `kube-prometheus-stack`: Prometheus, Grafana, Alertmanager, node-exporter, and kube-state-metrics. |
| `headlamp` | `headlamp` | `platform/headlamp` | Cluster UI for browsing workloads and resources. |

### Platform components

| Component | Namespace | Simple explanation |
|---|---|---|
| **Argo CD** | `argocd` | GitOps controller. It watches the GitHub `HEAD` revision and keeps `goapi-dev` and `ontime-dev` in sync with the overlays in this repository. Auto-sync, self-heal, and prune are enabled. |
| **Traefik** | `traefik` | Ingress controller with 5 replicas. The Service is `ClusterIP:80`; the NLB forwards TLS :443 to it. It routes by `Host` using `IngressRoute` resources. |
| **AWS Load Balancer Controller** | `kube-system` | Registers Traefik Pod IPs into the NLB target group through the `TargetGroupBinding` in `platform-apps`. It does not create a second load balancer. |
| **External Secrets** | `external-secrets` | Reads `lab-eks/external-secrets/app-2` from AWS Secrets Manager and creates Kubernetes Secrets for the applications. Uses a `SecretStore` backed by EKS Pod Identity. |
| **EBS CSI driver** | `kube-system` | Provides the `gp3` StorageClass used by Kafka, Oracle, PostgreSQL, Prometheus, and attendance uploads. The class uses `WaitForFirstConsumer` and allows volume expansion. |
| **Strimzi** | `kube-system` (operator) | Kafka operator. It watches `ontime-dev` and `ontime-prod` and reconciles the `Kafka`/`KafkaNodePool` resources in the `ontime` stack. |
| **kube-prometheus-stack** | `monitoring` | Prometheus (24h retention, 20Gi PVC), Grafana, Alertmanager, node-exporter, and kube-state-metrics. Alertmanager sends mail to Maildev SMTP in `ontime-dev`. |
| **Headlamp** | `headlamp` | Web UI for the cluster. It runs with a `cluster-admin` service account and is accessed by `kubectl port-forward`, not exposed by the NLB. |
| **TargetGroupBinding** | `traefik` | Maps the `traefik` Service to the Terraform-managed NLB target group. This is the bridge between the AWS NLB and the in-cluster Traefik pods. |

The platform chart creates the base namespaces (`traefik`, `argocd`,
`external-secrets`, and `ontime-dev`). Argo CD creates `goapi-dev` through
`CreateNamespace=true`.

### Platform access

```bash
# Argo CD UI
kubectl -n argocd port-forward svc/argocd-server 8080:443

# Grafana
kubectl -n monitoring port-forward svc/monitoring-grafana 3000:80

# Headlamp
kubectl -n headlamp port-forward svc/headlamp 4466:80
```

Grafana uses the `grafana-admin` Secret. Argo CD uses its standard
`argocd-initial-admin-secret` on a fresh install.

---

## goapi Apps

[![goapi architecture](docs/goapi.jpg)](docs/goapi.jpg)

Argo CD Application: `goapi-dev`

| Item | Value |
|---|---|
| Source path | `aws_kube/k8s/apps/goapi/overlays/dev` |
| Namespace | `goapi-dev` |
| Sync policy | Automated, self-heal, prune |
| Image | `unedotamps/goapi-app`, pinned in the overlay |

### Components

| Component | Kind | Simple explanation |
|---|---|---|
| `goapi-app` | Deployment | The Go API. It runs 3 replicas in `goapi-dev`, listens on `:8080`, and exposes `/healthz` and `/readyz` probes. |
| `goapi-service` | Service | Stable ClusterIP on port `80`, forwarding to the `goapi-app` pods on `:8080`. |
| `postgres` | StatefulSet | PostgreSQL 16 (`postgres:16-alpine`) with one replica and a 10Gi `gp3` PVC. It is the `goapi` database. |
| `postgres` / `postgres-headless` | Services | ClusterIP and headless Services on port `5432` for the database. |
| `goapi-app-credentials` | ExternalSecret | Reads the application username from AWS Secrets Manager. |
| `postgres-credentials` | ExternalSecret | Reads database username, password, and database name from AWS Secrets Manager. |
| `route-ingress` | IngressRoute | Routes `traefik.lensboxd.site` to `goapi-service:80`. |

### Request flow

```text
Internet
  -> NLB :443
  -> Traefik (Host: traefik.lensboxd.site)
  -> goapi-service :80
  -> goapi-app :8080 (3 replicas)
  -> postgres :5432
      -> PVC 10Gi gp3
```

External Secrets supplies both the application credential and the PostgreSQL
credential from `lab-eks/external-secrets/app-2`.

To change the deployed image, update `images.newTag` in
`aws_kube/k8s/apps/goapi/overlays/dev/kustomization.yaml`, commit, and let Argo
CD sync.

### goapi access

```bash
kubectl -n goapi-dev port-forward svc/goapi-service 8080:80
```

The public host is `https://traefik.lensboxd.site` through the NLB and Traefik.

---

## ontime Apps

[![ontime architecture](docs/ontime.jpg)](docs/ontime.jpg)

Argo CD Application: `ontime-dev`

| Item | Value |
|---|---|
| Source path | `aws_kube/k8s/apps/ontime/overlays/dev` |
| Namespace | `ontime-dev` |
| Sync policy | Automated, self-heal, prune |
| Images | `ontime-web`, `ontime-api-gateway`, `ontime-identity`, `ontime-attendence`, `ontime-notification`, pinned in the overlay |

### Components

| Component | Kind | Simple explanation |
|---|---|---|
| `ontime-web` | Deployment | Frontend on `:3000`. `IngressRoute/ontime-web-ingress` publishes it at `ontime.lensboxd.site`. |
| `api-gateway` | Deployment | Internal API gateway on `:3001`. Calls `identity-service` and `attendence-service`. |
| `identity-service` | Deployment | Identity and user service on `:3002`. Uses Oracle `db-identity` and publishes identity events to Kafka. |
| `attendence-service` | Deployment | Attendance service on `:3003`. Uses Oracle `db-attendence`, publishes attendance events, and stores uploaded files in a 5Gi PVC. It stays at one replica because the volume is `ReadWriteOnce`. |
| `notification-service` | Deployment | Kafka consumer on `:3004`. Sends email through Maildev SMTP on `:1025` and calls `identity-service` when needed. |
| `ontime` | Kafka (Strimzi) | Three KRaft brokers with 10Gi `gp3` volumes each. Topics `identity.events` and `attendence.events` use 4 partitions, replication factor 3, and `min.insync.replicas=2`. |
| `broker` | KafkaNodePool | The Strimzi node pool managed by the `ontime` Kafka resource: controller and broker roles, 3 replicas. The pods are named `ontime-broker-*`. |
| `db-identity` | StatefulSet | Oracle Free (`gvenzl/oracle-free:23-slim`) with a 20Gi `gp3` PVC. PDB `FREEPDB1` stores identity data. |
| `db-attendence` | StatefulSet | Oracle Free with a 20Gi `gp3` PVC. PDB `FREEPDB1` stores attendance data. The dev overlay adds restart hardening (`/dev/shm` cleanup, diagnostic log volume, and a longer liveness window). |
| `attendence-uploads` | PVC | 5Gi `gp3` shared by `attendence-service` for local upload files. Replace this with object storage before scaling attendance horizontally. |
| `kafka-ui` | Deployment | Kafka UI on `:8080`, exposed only through `kubectl port-forward`. Useful for topics, consumer groups, and messages. |
| `maildev` | Deployment | Development SMTP (`:1025`) and web inbox (`:1080`). Used by `notification-service` and Alertmanager. |
| Oracle credential secrets | ExternalSecret | Supplies the Oracle application and admin credentials from AWS Secrets Manager. |
| `ontime-web-ingress` | IngressRoute | Routes `ontime.lensboxd.site` to `ontime-web:80`. |

### Request and event flow

```text
Internet
  -> NLB :443
  -> Traefik (Host: ontime.lensboxd.site)
  -> ontime-web :3000
  -> api-gateway :3001
  -> identity-service :3002  -> Oracle db-identity / FREEPDB1
  -> attendence-service :3003 -> Oracle db-attendence / FREEPDB1
                              -> PVC 5Gi (uploads)
                              -> Kafka (attendance events)

Kafka
  -> notification-service :3004 -> Maildev SMTP :1025

Kafka UI -> Kafka (port-forward only)
```

Storage summary:

| Workload | PVC |
|---|---|
| Kafka brokers | 3 × 10Gi `gp3` |
| Oracle identity | 20Gi `gp3` |
| Oracle attendance | 20Gi `gp3` |
| Attendance uploads | 5Gi `gp3` |

### ontime access

```bash
# Kafka UI
kubectl -n ontime-dev port-forward svc/kafka-ui 8080:80

# Maildev web inbox
kubectl -n ontime-dev port-forward svc/maildev 1080:1080

# Oracle databases
kubectl -n ontime-dev port-forward svc/db-identity 1521:1521
kubectl -n ontime-dev port-forward svc/db-attendence 1521:1521
```

The Oracle services use `FREEPDB1` as the service name. The application
credentials are created by External Secrets.

---

## GitOps Workflow

`platform/apps` creates the Argo CD Applications. Both applications use:

- `repoURL: https://github.com/unedtamps/aws.git`
- `targetRevision: HEAD`
- `path: aws_kube/k8s/apps/<app>/overlays/dev`
- automated sync with self-heal and prune
- retry with exponential backoff

Typical workflow:

```bash
# Check application health
kubectl -n argocd get applications

# Change an image tag in the overlay
# aws_kube/k8s/apps/<app>/overlays/dev/kustomization.yaml

git add aws_kube/k8s/apps/<app>/overlays/dev/kustomization.yaml
git commit -m "deploy: update <app> image"
git push

# Argo CD reconciles the new revision
```

Database and Kafka volumes are retained with `gp3` PVCs. Deleting a pod does
not delete its PVC or data.
