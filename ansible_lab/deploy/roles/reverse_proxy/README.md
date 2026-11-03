# reverse_proxy

Installs NGINX on the control node (`ec2-ans-0`) and turns it into the
reverse proxy for the two lab apps, which run in Docker containers on the
workers.

## What it does

1. Installs NGINX from apt.
2. Removes the distro default site.
3. Renders `templates/config.j2` to
   `/etc/nginx/sites-available/ansiible-lab.conf` and enables it via symlink
   in `sites-enabled/`.
4. Validates with `nginx -t` and reloads NGINX on every config change.

## Routing (multi-domain on port 80 of the control node)

| Vhost (`server_name`)            | Upstream                 | Notes                                        |
|----------------------------------|--------------------------|----------------------------------------------|
| `ansible-app.lensboxd.site`      | `ansible_app` upstream   | Go API (`unedotamps/ansible-app`, port 8000) |
| `ansible-page.lensboxd.site`     | `ansiible_page` upstream | Astro static site (image `unedotamps/ansible-page`, port 8080) |
| anything else (default_server)   | -                        | `return 444` (drop unknown Host headers)     |

DNS: both subdomains need A records pointing at the control node's EIP —
the only node with the `http-sg` security group (80/443 open to the world).

Upstream servers are built from the `workers` inventory group — the proxy
targets every worker's app ports, and `proxy_connect_timeout 2s` makes nginx
fail over to the next worker quickly when one is down.

## Role variables (`defaults/main.yml`)

| Variable                   | Default        | Description |
|----------------------------|----------------|-------------|
| `reverse_proxy_app_port`   | `8000`         | Port the Go API container listens on |
| `reverse_proxy_page_port`  | `8080`         | Port the static page container listens on |
| `reverse_proxy_domain`     | `lensboxd.site`| Domain both vhosts live under |

Both ports must stay inside `8000-8020`, the range `ansible-sg` allows in
from `http-sg` (the control node's traffic).

## Traffic flow

```
internet --> DNS (ansible-app./ansible-page.lensboxd.site -> control EIP)
         :80 -> control (http-sg) -> nginx vhosts
                                     |-> workers :8000 (ansible-app, via ansible-sg 8000-8020)
                                     `-> workers :8080 (ansiible-page, via ansible-sg 8000-8020)
```
