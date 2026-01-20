#!/bin/sh
set -eu

echo "[*] Vault addr: ${VAULT_ADDR}"
vault status || true

echo "[*] Enable KV v2 at secret/ (idempotent)"
vault secrets enable -path=secret kv-v2 2>/dev/null || true

echo "[*] Enable kubernetes auth (idempotent)"
vault auth enable kubernetes 2>/dev/null || true

echo "[*] Configure kubernetes auth"
# Внутри job мы в кластере, берём serviceaccount JWT + CA + kube host
SA_JWT="$(cat /var/run/secrets/kubernetes.io/serviceaccount/token)"
SA_CA="/var/run/secrets/kubernetes.io/serviceaccount/ca.crt"
KUBE_HOST="https://kubernetes.default.svc"

vault write auth/kubernetes/config \
  token_reviewer_jwt="$SA_JWT" \
  kubernetes_host="$KUBE_HOST" \
  kubernetes_ca_cert=@$SA_CA

echo "[*] Create policy app-read-secret"
cat <<'EOF' | vault policy write app-read-secret -
path "secret/data/demo/*" {
  capabilities = ["read"]
}
EOF

echo "[*] Create role demo-app in kubernetes auth"
# Для примера: namespace demo, serviceaccount demo-app
vault write auth/kubernetes/role/demo-app \
  bound_service_account_names=demo-app \
  bound_service_account_namespaces=demo \
  policies=app-read-secret \
  ttl=24h

echo "[*] Put sample secret at secret/demo/hello"
vault kv put secret/demo/hello value="world"

echo "[+] Bootstrap completed"
