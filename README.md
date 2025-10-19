dif y-config image manual

This small helper image pre-seeds configuration files for a CasaOS Dify deployment. It copies bundled configs into a host-mounted `/configs` directory once on first run, then idles. Other containers (nginx, ssrf_proxy, sandbox) mount those configs from the host.

**What it ships**
- `nginx/`
  - `nginx.conf` (client_max_body_size 100M)
  - `conf.d/default.conf` (routes /api, /console/api, /files, /e/, /mcp, / → web)
  - `proxy.conf` (forwarded headers, timeouts)
- `ssrf_proxy/`
  - `squid.conf` (HTTP 3128, reverse proxy to `sandbox:8194`)
  - `conf.d/` (extra includes; empty by default)
- `sandbox/`
  - `conf/config.yaml` (port 8194, proxies via `ssrf_proxy:3128`)
- Entrypoint logic
  - Copies `raw_configs/*` to `/configs` once and creates `/configs/.configed`

**Build and push**
- Build locally (single arch)
  - `cd dify-config`
  - `docker build -t <your-dockerhub-user>/dify-config:latest .`
- Optional: multi-arch (amd64/arm64)
  - `docker buildx create --use`
  - `docker buildx build --platform linux/amd64,linux/arm64 -t <your-dockerhub-user>/dify-config:latest --push .`
- Push to Docker Hub
  - `docker login -u <your-dockerhub-user>`
  - `docker push <your-dockerhub-user>/dify-config:latest`

**Quick local test**
- `mkdir -p /tmp/dify-config-test`
- `docker run --rm -v /tmp/dify-config-test:/configs <your-dockerhub-user>/dify-config:latest`
- Verify copied files
  - `ls -al /tmp/dify-config-test` (should contain `.configed`, `nginx/`, `ssrf_proxy/`, `sandbox/`)

**Use in CasaOS compose**
- Reference the image in your app compose and mount target paths under CasaOS data:

```
services:
  config:
    image: <your-dockerhub-user>/dify-config:latest
    container_name: dify-config
    restart: unless-stopped
    volumes:
      - type: bind
        source: /DATA/AppData/$AppID/data/nginx
        target: /configs/nginx
      - type: bind
        source: /DATA/AppData/$AppID/data/ssrf_proxy
        target: /configs/ssrf_proxy
      - type: bind
        source: /DATA/AppData/$AppID/data/sandbox
        target: /configs/sandbox
```

- Make dependent services wait for config (example in `dify-casaos/docker-compose.yaml`):
  - `nginx`, `ssrf_proxy`, and `sandbox` include `depends_on: - config`.

**Updating configs later**
- The container only copies on first run. To re-copy bundled configs:
  - Remove the flag: delete `/DATA/AppData/$AppID/data/**/.configed` on the host, then recreate the `config` container; or
  - Bump/pull a new image tag and recreate the container after removing the flag; or
  - Manually edit the files on the host paths.

**Customization notes**
- Nginx
  - External exposure is controlled by your reverse proxy container (e.g. mapping `3701:80` in the main stack). Paths are pre-wired to `api:5001`, `web:3000`, and `plugin_daemon:5002` inside the Docker network.
- SSRF proxy (Squid)
  - `ssrf_proxy/squid.conf` uses fixed ports (3128 HTTP, reverse proxy 8194 to `sandbox`). If you change the sandbox port or service name, update this file accordingly.
- Sandbox
  - `sandbox/conf/config.yaml` enables network and points `http/https` proxies at `ssrf_proxy:3128`.

**Troubleshooting**
- Permission denied on `/configs`
  - Ensure the host paths exist and are writable by Docker. The container runs as root for the one-time copy.
- Files not updating after image change
  - Remove the host flag file `/configs/.configed` before recreating the container.
- Docker Hub push denied
  - Login with the correct namespace or retag the image to your account: `docker tag local/dify-config <your-user>/dify-config:latest`.

**Compose helper (optional)**
- You can build with compose inside `dify-config/`:
  - `docker compose build`
  - `docker compose up -d`

This repository’s CasaOS stack example references the image in `dify-casaos/docker-compose.yaml`.
