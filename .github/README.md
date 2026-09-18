# GitHub Actions

## API Development Pipeline

Workflow `workflows/api-dev-ci.yaml` berjalan ketika perubahan source API atau
workflow di-push ke branch `master`.

```text
push master
  -> go test
  -> build image
  -> push Docker Hub
  -> update overlay dev
  -> create or update pull request
  -> human merge
  -> Argo CD sync
```

Image dipublikasikan sebagai:

```text
unedotamps/api-app:sha-<full-git-commit-sha>
```

Workflow kemudian memperbarui `newTag` pada:

```text
aws_kube/k8s/apps/overlays/dev/kustomization.yaml
```

Pull Request memakai branch tetap `automation/dev-api-image`. Jika Pull Request
sebelumnya belum di-merge, build terbaru akan memperbarui branch dan Pull Request
yang sama.

## Repository Secrets

Tambahkan secrets berikut melalui repository settings GitHub:

| Secret | Fungsi |
|---|---|
| `DOCKERHUB_USERNAME` | Username Docker Hub, misalnya `unedotamps` |
| `DOCKERHUB_TOKEN` | Docker Hub access token dengan permission push |

Jangan gunakan password account Docker Hub sebagai secret pipeline.
Repository `unedotamps/api-app` harus public agar EKS dapat menarik image tanpa
credential tambahan. Jika repository dibuat private, tambahkan `imagePullSecret`
ke workload Kubernetes.

## GitHub Permissions

Workflow meminta permission berikut:

```yaml
permissions:
  contents: write
  pull-requests: write
```

Pada repository settings, pastikan GitHub Actions memperoleh read/write workflow
permission dan diizinkan membuat Pull Request. Workflow tidak melakukan direct
push ke `master`.

Pull Request yang dibuat memakai `GITHUB_TOKEN`. GitHub mencegah event dari token
tersebut memicu workflow baru secara rekursif. Jika nantinya Pull Request wajib
menjalankan workflow terpisah, gunakan GitHub App token atau token lain dengan
permission minimum yang sesuai.
