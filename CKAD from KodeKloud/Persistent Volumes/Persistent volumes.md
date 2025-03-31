В уроке "Volumes in Kubernetes" мы создавали volume в рамках pod definition файла.

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: random-number-generator
spec:
  containers:
  - name: alpine
    image: alpine
    command: ["/bin/sh","-c"]
    args: ["shuf -i 0-100 -n 1 >> /opt/number.out;"]
    volumeMounts:
    - mountPath: /opt     # куда volume будет смонтирован внутри контейнера
      name: data-volume   # имя volume из списка ниже
  volumes:
  - name: data-volume
    hostPath:            # директория на ноде, не рекомендуется использовать этот тип, если в кластере несколько нод, т.к. в этом случае указанная папка должна существовать на всех нодах кластера и иметь одинаковый контент
      path: /data
      type: Directory
```

Which statements best describe `hostPath` volume type? You either need to run your process as `root` in a privileged container or modify the file permissions on the host to be able to write to a `hostPath`.

Когда у нас большая инфрастуктура с множеством пользователей, разворачивающих большое количество pod-ов, каждый пользователь будет вынужден конфигурировать storage для каждого pod-а в рамках своего pod definition файла.

Плюс каждый раз, когда будет происходить изменение storage, пользователи должны будут внести соответствующие изменения во всех pod-ах.

Вместо этого нам бы хотелось управлять storage более централизованно.

Например администратор создал бы объемный пул storage, а пользователи "отрезали" от него кусочки по мере необходимости.

Здесь нам приходит на помощь Persistent Volumes - cluster wide pool of storage volumes, настроенный администратором для использования юзерами, разворачивающими приложения в кластере.

Пользователи могут выбирать storage из пула, используя Persistent Volume Claims (PVC).

Пример PV:

```yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: pv-vol1
spec:
  accessModes:
  - ReadWriteOnce   # как volume должен быть смонтирован на хосте, может быть еще ReadOnlyMany, ReadWriteMany
  capacity:
    storage: 1Gi
  hostPath:         # этот тип storage не рекомендуется использовать в prod-е
    path: /tmp/data
```

Смотреть Persistent Volumes: `kubectl get pv`.

### Access Modes

- `ReadWriteOnce` - the volume can be mounted as **read-write** by a **single** node. `ReadWriteOnce` access mode still can allow multiple pods to access (read from or write to) that volume when the pods are running on the same node.
- `ReadOnlyMany` - the volume can be mounted as **read-only** by **many** nodes.
- `ReadWriteMany` - the volume can be mounted as **read-write** by **many** nodes.
- `ReadWriteOncePod` - the volume can be mounted as **read-write** by a **single** Pod. Use `ReadWriteOncePod` access mode if you want to ensure that only one pod across the whole cluster can read that PVC or write to it.