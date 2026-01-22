# 07 — External Secrets Operator (ESO) + Vault

## 1. Назначение

External Secrets Operator (ESO) используется для **синхронизации секретов из Vault в Kubernetes Secrets**.

Зачем он нужен в платформе:

* приложения **не работают напрямую с Vault**
* нет Vault Agent / sidecar в каждом Pod
* Kubernetes остаётся источником секретов для приложений
* Vault — **единственный backend хранения секретов**

Схема:

Vault → ESO → Kubernetes Secret → Application

---

## 2. Архитектурный выбор

### Почему ESO

* нативная интеграция с Vault
* поддержка KV v2
* Kubernetes auth
* хорошо подходит для platform-approach

### Почему ClusterSecretStore

Используется **ClusterSecretStore**, а не `SecretStore`, потому что:

* Vault — кластерный сервис
* единая точка конфигурации доступа
* меньше дублирования
* безопаснее для эксплуатации

Namespaces:

* ESO живёт в `external-secrets`
* приложения используют `ExternalSecret` в своих namespace

---

## 3. Установка ESO

### Make target

```bash
make external-secrets
```

### Что делает плейбук

* создаёт namespace `external-secrets`
* добавляет Helm repo `external-secrets`
* устанавливает External Secrets Operator
* ждёт readiness всех компонентов

Проверка:

```bash
kubectl -n external-secrets get pods
kubectl get crd | grep external-secrets
```

---

## 4. Настройка Vault для ESO

### Policy (Vault)

ESO читает секреты **read-only**.

```hcl
path "secret/data/*" {
  capabilities = ["read"]
}

path "sys/internal/ui/mounts/*" {
  capabilities = ["read"]
}
```

### Role (Kubernetes auth)

```bash
vault write auth/kubernetes/role/eso-read \
  bound_service_account_names=external-secrets \
  bound_service_account_namespaces=external-secrets \
  policies=eso-read \
  ttl=24h
```

---

## 5. ClusterSecretStore

### Важный момент про apiVersion

Используется:

```yaml
apiVersion: external-secrets.io/v1
kind: ClusterSecretStore
```

❌ `v1beta1` больше не является default и может не работать.

### Пример

```yaml
apiVersion: external-secrets.io/v1
kind: ClusterSecretStore
metadata:
  name: vault
spec:
  provider:
    vault:
      server: https://vault.ejara1.ru
      path: secret
      version: v2
      auth:
        kubernetes:
          mountPath: kubernetes
          role: eso-read
          serviceAccountRef:
            name: external-secrets
            namespace: external-secrets
```

Проверка:

```bash
kubectl describe clustersecretstore vault
```

Ожидаемо:

```
Status:
  Type: Ready
  Status: True
  Reason: Valid
```

---

## 6. ExternalSecret (пример)

### Vault secret

```bash
vault kv put secret/demo/hello value=world
```

### ExternalSecret

```yaml
apiVersion: external-secrets.io/v1
kind: ExternalSecret
metadata:
  name: demo-hello
  namespace: demo
spec:
  refreshInterval: 1m
  secretStoreRef:
    kind: ClusterSecretStore
    name: vault
  target:
    name: demo-hello
    creationPolicy: Owner
  data:
    - secretKey: value
      remoteRef:
        key: demo/hello
        property: value
```

---

## 7. Проверка работоспособности

```bash
kubectl -n demo describe externalsecret demo-hello
kubectl -n demo get secret demo-hello -o jsonpath='{.data.value}' | base64 -d
```

Ожидаемо:

```text
world
```

---

## 8. Типовые проблемы

### Ошибка: no matches for kind ClusterSecretStore

Причина:

* используется `external-secrets.io/v1beta1`

Решение:

* перейти на `external-secrets.io/v1`

---

### Ошибка: 403 permission denied

Причины:

* неправильная Vault policy
* неверный `role`
* serviceAccount не совпадает

Проверка:

```bash
vault read auth/kubernetes/role/eso-read
kubectl -n external-secrets get sa external-secrets
```

---

### ESO не создаёт Secret

Проверить:

```bash
kubectl -n external-secrets logs deploy/external-secrets
```

---

## 9. Итог

На текущий момент:

* Vault — единый источник секретов
* ESO — единственная точка синхронизации
* приложения не знают о Vault
* платформа готова к production-подходу
