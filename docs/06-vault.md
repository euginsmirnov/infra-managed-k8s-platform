# 06 — HashiCorp Vault

## Цель

Развернуть централизованное хранилище секретов **внутри Kubernetes** без облачных KMS и managed‑сервисов:

* TLS через cert-manager
* доступ через Ingress (`vault.ejara1.ru`)
* storage: Raft (PVC через local-path)
* интеграция с Kubernetes Auth
* дальнейшее использование через **External Secrets Operator (ESO)**

> Осознанно **без auto-unseal** — unseal выполняется вручную для прозрачности и контроля.

---

## Архитектура

* Namespace: `vault`
* Helm chart: `hashicorp/vault`
* Режим: **HA + Raft** (1 реплика для MVP, готово к scale)
* Ingress:

  * host: `vault.ejara1.ru`
  * TLS: Let’s Encrypt (cert-manager)
* Services:

  * `vault-active` — активный лидер
  * `vault-standby` — standby (при scale)

**Важно:** Pod может быть `Running`, но **не Ready**, пока Vault запечатан (sealed). Это ожидаемое поведение.

---

## Развёртывание

```bash
make vault
```

Playbook делает:

* установку Helm chart
* ожидание выпуска TLS‑сертификата
* применение RBAC для Kubernetes Auth
* (опционально) запуск bootstrap‑job

---

## Init и Unseal (ручной шаг)

```bash
kubectl -n vault exec -it vault-0 -- vault operator init
```

Сохранить:

* unseal keys
* root token

Unseal (3 из 5):

```bash
kubectl -n vault exec -it vault-0 -- vault operator unseal
```

Проверка:

```bash
kubectl -n vault exec -it vault-0 -- vault status
```

Ожидаемо:

* `Initialized: true`
* `Sealed: false`

---

## Kubernetes Auth

Включён и настроен автоматически bootstrap‑скриптом:

* mount: `auth/kubernetes`
* token reviewer: service account `vault-auth`

Проверка:

```bash
kubectl -n vault exec -it vault-0 -- vault auth list
```

---

## Secrets Engine

* Используется **KV v2**
* mount path: `secret/`

Пример секрета:

```bash
vault kv put secret/demo/hello value=world
```

---

## Интеграция с External Secrets Operator

Vault используется как backend для ESO:

* `ClusterSecretStore` указывает на `vault.ejara1.ru`
* аутентификация через Kubernetes Auth

Это позволяет приложениям получать секреты **без прямого доступа к Vault**.

Подробнее: `07-external-secrets.md`

---

## Ограничения (осознанные)

* ❌ Нет auto‑unseal (KMS/HSM)
* ❌ Нет cloud storage
* ❌ Нет dynamic secrets (DB creds и т.п.)

Для учебного и MVP‑сценария — осознанный компромисс.

---

## Проверка end‑to‑end

```bash
kubectl -n vault exec -it vault-0 -- vault status
kubectl get ingress -n vault
```

Ingress и TLS должны быть в состоянии `Ready`.
