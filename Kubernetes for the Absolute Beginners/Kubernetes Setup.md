## Установка для Ubuntu:
Устанавливаем VirtualBox, добавляем текущего юзера в группу vboxusers:

`sudo usermod -a -G vboxusers $USER`

Перезагружаем ОС

Запускаем конфигурирование модулей ядра для VirtualBox:

`sudo /sbin/vboxconfig`

Устанавливаем Vagrant (потребуется VPN)

Клонируем репозиторий Kodekloud:

`git clone git@github.com:kodekloudhub/certified-kubernetes-administrator-course.git`

Переходим в папку с проектом и выполняем команду:

`vagrant status`

Поднять машины:

`vagrant up`

Залогиниться по SSH на мастер ноду:

`vagrant ssh kubemaster`

Проверяем модули ядра:

`lsmod | grep br_netfilter`

Если вывод команды выше пустой, то загружаем модуль ядра на всех нодах кластера:

`sudo modprobe br_netfilter`

Выполняем на всех нода кластера команды:

`cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
EOF
sudo sysctl --system`

Далее ставим Docker, переключаемся в root-а и выполняем на всех нодах:

`sudo apt-get update && sudo apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    software-properties-common \
    gnupg2`

Добавляем ключи:

`curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -`

Добавляем репозиторий:

`add-apt-repository \
   "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
   $(lsb_release -cs) \
   stable"`

Ставим Docker:

`apt-get update && apt-get install -y containerd.io=1.2.13-1 docker-ce=5:19.03.8~3-0~ubuntu-$(lsb_release -cs) docker-ce-cli=5:19.03.8~3-0~ubuntu-$(lsb_release -cs)`

Настройки для демона Docker:

`cat > /etc/docker/daemon.json <<EOF
{
  "exec-opts": ["native.cgroupdriver=systemd"],
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m"
  },
  "storage-driver": "overlay2"
}
EOF`

Создаем директорию:

`mkdir -p /etc/systemd/system/docker.service.d`

Перезагружаем сервисы:

`systemctl daemon-reload
systemctl restart docker`

Ставим компоненты Kubernetes:

`sudo apt-get update && sudo apt-get install -y apt-transport-https curl
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
cat <<EOF | sudo tee /etc/apt/sources.list.d/kubernetes.list
deb https://apt.kubernetes.io/ kubernetes-xenial main
EOF
sudo apt-get update
sudo apt-get install -y kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl`

Выполняем команду:

`rm /etc/containerd/config.toml && systemctl restart containerd`

Выполняем инциализацию кластера (на мастер ноде):

`kubeadm init --pod-network-cidr 10.244.0.0/16 --apiserver-advertise-address=192.168.56.2`

Указали сеть для pod-ов и адрес apiserver (расположен на мастер ноде)


