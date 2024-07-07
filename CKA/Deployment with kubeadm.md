Инструкция по установке кластера с помощью kubeadm доступна по [ссылке](https://github.com/kodekloudhub/certified-kubernetes-administrator-course).

Скачать Vagrant по [ссылке](https://hashicorp-releases.yandexcloud.net/vagrant/).

В Vagrantfile нужно добавить одну строку: `ENV['VAGRANT_SERVER_URL'] = 'https://vagrant.elab.pro'`.

[Ссылка](https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/install-kubeadm/) на официальную документацию.

Начинаем с установки Container Runtime.

Выполняем на всех нодах кластера.

### Forwarding IPv4 and letting iptables see bridged traffic

```bash
cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF

sudo modprobe overlay
sudo modprobe br_netfilter

# sysctl params required by setup, params persist across reboots
cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF

# Apply sysctl params without reboot
sudo sysctl --system
```

Проверяем:

```bash
lsmod | grep br_netfilter
lsmod | grep overlay

sysctl net.bridge.bridge-nf-call-iptables net.bridge.bridge-nf-call-ip6tables net.ipv4.ip_forward
```

Ставим ContainerD по [инструкции](https://docs.docker.com/engine/install/ubuntu/) с официального сайта:

```
# Add Docker's official GPG key:
sudo apt-get update
sudo apt-get install ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

# Add the repository to Apt sources:
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt-get update

sudo apt-get install containerd.io

systemctl status containerd
```

On Linux, control groups are used to constrain resources that are allocated to processes.

Both the kubelet and the underlying container runtime need to interface with control groups to enforce resource management for pods and containers and set resources such as cpu/memory requests and limits. To interface with control groups, the kubelet and the container runtime need to use a cgroup driver. **It's critical that the kubelet and the container runtime use the same cgroup driver and are configured the same**.

There are two cgroup drivers available:
- cgroupfs
- systemd

Если в ОС используется система инициализации systemd, тогда вам нужно использовать systemd cgroup driver.

Проверить какая система инициализации используется: `ps -p 1`.

Удаляем содержимое файла `/etc/containerd/config.toml` и добавляем следующее (не вариант, контейнеры начинают циклически падать через некоторое время):

```bash
[plugins."io.containerd.grpc.v1.cri".containerd.runtimes.runc]
  [plugins."io.containerd.grpc.v1.cri".containerd.runtimes.runc.options]
    SystemdCgroup = true
```

Используем вариант из Hard Way, создаем дефолтный конфиг и включаем systemd cgroup driver:

`containerd config default | sed 's/SystemdCgroup = false/SystemdCgroup = true/' | sudo tee /etc/containerd/config.toml`

Перезапускаем службу: `sudo systemctl restart containerd`.

Настраиваем клиент crictl. Прописываем endpoint-ы в файле `/etc/crictl.yaml`:

```
runtime-endpoint: unix:///var/run/containerd/containerd.sock
image-endpoint: unix:///var/run/containerd/containerd.sock
timeout: 0
debug: false
pull-image-on-create: false
disable-pull-on-run: false
```

### Installing kubeadm, kubelet and kubectl

```bash
sudo apt-get update
# apt-transport-https may be a dummy package; if so, you can skip that package
sudo apt-get install -y apt-transport-https ca-certificates curl gpg

# If the folder `/etc/apt/keyrings` does not exist, it should be created before the curl command, read the note below.
# sudo mkdir -p -m 755 /etc/apt/keyrings
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.29/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg

# This overwrites any existing configuration in /etc/apt/sources.list.d/kubernetes.list
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.29/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list

sudo apt-get update
sudo apt-get install -y kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl
```

Далее инициализируем control plane, выполняем только на мастере:

`sudo kubeadm init --pod-network-cidr=10.244.0.0/16 --apiserver-advertise-address=MASTER_NODE_IP`

Создаем kubeconfig:

```bash
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
```

Ставим CNI Weave.

Скачиваем манифест weave: `wget https://github.com/weaveworks/weave/releases/download/v2.8.1/weave-daemonset-k8s.yaml`.

И прописываем для контейнера `weave` необходимую переменную `IPALLOC_RANGE` (по умолчанию ее там нет):

```yaml
      containers:
        - name: weave
          env:
            - name: IPALLOC_RANGE
              value: 10.244.0.0/16
```

Применяем манифест через команду apply.

Далее подключаем к мастеру worker-ноды.

Если потеряли команду join, то сгенерировать заново можно так: `kubeadm token create --print-join-command`.

Выполняем на каждой worker-ноде:

`sudo kubeadm join 192.168.56.11:6443 --token h45kmq.ofvxgdeqtyrphk5f --discovery-token-ca-cert-hash sha256:f50e91a12b95071fdefbe5af01f277adcf39f88471c8b4a4280814f05274310c`

Готово, можно пробовать запускать тестовый pod.

