# Этап 1. Bootstrap узлов

В данном разделе описан этап bootstrap — базовая подготовка серверов для дальнейшего развертывания Kubernetes.

Bootstrap выполняется одинаково на всех узлах кластера: как на control-plane, так и на worker-нодах.

---

## Цель этапа

Подготовить операционную систему для корректной работы Kubernetes.

На данном этапе Kubernetes-кластер ещё не создаётся — выполняется только системная подготовка серверов.

---

## Что выполняется в рамках bootstrap

В процессе bootstrap выполняются следующие действия:

* отключение swap
* загрузка необходимых kernel-модулей (`overlay`, `br_netfilter`)
* настройка sysctl параметров для Kubernetes
* установка containerd
* настройка containerd для работы с kubelet (`SystemdCgroup=true`)
* установка kubelet, kubeadm и kubectl
* фиксация версий Kubernetes-пакетов

Все действия выполняются автоматически с помощью Ansible.

---

## Запуск bootstrap

```bash
make bootstrap
```

После выполнения bootstrap на всех серверах должны быть доступны команды:

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

## Результат этапа

После завершения bootstrap:

* все узлы подготовлены для установки Kubernetes
* container runtime настроен
* версии Kubernetes зафиксированы

Данный этап является обязательной основой для дальнейшей инициализации кластера.

---

Следующий этап — инициализация Kubernetes-кластера с помощью kubeadm.
