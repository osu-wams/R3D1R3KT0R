# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Is

A minimal, hardened web redirect and reverse proxy service built on **Caddy 2**. Listens on HTTP (80) and HTTPS (443), enforces HTTPS via 308 permanent redirect, applies security headers, and emits structured JSON logs. No application code — configuration only.

Most domains are pure redirect rules. Some domains use a hybrid pattern: explicit `redir` rules for specific paths, with all unmatched traffic reverse-proxied to `oregonstate.acquiaedge.net` (Acquia Edge / Cloudflare) with the `Host` header preserved, so the Drupal CDN routes to the correct site and the end user sees the original hostname in their browser. Hybrid domains: `science.oregonstate.edu`, `biochem.oregonstate.edu`, `chemistry.oregonstate.edu`, `ib.oregonstate.edu`, `math.oregonstate.edu`, `microbiology.oregonstate.edu`, `physics.oregonstate.edu`, `stat.oregonstate.edu`.

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

Edit `Caddyfile` (VM) or `Caddyfile.azure` (Azure).

**Single domain, multiple paths** — add `redir` lines inside the server block:

```caddyfile
redir /old-path          https://destination.example.com 301   # permanent
redir /temporary-promo   https://promo.example.com       302   # temporary
redir /gone-forever      https://new-home.example.com    308   # permanent, method-preserving
redir /blog/*            https://blog.example.com{uri}   301   # wildcard: {uri} = path + query
```

**Multiple domains — VM (`Caddyfile`)** — separate site blocks; each gets its own TLS cert. Use the `(shared)` snippet (defined at the top of `Caddyfile`) for headers/logging:

```caddyfile
example.com, www.example.com {
    import shared
    redir /old-path https://destination.example.com 301
}

anotherdomain.com {
    import shared
    redir /old      https://new.anotherdomain.com   301
}
```

**Multiple domains — Azure (`Caddyfile.azure`)** — named host matchers inside the single `:80` block (Azure preserves the `Host` header):

```caddyfile
@example-com host example.com www.example.com
handle @example-com {
    redir /old-path https://destination.example.com 301
}

@anotherdomain host anotherdomain.com
handle @anotherdomain {
    redir /old      https://new.anotherdomain.com   301
}
```

On-prem reload (no restart): `docker compose exec caddy caddy reload --config /etc/caddy/Caddyfile`

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

## Redirect Rule Conventions

Redirect rules in both Caddyfiles are organized into named groups. Each group is bracketed by `START <GROUP NAME>` / `END <GROUP NAME>` comments for navigation. Keep groups alphabetical within each Caddyfile. Use `{uri}` on whole-domain redirects so path and query string are preserved.

## Changelog

