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
    image: busybox
    command:
    - sleep
    - "7200"
  - name: sleep2
    image: busybox
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

Посмотрим на namespace-ы, созданные на ноде:

```bash
$ lsns -t pid
        NS TYPE NPROCS   PID USER    COMMAND
<...>
4026533023 pid       1 42699 root    sleep 7200
4026533026 pid       2 42756 root    nginx: master process nginx -g daemon off;
4026533029 pid       1 42804 root    sleep 7200
4026533032 pid       2 42865 root    nginx: master process nginx -g daemon off;
```

`-t, --type` - namespace type (mnt, net, ipc, user, pid, uts, cgroup, time)

Определим к каким сетевым namespace-ам относятся эти контейнерные процессы:

```bash
$ ip netns identify 42865
cni-ac4a92c5-7634-7c7b-8345-c260af3827c2
```

Имя namespace начинается с `cni`, т.к. он был создан с помощью CNI.