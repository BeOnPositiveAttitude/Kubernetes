Опубликовать приложение в pod-е redis на порт 6379, имя Service - redis-service, тип Service - ClusterIP (по умолчанию):

`kubectl expose pod redis --port=6379 --name redis-service`

Создать Deployment с тремя репликами:

`kubectl create deployment webapp --image=kodekloud/webapp-color --replicas=3`

Создать pod и опубликовать с помощью Service:

`kubectl run httpd --image=httpd:alpine --port=80 --expose`

Создать Service с именем redis и типом ClusterIP:

`kubectl create service clusterip redis --tcp=6379:6379`