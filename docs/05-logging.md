# 05 — Logging (Loki + Promtail)

## Цель

Обеспечить централизованный сбор логов Kubernetes-кластера без внешних managed-сервисов:

* сбор логов контейнеров и kubelet
* минимальное потребление ресурсов
* интеграция с Grafana

---

## Архитектура

* Namespace: `logging`
* Loki: **single binary mode**
* Storage:

  * metadata + index — внутри pod
  * chunks — S3-совместимое хранилище
* Promtail:

  * DaemonSet на всех нодах
  * сбор:

    * container logs (`/var/log/pods`)
    * kubelet logs

Режим single выбран осознанно — для MVP и небольшого кластера он проще и надёжнее, чем distributed.

---

## Развёртывание

```bash
make logging
```

Playbook выполняет:

* установку Loki
* настройку backend-хранилища
* установку Promtail
* регистрацию Loki datasource в Grafana

---

## Проверка

### Pods

```bash
kubectl -n logging get pods
```

Ожидаемо:

* Loki — `Running`
* Promtail — `Running` на всех нодах

### Grafana

1. Открыть Grafana через ingress
2. Перейти в **Explore**
3. Выбрать datasource **Loki**
4. Выполнить запрос:

```
{namespace="online-boutique"}
```

Логи должны отображаться.

---

## Типовые проблемы

### PVC без StorageClass

Решение: использовать `local-path-provisioner` как default StorageClass.

### Ошибки ring / memberlist

Возникают при неверном режиме Loki. В данном проекте используется **single binary**, поэтому эти ошибки исключены.

---

## Ограничения

* ❌ Нет retention policy (настраивается вручную)
* ❌ Нет multi-tenant isolation

Для учебного и MVP-сценария это допустимо.
