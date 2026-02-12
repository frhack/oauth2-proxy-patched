# oauth2-proxy v7.14.2 patched

Immagini custom di oauth2-proxy v7.14.2 con patch applicate. Due varianti disponibili.

## Patch incluse

- **PR #3333**: fix per invalidare la sessione su errori fatali OAuth2 durante il refresh del token (`invalid_grant`, `invalid_client`). Senza questa patch, una sessione revocata lato provider (es. Keycloak) rimane attiva indefinitamente in oauth2-proxy.
  - https://github.com/oauth2-proxy/oauth2-proxy/pull/3333
  - Risolve: https://github.com/oauth2-proxy/oauth2-proxy/issues/1945
- **PR #3336**: subcommand `oauth2-proxy health` per healthcheck Docker built-in senza curl.
  - https://github.com/oauth2-proxy/oauth2-proxy/pull/3336
  - Risolve: https://github.com/oauth2-proxy/oauth2-proxy/issues/2555

## Due varianti

| Variante | Dockerfile | Tag | Healthcheck | Dimensione |
|----------|-----------|-----|-------------|-----------|
| **Con curl** | `Dockerfile` | `oauth2-proxy:v7.14.2-patched` | `curl -f http://localhost:4180/ping` | ~49 MB |
| **Senza curl** (raccomandata) | `Dockerfile.nocurl` | `oauth2-proxy:v7.14.2-patched-nocurl` | `oauth2-proxy health` (built-in) | ~40 MB |

La variante **nocurl** e' raccomandata: distroless pura, nessun tool esterno, superficie di attacco minima.

## Contenuto directory

```
Dockerfile          # Variante con curl (PR #3333 + curl da Alpine)
Dockerfile.nocurl   # Variante senza curl (PR #3333 + PR #3336, raccomandata)
pr-3333.patch       # Diff PR #3333 (gh pr diff 3333 --repo oauth2-proxy/oauth2-proxy)
pr-3336.patch       # Diff PR #3336 (gh pr diff 3336 --repo oauth2-proxy/oauth2-proxy)
README.md           # Questo file
```

## Build

```bash
# Variante con curl (compatibile con healthcheck esistenti)
docker build -t oauth2-proxy:v7.14.2-patched .

# Variante senza curl (raccomandata)
docker build -f Dockerfile.nocurl -t oauth2-proxy:v7.14.2-patched-nocurl .
```

## Verifica

```bash
# Versione
docker run --rm oauth2-proxy:v7.14.2-patched-nocurl --version
# Atteso: oauth2-proxy v7.14.2-patched (built with go1.25.7)

# Health check built-in (solo nocurl)
docker run --rm oauth2-proxy:v7.14.2-patched-nocurl health --help

# Verifica curl (solo variante con curl)
docker run --rm --entrypoint /usr/bin/curl oauth2-proxy:v7.14.2-patched --version
```

## Trasferimento su altra macchina

```bash
# Esporta
docker save oauth2-proxy:v7.14.2-patched-nocurl | gzip > oauth2-proxy-v7.14.2-patched-nocurl.tar.gz

# Copia
scp oauth2-proxy-v7.14.2-patched-nocurl.tar.gz user@destinazione:/tmp/

# Importa sulla destinazione
docker load < /tmp/oauth2-proxy-v7.14.2-patched-nocurl.tar.gz
```

## Aggiornare le patch

```bash
# Scaricare i diff aggiornati
gh pr diff 3333 --repo oauth2-proxy/oauth2-proxy > pr-3333.patch
gh pr diff 3336 --repo oauth2-proxy/oauth2-proxy > pr-3336.patch

# Per cambiare versione base
docker build -f Dockerfile.nocurl --build-arg VERSION=v7.x.x -t oauth2-proxy:v7.x.x-patched-nocurl .
```

## Migrazione da curl a nocurl

Per migrare i container esistenti dalla variante con curl a quella senza curl, aggiornare l'healthcheck nei `docker-compose.yml`:

```yaml
# PRIMA (con curl)
healthcheck:
  test: ["CMD", "curl", "-f", "http://localhost:4180/ping"]

# DOPO (senza curl, built-in)
healthcheck:
  test: ["CMD", "/bin/oauth2-proxy", "health"]
```

## Note

- L'immagine base runtime e' `gcr.io/distroless/static:nonroot` (stessa dell'immagine ufficiale)
- Il binario e' compilato con `CGO_ENABLED=0` (statico, no dipendenze glibc)
- Build originale: 2026-02-11 (curl), 2026-02-12 (nocurl)
