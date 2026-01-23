# 03 — Ingress

## Цель

Обеспечить внешний доступ к сервисам Kubernetes-кластера **без облачных Load Balancer’ов**, используя:

* ingress-nginx
* DaemonSet + hostNetwork
* маршрутизацию по Host header

---

## Архитектура

* ingress-nginx развёрнут как **DaemonSet**
* `hostNetwork: true`
* Порты **80/443** открыты напрямую на worker-нодах
* Один ingress обслуживает несколько сервисов по доменам:

  * `vault.ejara1.ru` → HashiCorp Vault
  * `shop.ejara1.ru` → Online Boutique

**Важно:**

* 443 порт **общий для всех сервисов**
* маршрутизация происходит по HTTP Host / SNI
* Vault и Online Boutique не конфликтуют между собой

---

## Почему DaemonSet + hostNetwork

Такой подход выбран осознанно:

* нет необходимости в cloud Load Balancer
* минимальная задержка
* простая и прозрачная схема
* хорошо подходит для bare-metal и self-hosted кластеров

Минусы:

* ingress доступен только на тех нодах, где он запущен
* требуется внешний DNS, указывающий на IP worker-ноды

---

## Развёртывание

```bash
make ingress
make ufw-ingress
```

---

## DNS

Для каждого сервиса создаётся отдельная DNS-запись:

* `vault.ejara1.ru` → IP worker-ноды
* `shop.ejara1.ru` → IP worker-ноды

> Для MVP используется **один IP** worker-ноды. Масштабирование возможно через несколько A-записей.

---

## Проверка

```bash
kubectl -n ingress-nginx get pods
kubectl get ingress -A
```

Пример теста:

```bash
curl -I https://shop.ejara1.ru
```

---

## Примечания

* nip.io использовался только для раннего smoke-теста
* в финальной конфигурации применяется собственный домен
