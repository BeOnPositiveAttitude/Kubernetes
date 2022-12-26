Например в Docker-е у нас есть контейнер, который генерирует логи:

`docker run -d kodekloud/event-simulator`

Смотреть логи контейнера в реальном времени:

`docker logs -f container_id`

Создадим pod из файла event-simulator.yaml и посмотрим его логи в реальном времени:

`kubectl logs -f event-simulator-pod`

Если в pod-е несколько контейнеров, то для просмотра логов мы должны явно указать имя контейнера:

`kubectl logs -f event-simulator-pod -c event-simulator`