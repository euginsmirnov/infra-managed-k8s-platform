# Vault

## Назначение

Vault используется как **централизованное хранилище секретов** для Kubernetes‑платформы. Решение максимально приближено к production‑подходу:

* TLS через cert-manager
* публикация через ingress-nginx
* HA‑режим на базе Raft
* Kubernetes auth (ServiceAccount → Vault role)
* минимум автоматизации вокруг unseal/root token

Цель — управляемая, предсказуемая и безопасная схема без managed‑KMS.

---

## Архитектура

### Компоненты

* **Vault** (Helm chart `hashicorp/vault`)
* **Storage**: Raft (PVC через `local-path-provisioner`)
* **Ingress**: nginx + cert-manager
* **TLS**: Let’s Encrypt (`ClusterIssuer`)
* **Auth**: Kubernetes auth method

### Namespace

```
vault
```

### DNS / Ingress

```
vault.ejara1.ru → ingress-nginx → vault service
```

TLS‑секрет:

```
vault-tls
```

---

## Deployment flow

### 1. Установка Vault

Выполняется через Ansible + Helm:

* Namespace `vault`
* Helm release `vault`
* Ingress + TLS
* RBAC для Kubernetes auth reviewer

Команда:

```bash
make vault
```

На этом этапе:

* pod `vault-0` = `Running`
* pod **не Ready**, пока Vault sealed

---

### 2. Init и Unseal (ручной этап)

⚠️ Этот шаг **не автоматизируется намеренно**.

#### Проверка статуса

```bash
kubectl -n vault exec -it vault-0 -- vault status
```

#### Init (один раз)

```bash
kubectl -n vault exec -it vault-0 -- vault operator init
```

Результат:

* 5 unseal keys
* root token

🔐 **Хранить вне кластера, не в git**

#### Unseal (3 из 5 ключей)

```bash
kubectl -n vault exec -it vault-0 -- vault operator unseal
```

После unseal:

* `Sealed: false`
* pod `vault-0` → `Ready`

---

### 3. Bootstrap (KV + auth)

Bootstrap выполняется **Job‑ом** и настраивает:

* KV v2 (`secret/`)
* Kubernetes auth
* policy `app-read-secret`
* role `demo-app`
* тестовый secret `secret/demo/hello`

#### Подготовка

Создать secret с root token:

```bash
kubectl -n vault create secret generic vault-bootstrap-token \
  --from-literal=token="<ROOT_TOKEN>"
```

#### Запуск

```bash
make vault
```

#### Проверка логов

```bash
kubectl -n vault logs job/vault-bootstrap
```

Ожидаемо:

```
[+] Bootstrap completed
```

---

## Проверка работы (E2E)

### Тестовый pod

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: vault-test
  namespace: demo
spec:
  serviceAccountName: demo-app
  restartPolicy: Never
  containers:
    - name: vault
      image: hashicorp/vault:1.21.2
      command: ["sh"]
      stdin: true
      tty: true
```

```bash
kubectl -n demo apply -f vault-test.yaml
kubectl -n demo exec -it vault-test -- sh
```

### Login в Vault

```sh
export VAULT_ADDR="https://vault.ejara1.ru"
JWT="$(cat /var/run/secrets/kubernetes.io/serviceaccount/token)"

vault write -format=json auth/kubernetes/login \
  role="demo-app" \
  jwt="$JWT" > /tmp/login.json
```

```sh
export VAULT_TOKEN="$(awk -F'"' '/client_token/ {print $4}' /tmp/login.json)"
```

### Чтение секрета

```sh
vault kv get secret/demo/hello
```

Ожидаемо:

```
value: world
```

---

## Security notes

* Root token **не хранится** в git или Kubernetes
* Unseal выполняется вручную
* Bootstrap job запускается **только при наличии root token secret**
* Политики минимальные (least privilege)

---

## Ограничения и осознанные решения

* ❌ Нет auto‑unseal (KMS/HSM)
* ❌ Нет dynamic secrets (пока)
* ❌ Нет External Secrets Operator

Это сделано намеренно для прозрачности и контроля.

---

## Следующие шаги

* Подключение External Secrets Operator
* Интеграция Online Boutique
* Audience‑based Kubernetes auth
* Auto‑unseal (опционально)
