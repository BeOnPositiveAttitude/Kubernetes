Опубликовать приложение в pod-е redis на порт 6379, имя Service - redis-service, тип Service - ClusterIP (по умолчанию):

`kubectl expose pod redis --port=6379 --name redis-service`

При таком способе labels pod-а будут автоматически использованы в селекторе Service, что очень удобно

Создать Deployment с тремя репликами:

`kubectl create deployment webapp --image=kodekloud/webapp-color --replicas=3`

Создать pod и опубликовать с помощью Service:

`kubectl run httpd --image=httpd:alpine --port=80 --expose`

Создать Service с именем redis и типом ClusterIP:

`kubectl create service clusterip redis --tcp=6379:6379`

При таком способе labels pod-а не будут использованы в селекторе Service, а вместо этого будут приняты 'app=redis'.
При создании Service командой нельзя передать опцию селектора.
Таким образом, если labels вашего pod-а отличаются, то это не лучший способ публиковать приложение.
Рекомендуется сгенерировать definition файл и указать селектор там.

Опубликовать приложение в pod-е nginx, порт в pod-е - 80, имя Service - nginx-service, тип Service - NodePort

`kubectl expose pod nginx --port=80 --name nginx-service --type=NodePort`

labels pod-а будут автоматически использованы в селекторе Service, но в команде нельзя задать определенное значение NodePort.
Рекомендуется сгенерировать definition файл и указать номер порта на ноде там.

Либо мы можем создать Service командой ниже и тут доступно указание порта на ноде:

`kubectl create service nodeport nginx --tcp=80:80 --node-port=30080`

Однако стоит помнить, что при таком способе labels pod-а не будут использованы в селекторе Service