# R3D1R3KT0R

A minimal, hardened web redirect service built on [Caddy 2](https://caddyserver.com). Configuration only — no application code.

- HTTP → HTTPS enforcement via 308 permanent redirect
- Security headers (HSTS, X-Frame-Options, X-Content-Type-Options, Referrer-Policy)
- Structured JSON logging to stdout
- Caddy admin API disabled
- Read-only container filesystem, all Linux capabilities dropped except `NET_BIND_SERVICE`

---

## Adding Redirect Rules

Edit `Caddyfile` (on-prem) or `Caddyfile.azure` (Azure) inside the server block:

```caddyfile
redir /old-path        https://destination.example.com 301   # permanent
redir /temporary-promo https://promo.example.com       302   # temporary
redir /gone-forever    https://new-home.example.com    308   # permanent, method-preserving
```

On Azure, push to `dom` — CI rebuilds and deploys automatically. On-prem, reload without restarting:

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

### Azure Container Apps (CI/CD)

Azure manages TLS. `Caddyfile.azure` is baked into the Docker image at build time.

**One-time infrastructure bootstrap** (requires Azure subscription Owner):

```bash
az deployment sub create \
  --name r3d1r3kt0r-init \
  --location eastus \
  --template-file infra/main.bicep \
  --parameters infra/main.bicepparam
```

This creates: resource group, Log Analytics workspace, Azure Container Registry, managed identity with AcrPull, Container Apps environment, and the Container App.

**One-time OIDC setup** (enables GitHub Actions to authenticate to Azure without stored secrets):

```bash
APP_ID=$(az ad app create --display-name "sp-r3d1r3kt0r-github" --query appId -o tsv)
az ad sp create --id "$APP_ID"
SP_OID=$(az ad sp show --id "$APP_ID" --query id -o tsv)
SUB_ID=$(az account show --query id -o tsv)

az role assignment create --assignee "$SP_OID" --role "Owner" --scope "/subscriptions/$SUB_ID"

az ad app federated-credential create --id "$APP_ID" --parameters '{
  "name": "github-actions-dom",
  "issuer": "https://token.actions.githubusercontent.com",
  "subject": "repo:YOUR_ORG/R3D1R3KT0R:ref:refs/heads/dom",
  "audiences": ["api://AzureADTokenAudience"]
}'
```

Add these as GitHub repository secrets:

| Secret | Value |
|---|---|
| `AZURE_CLIENT_ID` | `$APP_ID` |
| `AZURE_TENANT_ID` | `az account show --query tenantId -o tsv` |
| `AZURE_SUBSCRIPTION_ID` | `$SUB_ID` |

After that, every push to `dom` deploys automatically.

**Rollback** to any previous image by SHA:

```bash
az containerapp update \
  --name r3d1r3kt0r \
  --resource-group rg-r3d1r3kt0r \
  --image <acr-login-server>/r3d1r3kt0r:<old-sha>
```

---

## Architecture

```
Internet → :80  → 308 HTTPS redirect (Caddy automatic, on-prem only)
Internet → :443 → TLS termination → redirect rules
```

| File | Purpose |
|---|---|
| `Caddyfile` | On-prem config — Caddy owns TLS via Let's Encrypt |
| `Caddyfile.azure` | Azure config — `auto_https off`, Azure ingress owns TLS |
| `Dockerfile` | Bakes `Caddyfile.azure` into `caddy:2-alpine` for Azure |
| `docker-compose.yml` | Base compose for on-prem |
| `docker-compose.azure.yml` | Compose override for local Azure testing |
| `infra/main.bicep` | All Azure infrastructure (subscription-scoped, idempotent) |
| `.github/workflows/deploy.yml` | CI/CD — triggers on push to `dom` |