### 2026-05-22
- Added **CoS COLLEGE OF SCIENCE WEBSITES** redirect group (13 rules, first in file): mixed set — `environmental/envsci/envscinew.science.oregonstate.edu` combined into one rule targeting fixed URL `graduate.oregonstate.edu/environmental-sciences-graduate-program-esgp`; `naci.science.oregonstate.edu` → `research.oregonstate.edu` (URI preserved); `healthprofessions.science.oregonstate.edu`, `impact.oregonstate.edu`, `proposals.science.oregonstate.edu`, `cosine.oregonstate.edu` are whole-domain fixed-URL redirects; `science.oregonstate.edu` carries 5 path-specific rules (`/bgss`, `/bi311`, `/bpp`, `/ocean.productivity`, `/osumi`). All 301 permanent. Applied to both `Caddyfile` and `Caddyfile.azure`.
- Added **`bb.oregonstate.edu`** to BIOCHEM WEBSITES: whole-domain redirect to `biochem.oregonstate.edu` (URI preserved), 301 permanent. Applied to both `Caddyfile` and `Caddyfile.azure`.
- Added **BIOCHEM WEBSITES** redirect group (6 rules): `*.science.oregonstate.edu` → canonical biochem department destinations, all 301 permanent. Applied to both `Caddyfile` and `Caddyfile.azure`.
- Added **CEOAS WEBSITES** redirect group (6 rules): legacy `geo.*` subdomains and `icecorelab.science.oregonstate.edu` → CEOAS canonical destinations, all 301 permanent. Applied to both `Caddyfile` and `Caddyfile.azure`.
- Added **CHEMISTRY WEBSITES** redirect group (5 rules): legacy chemistry subdomains → canonical destinations, all 301 permanent. Note: `xrd.chem.*` → `xrd.science.*` is intentionally reversed relative to the other rules in this group. Applied to both `Caddyfile` and `Caddyfile.azure`.
- Added **INTEGRATIVE BIOLOGY WEBSITES** redirect group (4 rules): legacy `*.science.oregonstate.edu` subdomains → canonical IB destinations, all 301 permanent. `bi21x.science` and `bi22x.science` are combined into one rule as both target `bi22x.ib`. Applied to both `Caddyfile` and `Caddyfile.azure`.
- Added **MATHEMATICS WEBSITES** redirect group (2 rules): mixed redirect types — `math.oregonstate.edu/BridgeBook` is a path-specific redirect; `calendar.math.oregonstate.edu` is a whole-domain redirect to a fixed URL (path intentionally not forwarded). All 301 permanent. Applied to both `Caddyfile` and `Caddyfile.azure`.
- Updated **MATHEMATICS WEBSITES**: added `redir /BridgeBook/*` wildcard to `math.oregonstate.edu` so subpaths under `/BridgeBook/` are also redirected.
- Added **PHYSICS WEBSITES** redirect group (25 rules): large mixed set — 22 path-specific rules on `physics.oregonstate.edu` (root, named paths, tilde personal pages), plus `www.physics.orst.edu` whole-domain, `calendar.physics.oregonstate.edu` fixed-URL, and `osuper.science.oregonstate.edu` subdomain. `/BridgeBook` carries both exact and wildcard rules. All 301 permanent. Applied to both `Caddyfile` and `Caddyfile.azure`.
- Added **STATISTICS WEBSITES** redirect group (1 rule): `www.stat.orst.edu` → `stat.oregonstate.edu`, 301 permanent, URI preserved. Applied to both `Caddyfile` and `Caddyfile.azure`.
- Added **MYOPINION SURVEYS** sub-group under STATISTICS WEBSITES (6 rules): path-specific redirects on `myopinion.oregonstate.edu` to Qualtrics survey forms; root redirects to Surveys Research Center page. All fixed-URL 301 rules. `/dmv` and `/DMV` are separate rules (Caddy path matching is case-sensitive). Applied to both `Caddyfile` and `Caddyfile.azure`.
- Added **reverse proxy fallback** to `math.oregonstate.edu` and `physics.oregonstate.edu`: all traffic not matched by an explicit `redir` rule is proxied to `https://oregonstate.acquiaedge.net` with `Host` header preserved. End users see the original hostname; Acquia Edge routes to the correct Drupal site. `redir` directives take priority over `reverse_proxy` in Caddy's route ordering.
- Added **reverse proxy fallback** to 6 additional canonical department domains (`biochem.oregonstate.edu`, `chemistry.oregonstate.edu`, `ib.oregonstate.edu`, `microbiology.oregonstate.edu`, `stat.oregonstate.edu`) and to `science.oregonstate.edu` (which already had path redirects). All unmatched traffic proxied to `oregonstate.acquiaedge.net` with `Host` header preserved. `math.oregonstate.edu` and `physics.oregonstate.edu` already had this pattern. Applied to both `Caddyfile` and `Caddyfile.azure`.
- Added **MICROBIOLOGY WEBSITES** redirect group (5 rules): legacy microbiology subdomains → canonical destinations, all 301 permanent. `biohealth.science` and `microbiology.science` combined into one rule as both target `microbiology.oregonstate.edu`. `core-values.microbiology` redirects to a fixed URL path (incoming path not forwarded). Applied to both `Caddyfile` and `Caddyfile.azure`.
