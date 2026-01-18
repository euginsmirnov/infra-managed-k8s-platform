# Bootstrap и развертывание Kubernetes-кластера (kubeadm)

В этом разделе описан процесс развертывания Kubernetes-кластера с помощью **kubeadm**.

Кластер используется как основа для проектной работы «Managed Kubernetes платформа».
Все шаги выполняются с использованием **Ansible** и подхода *Infrastructure as Code*.

---

## Архитектура окружения

Для проекта используется следующая схема:

```
Management / Bastion (ejara1.ru)
  └─ используется для управления кластером
     (Ansible, kubectl)

Kubernetes cluster:

- controller-01 — control-plane
- worker-01 — worker node
- worker-02 — worker node
- worker-03 — worker node
```

Все серверы работают под управлением **Ubuntu 24.04**.

---

## Используемые компоненты

| Компонент  | Назначение                            |
| ---------- | ------------------------------------- |
| kubeadm    | Инициализация и управление Kubernetes |
| containerd | Container Runtime                     |
| Ansible    | Автоматизация установки и настройки   |
| Calico     | Сетевая модель Kubernetes (CNI)       |
| UFW        | Базовый firewall                      |

---

# Этап 1. Bootstrap узлов

На этапе bootstrap все серверы подготавливаются для работы с Kubernetes.

В рамках этапа выполняется:

* отключение swap
* загрузка необходимых kernel-модулей
* настройка sysctl параметров
* установка containerd
* настройка containerd для работы с kubelet
* установка kubelet, kubeadm и kubectl
* фиксация версий пакетов

Все действия выполняются автоматически через Ansible.

---

## Запуск bootstrap

```bash
make bootstrap
```

После выполнения bootstrap на всех узлах должны быть доступны команды:

```bash
kubeadm version
kubelet --version
containerd --version
```

Для проверки используется команда:

```bash
make versions
```

---

# Этап 2. Инициализация control-plane

После bootstrap выполняется инициализация Kubernetes-кластера.

Инициализация выполняется **только на сервере controller-01**.

Используется kubeadm config-файл, в котором задаются:

* версия Kubernetes
* адрес control-plane
* диапазоны pod и service сетей

Пример конфигурации:

```yaml
apiVersion: kubeadm.k8s.io/v1beta3
kind: ClusterConfiguration
kubernetesVersion: v1.29.6
controlPlaneEndpoint: <controller-ip>:6443
networking:
  podSubnet: 192.168.0.0/16
  serviceSubnet: 10.96.0.0/12
```

Запуск инициализации:

```bash
make kubeadm-init
```

В процессе выполнения:

* создаётся etcd
* запускается kube-apiserver
* разворачиваются системные компоненты Kubernetes
* kubeconfig автоматически копируется на management-сервер

После этого появляется доступ к кластеру через kubectl.

---

## Проверка состояния

```bash
kubectl get nodes
```

На данном этапе статус control-plane будет:

```
NotReady
```

Это ожидаемое поведение, так как сеть кластера ещё не установлена.

---

# Этап 3. Установка CNI (Calico)

Для организации сетевого взаимодействия между Pod используется **Calico**.

Установка выполняется применением манифеста:

```bash
kubectl apply -f platform/cni/calico/calico.yaml
```

После установки необходимо проверить состояние компонентов:

```bash
kubectl get pods -n kube-system
kubectl get nodes
```

После запуска Calico control-plane переходит в состояние:

```
Ready
```

---

# Этап 4. Подключение worker-нод

После того как control-plane стал Ready, выполняется подключение worker-нод.

```bash
make kubeadm-join
```

В рамках данного этапа:

* генерируется join token
* worker-ноды подключаются к кластеру
* kubelet начинает работу в составе кластера

---

## Проверка

```bash
kubectl get nodes -o wide
```

Ожидаемый результат:

```
controller-01   Ready   control-plane
worker-01       Ready
worker-02       Ready
worker-03       Ready
```

Также проверяется наличие сетевых pod на всех узлах:

```bash
kubectl get pods -n kube-system | grep calico-node
```