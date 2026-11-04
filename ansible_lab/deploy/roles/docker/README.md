# docker

Installs Docker CE on Ubuntu via the official Docker apt repository and
enables the `docker` service.

## Role variables

| Variable | Default | Description |
|---|---|---|
| `docker_user` | `ubuntu` | User added to the `docker` group |

## Example playbook

```yaml
- hosts: workers
  become: true
  roles:
    - docker
```
