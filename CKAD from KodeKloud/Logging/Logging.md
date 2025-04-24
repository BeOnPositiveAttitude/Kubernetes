Например в Docker-е у нас есть контейнер, который генерирует логи:

```shell
docker run -d kodekloud/event-simulator
```

Смотреть логи контейнера в реальном времени:

```shell
docker logs -f container_id
```

Создадим pod из файла `event-simulator.yaml` и посмотрим его логи в реальном времени:

```shell
kubectl logs -f event-simulator-pod
```

Если в pod-е несколько контейнеров, то для просмотра логов мы должны явно указать имя контейнера:

```shell
kubectl logs -f event-simulator-pod -c event-simulator
```

Предположим у нас есть Deployment с двумя pod-ами, и мы хотим посмотреть логи сразу двух этих pod-ов. В этом случае можно указать общий для этих **pod-ов** label:

```shell
kubectl logs -l app=nginx
```

Можно смотреть логи deployment:

```shell
kubectl logs deploy/frontend
```

Если наше приложение по каким-либо причинами не выводит временные метки в лог, то мы можем добавить их самостоятельно:

```shell
kubectl logs event-simulator-pod --timestamps
```

Посмотреть лог за последние секунды/минуты/часы:

```shell
kubectl logs event-simulator-pod --since=5s
kubectl logs event-simulator-pod --since=30m
kubectl logs event-simulator-pod --since=1h
```