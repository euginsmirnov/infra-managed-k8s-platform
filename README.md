# Infrastructure Managed k8s Platform (kubeadm) for Online Store

Цель: инфраструктурная платформа на базе Kubernetes (kubeadm) + наблюдаемость (monitoring/logging) + CI/CD для приложения.

## Архитектура (MVP)
- 1x Management/Controller VDS: Ansible runner, kubectl, доступ по SSH
- 1x Control-plane node (может совпадать с management при ограниченных ресурсах)
- 3x Worker nodes

## Репозиторий
- `automation/ansible` — автоматизация bootstrap и kubeadm
- `cluster/kubeadm` — конфиги kubeadm, скрипты
- `platform/` — ingress, monitoring, logging, tracing, secrets, registry
- `apps/` — приложение (например Online Boutique)
- `docs/` — пошаговые инструкции (runbooks)

## Быстрый старт
1. Заполнить `inventory/prod/hosts.ini`
2. Запустить bootstrap:
   - `make bootstrap`
3. Поднять кластер:
   - `make kubeadm-init`
   - `make kubeadm-join`

Подробно: `docs/02-kubeadm-cluster.md`

## Changelog
См. `CHANGELOG.md`
