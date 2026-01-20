# 05. Логирование (Loki + Promtail)

На данном этапе настраивается централизованное логирование Kubernetes-кластера.

Цель — собрать логи со всех нод и pod’ов и просматривать их через Grafana.

---

## Общая идея

Для логирования используется стек Grafana:

- **Loki** — система хранения логов
- **Promtail** — агент для сбора логов с нод
- **Grafana** — интерфейс для просмотра логов

Схема работы:
pod logs → promtail → loki → grafana

---

## Используемые компоненты

- Grafana Loki (single binary)
- Promtail (DaemonSet)
- Grafana (установлена на этапе мониторинга)

---

## Архитектура

### Loki

Используется режим **single binary**, так как кластер небольшой.

- один pod Loki
- хранение данных внутри pod (без распределённого хранилища)
- подходит для dev / lab / learning среды

### Promtail

Promtail разворачивается как **DaemonSet**:

- работает на каждой ноде
- читает логи контейнеров из: /var/log/pods

- автоматически добавляет Kubernetes-лейблы:
- namespace
- pod
- container
- node

---

## Установка Loki и Promtail

Установка выполняется через Helm и автоматизируется Ansible.

Файлы:
platform/logging/loki/values.yaml
automation/ansible/playbooks/logging.yml

Запуск установки:

```bash
make logging

После установки проверяем состояние:
kubectl -n logging get pods -o wide
