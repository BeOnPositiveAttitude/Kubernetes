Любой pod имеет status жизненного цикла и несколько conditions.

Когда pod создается впервые он находится в статусе `Pending`, в этот момент scheduler пытается понять куда разместить pod. Если pod не удается никуда разместить, он так и остается в статусе `Pending`.

Когда pod определен на какую-либо ноду он переходит в статус `ContainerCreating`, где скачивается нужный образ и контейнер стартует.

Когда все контейнеры в pod-е запущены, pod переходит в статус `Running` до успешного завершения приложения или пока pod не будет уничтожен.

Conditions дополняют информацию о статусе pod-а. Conditions - это массив true/false значений, которые говорят нам о статусе pod-а.

- `PodScheduled` - если true, значит pod запланирован к размещение на ноде
- `Initialized` - если true, значит pod проинициализирован
- `ContainersReady` - если true, значит все контейнеры в pod-е готовы
- `Ready` - если true, значит сам pod готов, приложение внутри pod-а запущено и готово принимать пользовательский трафик

Смотреть conditions:

```shell
$ kubectl describe pod pod-name
```

Внутри pod-а может находиться скрипт, который выполняется за считанные миллисекунды, а может быть и "тяжелое" приложение (например Jenkins), инициализация и запуск которого занимает несколько минут, при этом сам pod уже давно находится в статусе `Ready`, что не совсем соответствует действительности.

Допустим мы опубликовали наше приложение в pod-е через Service, как только condition `Ready` нашего pod-а станет true, объект Service, опираясь на этот Condition, сразу начнет маршрутизировать трафик на наш pod.

Таким образом нам нужно определять, действительно ли Condition `Ready` нашего pod-а соответствует готовности приложения внутри pod-а?

Существуют различные вариант проверки готовности приложения, например HTTP-тест до API приложения, TCP-тест до определенного порта, запуск скрипта внутри контейнера, который проверяет статус приложения и успешно завершается в случае готовности.

В K8s существует механизм Readiness Probes, пример в файле `pod-definition.yaml`.

Пример проверки доступности API-ручки:

```yaml
apiVersion: v1
kind: Pod
metadata:
  labels:
    name: simple-webapp
  name: simple-webapp
spec:
  containers:
  - image: simple-webapp
    name: simple-webapp
    ports:
    - containerPort: 8080
    readinessProbe:
      httpGet:
        path: /api/ready
        port: 8080
      initialDelaySeconds: 10   # если мы точно знаем, что приложение поднимается минимум 10 секунд, то можем задать интервал задержки перед проверкой
      periodSeconds: 5          # как часто выполнять проверку
      failureThreshold: 8       # по умолчанию после 3 неудачных попыток проба останавливается, можем переопределить на большее число попыток
```

Пример проверки доступности TCP-порта БД:

```yaml
apiVersion: v1
kind: Pod
metadata:
  labels:
    name: simple-webapp
  name: simple-webapp
spec:
  containers:
  - image: simple-webapp
    name: simple-webapp
    ports:
    - containerPort: 8080
    readinessProbe:
      tcpSocket:
        port: 3306
```

Пример проверки успешности выполнения команды:

```yaml
apiVersion: v1
kind: Pod
metadata:
  labels:
    name: simple-webapp
  name: simple-webapp
spec:
  containers:
  - image: simple-webapp
    name: simple-webapp
    ports:
    - containerPort: 8080
    readinessProbe:
      exec:
        command:
        - cat
        - /app/is_ready
```

Таким образом до тех пор, пока не выполнится условие Readiness Probe, K8s не установит Condition `Ready` нашего pod-а в значение true. Соответственно Service не будет маршрутизировать трафик на наш pod, т.к. его статус еще не `Ready`.

Это особенно полезно в случае, когда у нас есть Deployment или ReplicaSet и несколько pod-ов, а также Service, который направляет пользовательский трафик на эти pod-ы.

Если мы захотим добавить новый pod, то без использования Readiness Probe сущность Service сразу начнет часть запросов направлять на новый pod, приложение в котором фактически еще не готово принимать трафик. Это приведет к деградации нашего приложения.

**Readiness Probe работает на протяжении всего жизненного цикла pod-а.**

Which of the following would be the result/state of a probe?

- SUCCESS
- UNKNOWN
- FAILURE