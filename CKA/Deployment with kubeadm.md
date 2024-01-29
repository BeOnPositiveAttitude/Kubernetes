Инструкция по установке кластера с помощью kubeadm доступна по [ссылке](https://github.com/kodekloudhub/certified-kubernetes-administrator-course).

В Vagrantfile нужно добавить одну строку: `ENV['VAGRANT_SERVER_URL'] = 'https://vagrant.elab.pro'`.

[Ссылка](https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/install-kubeadm/) на официальную документацию.

Начинаем с установки Container Runtime.

Выполняем на всех нодах кластера.

## Forwarding IPv4 and letting iptables see bridged traffic

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