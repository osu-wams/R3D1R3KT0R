# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Is

A minimal, hardened web redirect service built on **Caddy 2**. Listens on HTTP (80) and HTTPS (443), enforces HTTPS via 308 permanent redirect, applies security headers, and emits structured JSON logs. No application code — configuration only.

## Commands

```bash
# Start (on-prem / VM)
docker compose up -d

# Start (Azure Container Apps mode — HTTP-only, Azure manages TLS)
docker compose -f docker-compose.yml -f docker-compose.azure.yml up -d

# Reload redirect rules without restarting the container
docker compose exec caddy caddy reload --config /etc/caddy/Caddyfile

# View structured JSON logs
docker compose logs -f caddy

# Validate Caddyfile syntax before applying
docker compose exec caddy caddy validate --config /etc/caddy/Caddyfile

# Stop
docker compose down
```

## Adding Redirect Rules

Edit `Caddyfile` (VM) or `Caddyfile.azure` (Azure), adding lines inside the server block:

```caddyfile
redir /old-path          https://destination.example.com 301   # permanent
redir /temporary-promo   https://promo.example.com       302   # temporary
redir /gone-forever      https://new-home.example.com    308   # permanent, method-preserving
```

Then reload: `docker compose exec caddy caddy reload --config /etc/caddy/Caddyfile`

## Architecture

```
Internet → :80  → 308 HTTPS redirect (Caddy automatic)
Internet → :443 → TLS termination (Let's Encrypt, auto-renewed) → redirect rules
```

Two Caddyfiles, same image:
- `Caddyfile` — VM/on-prem: Caddy owns TLS via Let's Encrypt
- `Caddyfile.azure` — Azure Container Apps: `auto_https off`, Azure ingress owns TLS

`docker-compose.azure.yml` is a **compose override** — always layer it on top of `docker-compose.yml`, never use it standalone.

## Security Decisions

- `admin off` in both Caddyfiles — disables Caddy's JSON API, no remote reconfiguration surface
- Container runs read-only filesystem; `/tmp` is a tmpfs mount
- All Linux capabilities dropped except `NET_BIND_SERVICE` (needed for ports <1024)
- Caddyfile mounted read-only (`:ro`)
- `Server` response header stripped to prevent version fingerprinting
- HSTS with `preload` and `includeSubDomains` — commit your domain to HTTPS-only before enabling

## Setup

```bash
cp .env.example .env
# Set ACME_EMAIL to a real address — Let's Encrypt sends cert expiry alerts here
```

DNS for your domain(s) must point to the host before starting. Caddy will fail ACME challenge if DNS isn't resolving.

## Azure Deployment (IaC + CI/CD)

Infrastructure is defined in `infra/main.bicep` (subscription-scoped). It creates the resource group, Log Analytics workspace, Azure Container Registry, a user-assigned managed identity with AcrPull, the Container Apps environment, and the Container App itself.

`Caddyfile.azure` is **baked into the Docker image** at build time via `Dockerfile` — no Azure File Share volume needed.

```bash
# One-time bootstrap (subscription Owner required)
az deployment sub create \
  --name r3d1r3kt0r-init \
  --location eastus \
  --template-file infra/main.bicep \
  --parameters infra/main.bicepparam
```

**CI/CD:** Pushing to the `dom` branch triggers `.github/workflows/deploy.yml`, which:
1. Runs Bicep (idempotent — handles infra drift)
2. Builds and pushes the image to ACR tagged with the git SHA
3. Calls `az containerapp update --image` to deploy the new revision

**Rollback:**
```bash
az containerapp update \
  --name r3d1r3kt0r \
  --resource-group rg-r3d1r3kt0r \
  --image <acr-login-server>/r3d1r3kt0r:<old-sha>
```

**OIDC prerequisite:** Before the first push, create an Azure App Registration with a federated credential scoped to `repo:YOUR_ORG/R3D1R3KT0R:ref:refs/heads/dom` and set `AZURE_CLIENT_ID`, `AZURE_TENANT_ID`, `AZURE_SUBSCRIPTION_ID` as GitHub repository secrets.

- No persistent volume needed (no Let's Encrypt certs in Azure mode)
- `ACME_EMAIL` env var is unused in Azure mode but harmless to set
