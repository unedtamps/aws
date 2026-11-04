# ansible_app

Runs the `unedotamps/ansible-app` Go API container on the workers.

Requires the Docker role to have run first, and the Postgres DSN in the
`db_string` variable (ansible-vault `inventory/group_vars/workers/vault.yaml`).

## Role variables

| Variable | Default | Description |
|---|---|---|
| `ansible_app_image` | `unedotamps/ansible-app:latest` | Container image |
| `ansible_app_name` | `ansible-app` | Container name |
| `ansible_app_port` | `8000` | Host/container port (inside the 8000-8020 SG range) |
| `ansible_app_restart_policy` | `unless-stopped` | Docker restart policy |
| `ansible_app_db_string` | `{{ db_string }}` | Postgres DSN passed as `DB_STRING`; `db_string` aliases `vault_db_string` |

## Example playbook

```yaml
- hosts: workers
  become: true
  roles:
    - ansible_app
```
