# Ingress Controller и публикация сервисов

В данном разделе описана настройка Ingress Controller и публикация приложения по HTTP.

Цель этапа — обеспечить доступ к сервисам Kubernetes-кластера извне.

---

## Общая идея

Кластер развернут на VDS без cloud LoadBalancer, поэтому стандартный Service типа `LoadBalancer` недоступен.

Для решения этой задачи используется следующий подход:

* ingress-nginx устанавливается как **DaemonSet**
* используется **hostNetwork: true**
* Ingress слушает порты **80/443 напрямую на worker-нодах**

Таким образом, пользователь может обращаться к сервисам по IP-адресу worker-ноды.

---

## Используемые компоненты

* ingress-nginx
* Helm
* Kubernetes Ingress

---

## Установка ingress-nginx

Ingress Controller устанавливается с помощью Helm и автоматизируется через Ansible.

### Основные параметры установки

* тип контроллера: `DaemonSet`
* включён `hostNetwork`
* сервис создаётся как `ClusterIP`

Файл с параметрами:

```
platform/ingress/ingress-nginx/values.yaml
```

Установка выполняется командой:

```bash
make ingress
```

После установки проверяется состояние подов:

```bash
kubectl -n ingress-nginx get pods -o wide
```

Ожидаемый результат — pod ingress-nginx на каждой worker-ноде.

---

## Открытие портов на worker-нодах

Для доступа извне на worker-нодах должны быть открыты порты 80 и 443.

Настройка выполняется через Ansible:

```bash
make ufw-ingress
```

---

## Тестовое приложение

Для проверки работы Ingress используется простое тестовое приложение `whoami`.

Приложение включает:

* Deployment (2 реплики)
* Service
* Ingress

Манифест расположен в:

```
platform/apps/demo/whoami.yaml
```

Применение:

```bash
kubectl apply -f platform/apps/demo/whoami.yaml
```

---

## Проверка работы

Проверка выполняется через HTTP-запрос к worker-ноде с указанием Host-заголовка.

Пример:

```bash
curl -H "Host: whoami.<worker-ip>.nip.io" http://<worker-ip>/
```

Пример результата:

```
Hostname: whoami-xxxxx
```

Это означает, что запрос прошёл следующий путь:

```
Internet → worker node → ingress-nginx → service → pod
```

---

## Результат этапа

На данном этапе реализована публикация сервисов Kubernetes-кластера по HTTP:

* ingress-nginx развернут в кластере
* доступ осуществляется через IP worker-ноды
* приложения публикуются стандартным объектом Ingress

Ingress используется далее для размещения пользовательских приложений и сервисов платформы.

---

Следующий этап — настройка мониторинга и наблюдаемости кластера.
