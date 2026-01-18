# Этап 2. Развертывание Kubernetes-кластера (kubeadm)

В данном разделе описан процесс создания Kubernetes-кластера после выполнения bootstrap.

На этом этапе из подготовленных серверов формируется полноценный Kubernetes-кластер.

---

## Общая схема

* один сервер используется как control-plane
* остальные серверы подключаются как worker-ноды

Развертывание выполняется с помощью kubeadm.

---

## Инициализация control-plane

Инициализация выполняется **только на сервере controller-01**.

Для kubeadm используется конфигурационный файл, в котором задаются:

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

В процессе:

* создаётся etcd
* запускается kube-apiserver
* разворачиваются системные компоненты Kubernetes
* kubeconfig автоматически копируется на management-сервер

---

## Проверка после init

```bash
kubectl get nodes
```

На данном этапе control-plane будет иметь статус:

```
NotReady
```

Это нормальное состояние, так как сеть кластера ещё не установлена.

---

## Установка CNI (Calico)

Для сетевого взаимодействия Pod используется Calico.

Установка выполняется применением манифеста:

```bash
kubectl apply -f platform/cni/calico/calico.yaml
```

После установки необходимо проверить:

```bash
kubectl get pods -n kube-system
kubectl get nodes
```

После запуска Calico control-plane переходит в состояние `Ready`.

---

## Подключение worker-нод

После того как control-plane стал Ready, выполняется подключение worker-нод.

```bash
make kubeadm-join
```

В процессе:

* генерируется join token
* worker-ноды подключаются к кластеру
* kubelet начинает работу в составе Kubernetes

---

## Проверка кластера

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

---

## Результат этапа

После выполнения данного этапа развернут полноценный Kubernetes-кластер:

* self-hosted Kubernetes (kubeadm)
* control-plane и worker-ноды
* Calico networking
* доступ к кластеру с management-сервера

Данный кластер используется далее для развертывания платформенных компонентов.
