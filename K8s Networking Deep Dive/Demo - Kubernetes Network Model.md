### Environment Setup

Создадим два pod-а:

```yaml
---
apiVersion: v1
kind: Pod
metadata:
  name: pod1
spec:
  containers:
  - name: sleep1
    image: ubuntu
    command:
    - sleep
    - "7200"
  - name: sleep2
    image: ubuntu
    command:
    - sleep
    - "7200"
  - name: nginx
    image: nginx
---
apiVersion: v1
kind: Pod
metadata:
  name: pod2
spec:
  containers:
  - name: nginx
    image: nginx
```

### Exploring Network Namespaces on the Node

Посмотрим на namespace-ы, созданные на ноде:

```bash
$ lsns -t pid
        NS TYPE NPROCS   PID USER    COMMAND
<...>
4026533023 pid       1 23038 root    sleep 7200
4026533026 pid       2 23169 root    nginx: master process nginx -g daemon off;
4026533029 pid       1 23211 root    sleep 7200
4026533032 pid       2 23261 root    nginx: master process nginx -g daemon off;
```

- Колонка `NS` - namespace identifier (inode number)
- Параметр `-t, --type` - namespace type (mnt, net, ipc, user, pid, uts, cgroup, time)

Определим к каким сетевым namespace-ам относятся эти контейнерные процессы:

```bash
$ ip netns identify 23261
cni-8f553eed-9d76-101e-f3bf-a5a02f4e20a9
```

Имя namespace начинается с `cni`, т.к. он был создан с помощью CNI.

### Host Network Interfaces

On the node, view all interfaces:

```bash
$ ip addr
```

Filter for virtual Ethernet pairs (`veth`) created by CNI:

```bash
$ ip addr | grep -A1 veth
8:  vethwe-datapath@vethwe-bridge: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1376 …
    link/ether 56:4e:80:f3:fb:01 brd ff:ff:ff:ff:ff:ff
9:  vethwe-bridge@vethwe-datapath: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1376 …
    link/ether 4e:43:6f:73:1a:d7 brd ff:ff:ff:ff:ff:ff
```

Each `veth` pair connects a Pod's network namespace to the host or overlay network.

Определим к каким сетевым namespace-ам относятся контейнерные процессы:

```bash
$ for i in 23038 23169 23211 23261; do ip netns identify $i; done
cni-8f553eed-9d76-101e-f3bf-a5a02f4e20a9
cni-a8d1d5fa-16e2-2508-94fd-0832afebb8fc
cni-8f553eed-9d76-101e-f3bf-a5a02f4e20a9
cni-8f553eed-9d76-101e-f3bf-a5a02f4e20a9
```

Обратите внимание, что всего два уникальных namespace-а (т.к. два pod-а).

Посмотрим на сетевые интерфейсы в одном из namespace-ов (в котором три контейнера):

```bash
$ ip -n cni-8f553eed-9d76-101e-f3bf-a5a02f4e20a9 addr show
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN group default qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo
       valid_lft forever preferred_lft forever
    inet6 ::1/128 scope host
       valid_lft forever preferred_lft forever
3: eth0@if12: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UP group default
    link/ether 4e:0c:60:4d:09:04 brd ff:ff:ff:ff:ff:ff link-netnsid 0
    inet 192.168.0.7/32 scope global eth0
       valid_lft forever preferred_lft forever
    inet6 fe80::4c0c:60ff:fe4d:904/64 scope link
       valid_lft forever preferred_lft forever
```

Проверим в контейнере `sleep1` в `pod1`:

```bash
$ kubectl exec pod1 -c sleep1 -- ip addr show
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo
       valid_lft forever preferred_lft forever
    inet6 ::1/128 scope host
       valid_lft forever preferred_lft forever
3: eth0@if12: <BROADCAST,MULTICAST,UP,LOWER_UP,M-DOWN> mtu 1500 qdisc noqueue
    link/ether 4e:0c:60:4d:09:04 brd ff:ff:ff:ff:ff:ff
    inet 192.168.0.7/32 scope global eth0
       valid_lft forever preferred_lft forever
    inet6 fe80::4c0c:60ff:fe4d:904/64 scope link
       valid_lft forever preferred_lft forever
```

Проверим в контейнере `sleep2` в `pod1`:

```bash
$ kubectl exec pod1 -c sleep1 -- ip addr show
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo
       valid_lft forever preferred_lft forever
    inet6 ::1/128 scope host
       valid_lft forever preferred_lft forever
3: eth0@if12: <BROADCAST,MULTICAST,UP,LOWER_UP,M-DOWN> mtu 1500 qdisc noqueue
    link/ether 4e:0c:60:4d:09:04 brd ff:ff:ff:ff:ff:ff
    inet 192.168.0.7/32 scope global eth0
       valid_lft forever preferred_lft forever
    inet6 fe80::4c0c:60ff:fe4d:904/64 scope link
       valid_lft forever preferred_lft forever
```

Видим, что конфигурация одинаковая.