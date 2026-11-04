# ansible_page

Runs the `unedotamps/ansible-page` Astro static site container on the workers.

The image listens on `8080`, which is outside the `8000-8020` range that
`ansible-sg` allows in from the control node, so the host port is remapped to
`8010`. `reverse_proxy_page_port` in the `reverse_proxy` role must match
`ansible_page_host_port`.

Requires the Docker role to have run first. No environment variables.

## Role variables

| Variable | Default | Description |
|---|---|---|
| `ansible_page_image` | `unedotamps/ansible-page:latest` | Container image |
| `ansible_page_name` | `ansible-page` | Container name |
| `ansible_page_container_port` | `8080` | Port the container listens on |
| `ansible_page_host_port` | `8010` | Published host port (must stay in 8000-8020) |
| `ansible_page_restart_policy` | `unless-stopped` | Docker restart policy |

## Example playbook

```yaml
- hosts: workers
  become: true
  roles:
    - ansible_page
```
