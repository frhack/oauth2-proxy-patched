# oauth2-proxy v7.14.2 patched

Immagine custom di oauth2-proxy v7.14.2 con:

- **PR #3333**: fix per invalidare la sessione su errori fatali OAuth2 durante il refresh del token (`invalid_grant`, `invalid_client`). Senza questa patch, una sessione revocata lato provider (es. Keycloak) rimane attiva indefinitamente in oauth2-proxy.
  - https://github.com/oauth2-proxy/oauth2-proxy/pull/3333
  - Risolve: https://github.com/oauth2-proxy/oauth2-proxy/issues/1945
- **curl** incluso nell'immagine distroless (copiato da Alpine 3.19 con relative librerie)

## Contenuto directory

```
Dockerfile        # Multi-stage build (3 stage: builder, curl-provider, distroless runtime)
pr-3333.patch     # Diff della PR #3333 (scaricato con: gh pr diff 3333 --repo oauth2-proxy/oauth2-proxy)
README.md         # Questo file
```

## Prerequisiti

- Docker
- Accesso a internet (per clonare il repo e scaricare le immagini base)

## Build

```bash
cd /home/frapas/DEV/OAuth2Proxy_patched
docker build -t oauth2-proxy:v7.14.2-patched .
```

## Verifica

```bash
# Versione oauth2-proxy
docker run --rm oauth2-proxy:v7.14.2-patched --version
# Atteso: oauth2-proxy v7.14.2-patched (built with go1.25.7)

# Verifica curl
docker run --rm --entrypoint /usr/bin/curl oauth2-proxy:v7.14.2-patched --version
```

## Trasferimento su altra macchina

```bash
# Esporta
docker save oauth2-proxy:v7.14.2-patched -o oauth2-proxy-v7.14.2-patched.tar

# Copia
scp oauth2-proxy-v7.14.2-patched.tar user@destinazione:/tmp/

# Importa sulla destinazione
docker load -i /tmp/oauth2-proxy-v7.14.2-patched.tar
```

## Aggiornare la patch

Se la PR #3333 viene aggiornata o si vuole rifare la patch su una versione diversa:

```bash
# Scaricare il diff aggiornato
gh pr diff 3333 --repo oauth2-proxy/oauth2-proxy > pr-3333.patch

# Per cambiare versione base, modificare VERSION nel Dockerfile (default: v7.14.2)
docker build --build-arg VERSION=v7.x.x -t oauth2-proxy:v7.x.x-patched .
```

## Note

- L'immagine base runtime e' `gcr.io/distroless/static:nonroot` (stessa dell'immagine ufficiale)
- curl e le sue librerie sono copiate da Alpine 3.19 (stesso pattern usato in PROD per cert-manager su docker-box)
- Il binario e' compilato con `CGO_ENABLED=0` (statico, no dipendenze glibc)
- Build originale: 2026-02-11
