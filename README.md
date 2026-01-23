# infra-managed-k8s-platform

> Учебно‑практический проект: управляемая Kubernetes‑платформа «как у облачного провайдера», но без managed‑сервисов.
> Фокус — эксплуатация, воспроизводимость и понятная архитектура.

---

## Что здесь собрано

* **Kubernetes**: kubeadm (Ubuntu 24.04, containerd)
* **CNI**: Calico
* **Ingress**: ingress-nginx (DaemonSet + hostNetwork)
* **TLS**: cert-manager + Let’s Encrypt (ClusterIssuer)
* **Secrets**: HashiCorp Vault (Raft + TLS + Ingress)
* **Secrets sync**: External Secrets Operator (ESO) + Vault
* **Observability**:

  * Metrics: Prometheus
  * Dashboards: Grafana
  * Logs: Loki + Promtail
* **Demo workload**: Online Boutique (HTTPS `shop.ejara1.ru`)

  * демонстрация цепочки **Vault → ESO → Kubernetes Secret → env в Pod**

Платформа полностью разворачивается **внутри кластера**, без cloud‑LB, cloud‑KMS и managed storage.

---

## Архитектура (кратко)

* **Ingress** работает как `DaemonSet + hostNetwork`, трафик приходит напрямую на worker‑ноды по 80/443
* Один IP на worker‑ноде, дальше маршрутизация по **Host header**:

  * `vault.ejara1.ru` → Vault
  * `shop.ejara1.ru` → Online Boutique
* TLS‑сертификаты выпускаются cert‑manager’ом автоматически
* Vault развёрнут в режиме Raft (HA), без auto‑unseal (осознанно)
* External Secrets Operator читает секреты из Vault и создаёт обычные Kubernetes Secrets

---

## Как воспроизвести


### 0. Предусловия

* Ubuntu 24.04 на нодах
* SSH‑доступ + sudo
* Установлены: `make`, `ansible`, `kubectl`

### 1. Bootstrap нод

```bash
make bootstrap
make versions
```

### 2. Kubernetes cluster (kubeadm)

```bash
make kubeadm-init
make kubeadm-join
```

### 3. Ingress

```bash
make ingress
make ufw-ingress
```

### 4. cert-manager (TLS)

```bash
make cert-manager
kubectl get clusterissuer
```

### 5. Vault

```bash
make vault
```

Далее вручную выполняется **init / unseal** (описано в `docs/06-vault.md`).

### 6. External Secrets Operator

```bash
make external-secrets
kubectl describe clustersecretstore vault
```

### 7. Online Boutique (demo workload)

```bash
make online-boutique
make online-boutique-secrets-demo
```

---

## Как проверить, что всё работает

### Ingress + TLS

```bash
kubectl -n online-boutique get ingress
kubectl -n online-boutique get certificate
curl -I https://shop.ejara1.ru
```

Ожидаемо: `HTTP/2 200` и валидный TLS.

### Vault

```bash
kubectl -n vault exec -it vault-0 -- vault status
```

Ожидаемо:

* `Initialized: true`
* `Sealed: false`

### Vault → ESO → Kubernetes Secret

```bash
kubectl -n online-boutique get secret ob-frontend-demo \
  -o jsonpath='{.data.demo_message}' | base64 -d; echo
```

Ожидаемо:

```text
Hello from Vault via ESO
```

### Demo приложение

Открыть в браузере:

```
https://shop.ejara1.ru
```

---

## Документация

Подробные пошаговые описания лежат в каталоге `docs/`:

* `01-bootstrap.md` — подготовка нод
* `02-kubeadm-cluster.md` — развёртывание Kubernetes
* `03-ingress.md` — ingress‑архитектура
* `05-logging.md` — Loki + Promtail
* `06-vault.md` — Vault (TLS, Raft, unseal, bootstrap)
* `07-external-secrets.md` — ESO + Vault
* `08-online-boutique.md` — demo workload + секреты

---