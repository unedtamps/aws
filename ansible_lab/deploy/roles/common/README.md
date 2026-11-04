# common

Baseline host setup: refreshes the apt cache and installs the standard
utility packages (`git`, `curl`).

## Role variables

| Variable | Default | Description |
|---|---|---|
| `common_packages` | `[git, curl]` | Packages to install |

## Example playbook

```yaml
- hosts: all
  become: true
  roles:
    - common
```
