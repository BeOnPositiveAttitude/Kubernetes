Контейнеры (также как и pod-ы) по своей природе носят временный характер, запускаются, выполняют необходимые задачи и умирают.

Соответственно данные в контейнерах также удаляются.

Чтобы сохранить эти данные, мы должны прикрепить volume к контейнеру в процессе его создания.

Пример использования volume в виде каталога на worker-ноде. Не рекомендуется использовать этот тип, если в кластере несколько нод, т.к. в этом случае указанная директория должна существовать на всех нодах кластера и иметь одинаковый контент.

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
    hostPath:
      path: /data
      type: Directory
```

Пример использования volume в AWS EBS:

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
    - mountPath: /opt     #куда volume будет смонтирован внутри контейнера
      name: data-volume   #имя volume из "списка" ниже
  volumes:
  - name: data-volume
    awsElasticBlockStore:
      volumeID: <volume-id>
      fsType: ext4
```