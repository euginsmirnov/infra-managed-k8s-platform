# 02. Kubernetes cluster via kubeadm

## Предпосылки
- Доступ по SSH на все ноды
- Ubuntu 22.04 (или совместимый Debian-based)
- Открыты порты Kubernetes control-plane (если CP отдельно)

## Шаги
1) Bootstrap:
- `make bootstrap`

2) Инициализация control-plane:
- `make kubeadm-init`

3) Join worker:
- `make kubeadm-join`

Детали будут дополняться по мере реализации ролей.
