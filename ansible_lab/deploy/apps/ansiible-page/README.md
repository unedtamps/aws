# ansiible-page

Single-page Astro website for the `ansible_lab` deployment, served as static
files by a non-root nginx container. Sits alongside the Go API in
`../ansible-app`.

## Stack

- [Astro](https://astro.build) builds the single page (`src/pages/index.astro`)
  to static HTML in `dist/`.
- `nginxinc/nginx-unprivileged` serves `dist/` on port **8080** (no root
  process) with a `/health` endpoint and long-cache headers for hashed
  `/_astro/` assets.

## Commands

```sh
npm install      # install deps (generates package-lock.json)
npm run dev      # dev server with HMR on http://localhost:4321
npm run build    # static build into dist/
npm run preview  # preview the built site
```

## Docker

```sh
docker build -t ansiible-page .
docker run --rm -p 8080:8080 ansiible-page
# open http://localhost:8080
```

Port 8080 falls inside the `ansible-sg` ingress range (8000-8020), so the
container maps directly on the lab workers without extra security-group
changes.
