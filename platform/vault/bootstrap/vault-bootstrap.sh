#!/usr/bin/env sh
set -eu

log() { echo "$@"; }

: "${VAULT_ADDR:?VAULT_ADDR is required}"
: "${VAULT_TOKEN:?VAULT_TOKEN is required}"

log "[*] Vault addr: ${VAULT_ADDR}"

# Подождём, пока API начнёт отвечать (после unseal/ингресса)
log "[*] Waiting for Vault API..."
i=0
while [ $i -lt 60 ]; do
  if vault status >/dev/null 2>&1; then
    break
  fi
  i=$((i+1))
  sleep 2
done

log "[*] Vault status:"
vault status

# KV v2
log "[*] Enable KV v2 at secret/ (idempotent)"
vault secrets enable -path=secret kv-v2 2>/dev/null || true

# Kubernetes auth
log "[*] Enable kubernetes auth (idempotent)"
vault auth enable kubernetes 2>/dev/null || true

log "[*] Configure kubernetes auth"
vault write auth/kubernetes/config \
  kubernetes_host="https://kubernetes.default.svc" \
  kubernetes_ca_cert=@/var/run/secrets/kubernetes.io/serviceaccount/ca.crt \
  token_reviewer_jwt="$(cat /var/run/secrets/kubernetes.io/serviceaccount/token)"

# Policy — через printf (без heredoc, без сюрпризов с кодировкой)
log "[*] Create/Update policy app-read-secret"
printf '%s\n' \
'path "secret/data/demo/*" {' \
'  capabilities = ["read"]' \
'}' \
'' \
'path "sys/internal/ui/mounts/*" {' \
'  capabilities = ["read"]' \
'}' \
| vault policy write app-read-secret -

# Role
log "[*] Create/Update role demo-app in kubernetes auth"
vault write auth/kubernetes/role/demo-app \
  bound_service_account_names="demo-app" \
  bound_service_account_namespaces="demo" \
  policies="app-read-secret" \
  ttl="24h" >/dev/null

# Sample secret
log "[*] Put sample secret at secret/demo/hello"
vault kv put secret/demo/hello value="world" >/dev/null

log "[+] Bootstrap completed"
