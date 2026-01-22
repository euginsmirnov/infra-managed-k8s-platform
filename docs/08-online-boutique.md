# 08. Online Boutique (Demo Workload)

## Цель

Развернуть **Online Boutique** как demo-приложение для проверки всей платформы end-to-end:

* ingress-nginx + cert-manager (TLS)
* Vault → External Secrets Operator → Kubernetes Secret
* работа микросервисного приложения
* эксплуатационные ограничения (малый кластер)

Деплой выполняется **исключительно через Ansible / Makefile**.

---

## Архитектура

```
User → HTTPS (shop.ejara1.ru)
  → ingress-nginx
    → frontend (Online Boutique)
      → internal services
      → secrets from K8s (synced via ESO)
          ↑
        ESO
          ↑
        Vault (KV v2)
```

---

## Домен и TLS

* Домен: `shop.ejara1.ru`
* DNS указывает на IP **первого worker-нода**
* TLS:

  * cert-manager
  * ClusterIssuer: `letsencrypt-prod`
  * Secret: `online-boutique-tls`

Проверка:

```bash
kubectl -n online-boutique get ingress
kubectl -n online-boutique get certificate
curl -I https://shop.ejara1.ru
```

---

## Деплой Online Boutique

### Команда

```bash
make online-boutique
```

### Что делает playbook

1. Создаёт namespace `online-boutique`
2. Скачивает **upstream manifest** Online Boutique
3. Применяет его в namespace (upstream не содержит namespaces)
4. Применяет патчи для **малых кластеров**
5. Создаёт Ingress с TLS
6. (Опционально) масштабирует `loadgenerator` до `0`

---

## Тюнинг для малых кластеров

Некоторые сервисы (например `emailservice`) по умолчанию нестабильны на небольших нодах.

Применяется автоматический patch:

* увеличены timeout’ы liveness/readiness
* снижены resource limits

Это **обязательная часть playbook**, а не ручной фикс.

---

## Интеграция с Vault через External Secrets

### Поток секретов

1. Secret хранится в Vault:

   ```
   secret/data/online-boutique/frontend/demo_message
   ```

2. ESO (`ExternalSecret`) синхронизирует его в Kubernetes Secret:

   ```
   ob-frontend-demo
   ```

3. Frontend deployment получает значение через env:

   ```yaml
   DEMO_MESSAGE:
     valueFrom:
       secretKeyRef:
         name: ob-frontend-demo
         key: demo_message
   ```

---

## Демо-плейбук с секретами

### Команда

```bash
make online-boutique-secrets-demo
```

### Что делает

1. Создаёт `ExternalSecret` для frontend
2. Ждёт синхронизацию ESO
3. Патчит frontend deployment
4. Ждёт rollout
5. Проверяет значение секрета через Kubernetes API

Важно: **kubectl не используется**, только `kubernetes.core` модули.

---

## Проверка

```bash
kubectl -n online-boutique get pods
kubectl -n online-boutique get ingress
curl https://shop.ejara1.ru
```

Secret:

```bash
kubectl -n online-boutique get secret ob-frontend-demo \
  -o jsonpath='{.data.demo_message}' | base64 -d
```

Ожидаемое значение:

```
Hello from Vault via ESO
```

---

## Итог

Online Boutique успешно демонстрирует:

* production ingress + TLS
* централизованное управление секретами
* GitOps/IaC подход
* эксплуатационную готовность платформы