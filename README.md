# R3D1R3KT0R

A minimal, hardened web redirect and reverse proxy service built on [Caddy 2](https://caddyserver.com). Configuration only — no application code.

- HTTP → HTTPS enforcement via 308 permanent redirect
- Security headers (HSTS, X-Frame-Options, X-Content-Type-Options, Referrer-Policy)
- Structured JSON logging to stdout
- Caddy admin API disabled
- Read-only container filesystem, all Linux capabilities dropped except `NET_BIND_SERVICE`

---

## Active Redirect Groups

Redirect rules are organized into named groups in both Caddyfiles. Each group is bracketed by `START <GROUP>` / `END <GROUP>` comments for easy navigation as the files grow.

| Group | Count | Source pattern | Added |
|---|---|---|---|
| BIOCHEM WEBSITES | 6 | `*.science.oregonstate.edu` | 2026-05-22 |
| CEOAS WEBSITES | 6 | `geo.*`, `icecorelab.science.oregonstate.edu` | 2026-05-22 |
| CHEMISTRY WEBSITES | 5 | `*.chem.oregonstate.edu`, `*.science.oregonstate.edu` | 2026-05-22 |
| INTEGRATIVE BIOLOGY WEBSITES | 4 | `*.science.oregonstate.edu` | 2026-05-22 |
| MATHEMATICS WEBSITES | 2 | `math.oregonstate.edu`, `calendar.math.oregonstate.edu` | 2026-05-22 |
| MICROBIOLOGY WEBSITES | 5 | `*.science.oregonstate.edu`, `*.microbiology.oregonstate.edu` | 2026-05-22 |
| PHYSICS WEBSITES | 25 | `physics.oregonstate.edu` paths, `www.physics.orst.edu`, `calendar.*`, `osuper.*` | 2026-05-22 |
| STATISTICS WEBSITES | 1 | `www.stat.orst.edu` | 2026-05-22 |
| ↳ MYOPINION SURVEYS | 6 | `myopinion.oregonstate.edu` | 2026-05-22 |

### BIOCHEM WEBSITES

Redirects legacy `*.science.oregonstate.edu` subdomains to their canonical biochemistry department destinations. All rules are 301 permanent.

| Source | Target |
|---|---|
| `barbar.science.oregonstate.edu` | `barbar.biochem.oregonstate.edu` |
| `biochem.science.oregonstate.edu` | `biochem.oregonstate.edu` |
| `ccf.science.oregonstate.edu` | `gce4all.oregonstate.edu` |
| `gombart.science.oregonstate.edu` | `gombart.biochem.oregonstate.edu` |
| `mehl.science.oregonstate.edu` | `mehl.biochem.oregonstate.edu` |
| `upf.science.oregonstate.edu` | `upf.biochem.oregonstate.edu` |

### CEOAS WEBSITES

Redirects legacy `geo.*` subdomains (across `oregonstate.edu` and `orst.edu`) and `icecorelab.science.oregonstate.edu` to College of Earth, Ocean, and Atmospheric Sciences (CEOAS) canonical destinations. `www` and apex variants that share a target are combined into a single rule. All rules are 301 permanent.

| Source | Target |
|---|---|
| `geo.oregonstate.edu` | `ceoas.oregonstate.edu` |
| `www.geo.oregonstate.edu` | `ceoas.oregonstate.edu` |
| `geo.science.oregonstate.edu` | `ceoas.oregonstate.edu` |
| `geo.orst.edu` | `ceoas.oregonstate.edu` |
| `www.geo.orst.edu` | `ceoas.oregonstate.edu` |
| `icecorelab.science.oregonstate.edu` | `icecore.ceoas.oregonstate.edu` |

### CHEMISTRY WEBSITES

Redirects legacy chemistry-related subdomains to canonical destinations. All rules are 301 permanent. Note: `xrd.chem.oregonstate.edu` → `xrd.science.oregonstate.edu` is intentionally reversed relative to the other rules in this group.

| Source | Target |
|---|---|
| `chemsafety.chem.oregonstate.edu` | `chemistry.oregonstate.edu` |
| `mass-spec.science.oregonstate.edu` | `mass-spec.chem.oregonstate.edu` |
| `remcho.science.oregonstate.edu` | `remcho.chem.oregonstate.edu` |
| `subramanian.science.oregonstate.edu` | `subramanian.chem.oregonstate.edu` |
| `xrd.chem.oregonstate.edu` | `xrd.science.oregonstate.edu` |

### INTEGRATIVE BIOLOGY WEBSITES

Redirects legacy `*.science.oregonstate.edu` subdomains to canonical Integrative Biology (IB) destinations. All rules are 301 permanent. `bi21x.science` and `bi22x.science` share a target and are combined into a single rule.

| Source | Target |
|---|---|
| `bi21x.science.oregonstate.edu` | `bi22x.ib.oregonstate.edu` |
| `bi22x.science.oregonstate.edu` | `bi22x.ib.oregonstate.edu` |
| `lytlelab.science.oregonstate.edu` | `lytlelab.ib.oregonstate.edu` |
| `masonlab.science.oregonstate.edu` | `masonlab.ib.oregonstate.edu` |

### MATHEMATICS WEBSITES

Mixed redirect types — all rules are 301 permanent.

| Source | Target | Notes |
|---|---|---|
| `math.oregonstate.edu/BridgeBook` | `sites.science.oregonstate.edu/math/BridgeBook` | Exact path match |
| `math.oregonstate.edu/BridgeBook/*` | `sites.science.oregonstate.edu/math{uri}` | Wildcard — preserves subpaths |
| `calendar.math.oregonstate.edu` | `internal.math.oregonstate.edu/room-reservations` | Whole-domain to fixed URL; incoming path not forwarded |

### MICROBIOLOGY WEBSITES

Redirects legacy microbiology-related subdomains to canonical destinations. All rules are 301 permanent. `biohealth.science` and `microbiology.science` share a target and are combined into a single rule. `core-values.microbiology` redirects to a fixed URL path — incoming path is not forwarded.

| Source | Target | Notes |
|---|---|---|
| `biohealth.science.oregonstate.edu` | `microbiology.oregonstate.edu` | Combined with microbiology.science |
| `microbiology.science.oregonstate.edu` | `microbiology.oregonstate.edu` | Combined with biohealth.science |
| `core-values.microbiology.oregonstate.edu` | `microbiology.oregonstate.edu/our-department/diversity-and-inclusion/core-values` | Fixed URL; incoming path not forwarded |
| `davidlab.science.oregonstate.edu` | `davidlab.microbiology.oregonstate.edu` | |
| `ephys.science.oregonstate.edu` | `ephys.microbiology.oregonstate.edu` | |

### PHYSICS WEBSITES

Large mixed set on `physics.oregonstate.edu` (path-specific rules) plus subdomain and legacy-domain rules. All rules are 301 permanent.

**`physics.oregonstate.edu` path rules**

| Source path | Target | Notes |
|---|---|---|
| `/BridgeBook` | `sites.science.oregonstate.edu/math/BridgeBook` | Exact match |
| `/BridgeBook/*` | `sites.science.oregonstate.edu/math{uri}` | Wildcard — preserves subpaths |
| `/` | `sites.science.oregonstate.edu/physics/meetings` | Root only — not a catch-all |
| `/energetics` | `sites.science.oregonstate.edu/physics/energetics` | |
| `/forum` | `sites.science.oregonstate.edu/forum` | |
| `/gradreview` | `sites.science.oregonstate.edu/physics/gradreview` | |
| `/mentorwiki` | `sites.science.oregonstate.edu/physics/mentorwiki` | |
| `/portfolioswiki` | `sites.science.oregonstate.edu/physics/portfolioswiki` | |
| `/qmaactivities` | `sites.science.oregonstate.edu/physics/coursewikis/portfolioswiki/topic_qmtext.html` | Fixed URL |
| `/wngrspace` | `sites.science.oregonstate.edu/physics/wngrspace` | |
| `/~grahamat/COURSES/ph411` | `sites.science.oregonstate.edu/~grahamat/COURSES/ph411` | More specific than `/~grahamat` — listed first |
| `/~craigda` | `sites.science.oregonstate.edu/~craigda` | |
| `/~grahamat` | `physics.oregonstate.edu/directory/matt-w-graham` | Same-domain redirect |
| `/~lazzatid` | `sites.science.oregonstate.edu/~lazzatid` | |
| `/~leeys` | `sites.science.oregonstate.edu/~leeys` | |
| `/~mcintyre` | `sites.science.oregonstate.edu/~mcintyre` | |
| `/~minote` | `minotlab.physics.oregonstate.edu` | Path→subdomain; path not forwarded |
| `/~ostroveo` | `sites.science.oregonstate.edu/~ostroveo` | |
| `/~schellmh` | `sites.science.oregonstate.edu/~schellmh` | |
| `/~sunb` | `sites.science.oregonstate.edu/~sunb` | |
| `/~tatej` | `sites.science.oregonstate.edu/~tatej` | |
| `/~tevian` | `sites.science.oregonstate.edu/~tevian/physics` | Appends `/physics` suffix; path not forwarded |
| `/~walshke` | `boxsand.physics.oregonstate.edu` | Path→subdomain; path not forwarded |

**Other domain rules**

| Source | Target | Notes |
|---|---|---|
| `www.physics.orst.edu` | `physics.oregonstate.edu` | Whole-domain; URI preserved |
| `calendar.physics.oregonstate.edu` | `physics.oregonstate.edu/our-department/internal-resources/room-reservations` | Fixed URL; incoming path not forwarded |
| `osuper.science.oregonstate.edu` | `osuper.physics.oregonstate.edu` | Whole-domain; URI preserved |

### STATISTICS WEBSITES

| Source | Target |
|---|---|
| `www.stat.orst.edu` | `stat.oregonstate.edu` |

#### MYOPINION SURVEYS

Path-specific redirects on `myopinion.oregonstate.edu` to Qualtrics survey forms. All fixed-URL 301 rules — incoming paths are not forwarded. `/dmv` and `/DMV` are listed as separate rules because Caddy path matching is case-sensitive.

| Source | Target |
|---|---|
| `myopinion.oregonstate.edu` (root) | `stat.oregonstate.edu/services/surveys-research-center` |
| `myopinion.oregonstate.edu/air` | `oregonstate.qualtrics.com/jfe/form/SV_4U4U0yNKbbb6cdM` |
| `myopinion.oregonstate.edu/dmv` | `oregonstate.qualtrics.com/jfe/form/SV_eDLNjMhZv6ypF8F` |
| `myopinion.oregonstate.edu/DMV` | `oregonstate.qualtrics.com/jfe/form/SV_eDLNjMhZv6ypF8F` |
| `myopinion.oregonstate.edu/highways` | `oregonstate.qualtrics.com/jfe/form/SV_cV1pv3aJekkNdgp` |
| `myopinion.oregonstate.edu/roads` | `oregonstate.qualtrics.com/jfe/form/SV_3Jo5ThHFp5J222O` |

---

### Notes and Caveats — Reverse Proxy Domains

Some domains in this service use a **hybrid redirect + reverse proxy** pattern rather than pure redirects. Currently: `math.oregonstate.edu` and `physics.oregonstate.edu`.

#### How Caddy route ordering works

Caddy assigns each directive an implicit priority. `redir` has priority 2; `reverse_proxy` has priority 28. Caddy compiles the site block into an ordered route list at startup — explicit `redir` rules always win, and anything that falls through is handled by the `reverse_proxy` catch-all. No manual ordering or path exclusions are needed.

#### What `header_up Host {host}` does

By default, Caddy rewrites the `Host` header to the upstream address (`oregonstate.acquiaedge.net`) before forwarding the request. Without the override, Acquia Edge / Cloudflare would not know which Drupal site to serve. `header_up Host {host}` preserves the original hostname (e.g. `physics.oregonstate.edu`) end-to-end so the CDN routes to the correct origin. The end user's browser always sees the original hostname — this is a transparent proxy, not a redirect.

#### Acquia Edge hostname registration

Acquia Edge may require `math.oregonstate.edu` and `physics.oregonstate.edu` to be registered as allowed inbound hostnames on their platform. If the CDN rejects requests where the `Host` header doesn't match a known domain, proxied traffic will fail with a 421 or similar upstream error. Confirm with your Acquia team that both domains are whitelisted before cutting DNS over to this service.

---

## Redirect Rules

Edit `Caddyfile` (on-prem) or `Caddyfile.azure` (Azure) and add rules using Caddy's `redir` directive.

### Redirect types

```caddyfile
redir /old-path        https://destination.example.com 301   # permanent (GET only)
redir /temporary-promo https://promo.example.com       302   # temporary
redir /gone-forever    https://new-home.example.com    308   # permanent, method-preserving
```

### Multiple paths per domain

Add as many `redir` lines as needed. Use `{uri}` to forward the full path and query string to the new host:

```caddyfile
redir /about   https://company.example.com/about    301
redir /promo   https://promo.example.com            302
redir /blog/*  https://blog.example.com{uri}        301   # /blog/my-post?ref=tw → https://blog.example.com/blog/my-post?ref=tw
```

### Multiple domains — on-prem (`Caddyfile`)

Each site block gets its own TLS certificate from Let's Encrypt. Comma-separate hostnames to share rules. The `(shared)` snippet (defined in `Caddyfile`) applies security headers and JSON logging:

```caddyfile
example.com, www.example.com {
    import shared

    redir /old-path https://destination.example.com 301
    redir /blog/*   https://blog.example.com{uri}   301
}

anotherdomain.com {
    import shared

    redir /old      https://new.anotherdomain.com   301
}
```

### Multiple domains — Azure (`Caddyfile.azure`)

Azure Container Apps preserves the `Host` header, so Caddy can route by hostname inside a single `:80` block using named matchers:

```caddyfile
@example-com host example.com www.example.com
handle @example-com {
    redir /old-path https://destination.example.com 301
    redir /blog/*   https://blog.example.com{uri}   301
}

@anotherdomain host anotherdomain.com
handle @anotherdomain {
    redir /old      https://new.anotherdomain.com   301
}
```

**On Azure:** push the updated `Caddyfile.azure` to `dom` — CI rebuilds and deploys automatically.  
**On-prem:** reload without restarting:

```bash
docker compose exec caddy caddy reload --config /etc/caddy/Caddyfile
```

---

## Deployment

### On-Premises / VM

Caddy manages TLS automatically via Let's Encrypt.

```bash
cp .env.example .env
# Set ACME_EMAIL to a real address — Let's Encrypt sends cert expiry alerts here
docker compose up -d
```

DNS must resolve to the host before starting. Caddy will fail the ACME challenge otherwise.

---

### Azure Container Apps — Full Setup Guide

Everything from a blank subscription to a live, TLS-terminated redirect service.

**Prerequisites:**
- [Azure CLI](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli) installed (`az --version`)
- Owner role on the target Azure subscription
- GitHub repository with admin access (to configure secrets)

---

#### 1. Configure infra parameters

Open `infra/main.bicepparam`. The two parameters you may want to change:

| Parameter | Default | Notes |
|---|---|---|
| `location` | `eastus` | Azure region for all resources |
| `environmentName` | `r3d1r3kt0r` | Base name — drives all resource names below |

All resource names are deterministically derived from `environmentName`:

| Resource | Derived name |
|---|---|
| Resource group | `rg-{environmentName}` |
| Container Registry | `acr{environmentName}` (hyphens stripped — ACR names must be alphanumeric) |
| Managed identity | `id-{environmentName}` |
| Container Apps environment | `acaenv-{environmentName}` |
| Container App | `{environmentName}` |

If you change `environmentName`, update the resource names in any rollback commands.

---

#### 2. Bootstrap Azure infrastructure

```bash
az login
az account list --output table           # identify your subscription
az account set --subscription <subscription-id>

az deployment sub create \
  --name r3d1r3kt0r-init \
  --location westus2 \
  --template-file infra/main.bicep \
  --parameters infra/main.bicepparam \
  --query "properties.outputs" \
  --output json
```

Note the three output values — you'll need them in later steps:

```json
{
  "acrLoginServer":    { "value": "acrr3d1r3kt0r.azurecr.io" },
  "resourceGroupName": { "value": "rg-r3d1r3kt0r" },
  "containerAppName":  { "value": "r3d1r3kt0r" }
}
```

This creates: resource group, Log Analytics workspace, Azure Container Registry (Basic SKU), user-assigned managed identity with AcrPull, Container Apps environment, and a Container App running a placeholder image. The deployment is idempotent — safe to re-run.

---

#### 3. Set up OIDC (GitHub Actions → Azure, no stored credentials)

OIDC lets GitHub Actions authenticate to Azure using short-lived, automatically-issued tokens — no passwords, certificates, or API keys are ever created or stored anywhere. GitHub mints a signed JWT per workflow run; Azure validates it against a federated credential you configure here.

The three values you'll store as GitHub secrets are **identifiers, not credentials** (`clientId`, `tenantId`, `subscriptionId`). They tell Azure where to look, but cannot authenticate on their own — authentication only succeeds when the request comes from a GitHub Actions run in exactly the repo and branch you specify below.

```bash
# Create an App Registration and its service principal
APP_ID=$(az ad app create --display-name "sp-r3d1r3kt0r-github" --query appId -o tsv)
az ad sp create --id "$APP_ID"

# Capture the IDs you need
SP_OID=$(az ad sp show --id "$APP_ID" --query id -o tsv)
SUB_ID=$(az account show --query id -o tsv)
TENANT_ID=$(az account show --query tenantId -o tsv)

echo "APP_ID:    $APP_ID"
echo "TENANT_ID: $TENANT_ID"
echo "SUB_ID:    $SUB_ID"
```

Grant **Owner** on the subscription. This is required because the Bicep template creates a role assignment (AcrPull for the managed identity), which requires `Microsoft.Authorization/roleAssignments/write`:

```bash
az role assignment create \
  --assignee "$SP_OID" \
  --role "Owner" \
  --scope "/subscriptions/$SUB_ID"
```

Create a federated credential scoped to the `dom` branch. Replace `YOUR_ORG` with your GitHub username or organization:

```bash
az ad app federated-credential create --id "$APP_ID" --parameters '{
  "name": "github-actions-dom",
  "issuer": "https://token.actions.githubusercontent.com",
  "subject": "repo:YOUR_ORG/R3D1R3KT0R:ref:refs/heads/dom",
  "audiences": ["api://AzureADTokenAudience"]
}'
```

The `subject` field must exactly match your repo path and branch — Azure rejects tokens from any other repo or branch.

---

#### 4. Set GitHub repository secrets

Go to your repository → **Settings → Secrets and variables → Actions → New repository secret** and add three secrets:

| Secret | Value |
|---|---|
| `AZURE_CLIENT_ID` | `$APP_ID` from step 3 |
| `AZURE_TENANT_ID` | `$TENANT_ID` from step 3 |
| `AZURE_SUBSCRIPTION_ID` | `$SUB_ID` from step 3 |

GitHub encrypts these at rest and injects them as environment variables at runtime — they never appear in logs. Because OIDC is used, there's nothing to rotate: tokens expire within minutes and are scoped to a single workflow run.

---

#### 5. Add your redirect rules

Edit `Caddyfile.azure` with your rules (see [Redirect Rules](#redirect-rules) above). Commit the file.

---

#### 6. Push to trigger the first deploy

```bash
git push origin dom
```

The workflow (`.github/workflows/deploy.yml`) will:
1. Authenticate to Azure via OIDC
2. Run Bicep (idempotent — handles any infra drift since bootstrap)
3. Build the Docker image (`Dockerfile` bakes `Caddyfile.azure` into `caddy:2-alpine`)
4. Push the image to ACR tagged with the 8-character git SHA and `latest`
5. Update the Container App to the new revision

Monitor the run at `https://github.com/YOUR_ORG/R3D1R3KT0R/actions`.

---

#### 7. Configure custom domains

Get the Container App's auto-assigned default hostname:

```bash
az containerapp show \
  --name r3d1r3kt0r \
  --resource-group rg-r3d1r3kt0r \
  --query "properties.configuration.ingress.fqdn" \
  --output tsv
# → r3d1r3kt0r.something.eastus.azurecontainerapps.io
```

For each custom domain you want to route through this service:

**a) Create a DNS CNAME record** at your registrar or DNS provider:

```
example.com   CNAME   r3d1r3kt0r.something.eastus.azurecontainerapps.io
```

For apex domains that don't support CNAME, use an ALIAS/ANAME record (supported by most modern DNS providers). Wait for DNS propagation before continuing.

**b) Bind the domain and provision a free managed TLS certificate:**

```bash
az containerapp hostname add \
  --hostname example.com \
  --name r3d1r3kt0r \
  --resource-group rg-r3d1r3kt0r

az containerapp ssl bind \
  --hostname example.com \
  --name r3d1r3kt0r \
  --resource-group rg-r3d1r3kt0r \
  --environment acaenv-r3d1r3kt0r \
  --validation-method CNAME
```

Repeat for each domain. Azure provisions and auto-renews TLS certificates for all bound hostnames — no Let's Encrypt setup needed.

---

#### Rollback

```bash
az containerapp update \
  --name r3d1r3kt0r \
  --resource-group rg-r3d1r3kt0r \
  --image <acrLoginServer>/r3d1r3kt0r:<old-sha>
```

Find previous SHAs in revision history:

```bash
az containerapp revision list \
  --name r3d1r3kt0r \
  --resource-group rg-r3d1r3kt0r \
  --output table
```

---

## Architecture

On-prem:
```
Internet → :80  → 308 HTTPS redirect (Caddy)
Internet → :443 → TLS termination (Let's Encrypt) → redirect rules
```

Azure:
```
Internet → Azure ingress (TLS, managed certs) → :80 (Caddy) → redirect rules
```

| File | Purpose |
|---|---|
| `Caddyfile` | On-prem config — Caddy owns TLS via Let's Encrypt |
| `Caddyfile.azure` | Azure config — `auto_https off`, Azure ingress owns TLS |
| `Dockerfile` | Bakes `Caddyfile.azure` into `caddy:2-alpine` for Azure |
| `docker-compose.yml` | Base compose for on-prem |
| `docker-compose.azure.yml` | Compose override for local Azure testing |
| `infra/main.bicep` | All Azure infrastructure (subscription-scoped, idempotent) |
| `infra/main.bicepparam` | Bicep parameter values — edit location and environmentName here |
| `.github/workflows/deploy.yml` | CI/CD — triggers on push to `dom` |

---

## Changelog

### 2026-05-22
- Added **BIOCHEM WEBSITES** redirect group (6 rules): `*.science.oregonstate.edu` → canonical biochem department destinations, all 301 permanent.
- Added **CEOAS WEBSITES** redirect group (6 rules): legacy `geo.*` subdomains and `icecorelab.science.oregonstate.edu` → CEOAS canonical destinations, all 301 permanent.
- Added **CHEMISTRY WEBSITES** redirect group (5 rules): legacy chemistry subdomains → canonical destinations, all 301 permanent. `xrd.chem.*` → `xrd.science.*` is intentionally reversed relative to the other rules in this group.
- Added **INTEGRATIVE BIOLOGY WEBSITES** redirect group (4 rules): legacy `*.science.oregonstate.edu` subdomains → canonical IB destinations, all 301 permanent. `bi21x.science` and `bi22x.science` combined into one rule as both target `bi22x.ib`.
- Added **MATHEMATICS WEBSITES** redirect group (2 rules): `math.oregonstate.edu/BridgeBook` path-specific redirect and `calendar.math.oregonstate.edu` whole-domain-to-fixed-URL redirect, all 301 permanent.
- Added **MICROBIOLOGY WEBSITES** redirect group (5 rules): legacy microbiology subdomains → canonical destinations, all 301 permanent. `biohealth.science` and `microbiology.science` combined into one rule; `core-values.microbiology` redirects to a fixed URL path (incoming path not forwarded).
- Updated **MATHEMATICS WEBSITES**: added `redir /BridgeBook/*` wildcard to `math.oregonstate.edu` so subpaths under `/BridgeBook/` redirect correctly.
- Added **PHYSICS WEBSITES** redirect group (25 rules): 22 path-specific rules on `physics.oregonstate.edu` (root, named paths, tilde personal pages with `/BridgeBook` exact+wildcard pair) plus `www.physics.orst.edu`, `calendar.physics.oregonstate.edu` (fixed URL), and `osuper.science.oregonstate.edu`. All 301 permanent.
- Added **STATISTICS WEBSITES** redirect group (1 rule): `www.stat.orst.edu` → `stat.oregonstate.edu`, 301 permanent.
- Added **MYOPINION SURVEYS** sub-group under STATISTICS WEBSITES (6 rules): `myopinion.oregonstate.edu` path-specific redirects to Qualtrics forms; root → Surveys Research Center. All fixed-URL 301. `/dmv` and `/DMV` listed separately (case-sensitive path matching).
- Added **reverse proxy fallback** to `math.oregonstate.edu` and `physics.oregonstate.edu`: traffic not matched by an explicit redirect rule is proxied to `oregonstate.acquiaedge.net` (Acquia Edge / Cloudflare) with the `Host` header preserved. End users see the original hostname in their browser; Acquia Edge routes the request to the correct Drupal site. No 404s for unlisted paths.
