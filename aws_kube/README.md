# aws_kube

AWS EKS lab: AWS infrastructure, the Kubernetes platform, and the application
workloads that run on top of it.

## Repository layout

| Path | What it is |
|---|---|
| `provision/` | OpenTofu configuration for AWS: VPC, EKS, IAM, NLB, ACM, Cloudflare DNS, and the OpenVPN server. See [provision/README.md](provision/README.md). |
| `k8s/` | Kubernetes layer: platform Helm charts, Argo CD Applications, and application manifests. See [k8s/README.md](k8s/README.md). |
| `k8s/platform/` | Platform releases: `core`, `apps`, `monitoring`, and `headlamp`. |
| `k8s/apps/` | Kustomize manifests and overlays for the application workloads. |
| `apps/` | Application source code; currently the `goapi` Go service, Dockerfile, and SQL migrations. |
| `scripts/` | Helper scripts, including `update-runtime-values.sh` for syncing OpenTofu outputs into Kubernetes YAML. |
| `asset/` | Reserved for static assets; currently empty. |

`apps/` contains source code. `k8s/apps/` contains the Kubernetes deployment
manifests for those applications.

## High-level flow

```text
OpenTofu
  -> AWS VPC, EKS, NLB, ACM, Cloudflare DNS, OpenVPN

Argo CD (inside EKS)
  -> Platform chart: Argo CD, Traefik, External Secrets, EBS CSI,
     AWS Load Balancer Controller, Strimzi
  -> Monitoring: Prometheus, Grafana, Alertmanager
  -> Applications: goapi-dev and ontime-dev

goapi-dev
  -> Go API + PostgreSQL

ontime-dev
  -> ontime-web, api-gateway, identity, attendance, notification
  -> Kafka (Strimzi)
  -> Oracle Free (identity and attendance)
  -> Kafka UI and Maildev
```

The public application traffic path is:

```text
Internet -> NLB :443 -> Traefik -> application services
```

`kubectl` uses the EKS private endpoint, so the OpenVPN connection is required
for cluster access. The application hosts remain reachable through the NLB:
`traefik.lensboxd.site` for goapi and `ontime.lensboxd.site` for ontime.

## Start here

- AWS infrastructure: [provision/README.md](provision/README.md)
- Kubernetes platform and applications: [k8s/README.md](k8s/README.md)
- Editable architecture canvas:
  [k8s/docs/k8s-architecture.tldraw](k8s/docs/k8s-architecture.tldraw)
- Go API source: [apps/goapi](apps/goapi)

Typical access after the VPN is connected:

```bash
# Argo CD
kubectl -n argocd port-forward svc/argocd-server 8080:443

# Grafana
kubectl -n monitoring port-forward svc/monitoring-grafana 3000:80

# Headlamp
kubectl -n headlamp port-forward svc/headlamp 4466:80
```
