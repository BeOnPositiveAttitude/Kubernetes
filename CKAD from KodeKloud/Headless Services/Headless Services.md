Как мы знаем, чтобы сделать одно приложение доступным для другого по сети в K8s, нужно использовать Service.

Service работает как LoadBalancer, трафик пришедший на него, далее распределяется между всеми pod-ами в рамках Deployment.

Service имеет свой ClusterIP и DNS-имя. Тогда например pod с веб-сервером может использовать это DNS-имя, чтобы достучаться до pod-ов с БД MySQL.

Как мы знаем из предыдущего урока в MySQL reads могут обслуживаться и master-ом и slave-ми, а writes только master-ом. Соответственно веб-сервер может успешно прочитать данные из БД, но не сможет ничего записать в БД.

<img src="scheme.png" width="600" height="400"><br>

Как же нам настроить веб-сервер для обращения только к master-у? Мы не можем указать ip-адрес или dns-имя master pod-а, т.к. они динамически обновляются при пересоздании pod-а.

Нам нужен Service, который не будет балансировать приходящие запросы, но даст нам DNS-записи для доступа к каждому pod-у. Вот что такое Headless Service.

Headless Service создается как обычный Service, но он не имеет своего собственного IP, как например ClusterIP для обычного Service. Он не балансирует трафик, а только создает DNS-записи для каждого pod-а, используя имя pod-а и поддомен.

Таким образом, когда мы создаем Headless Service например с именем mysql-h, каждый pod получает dns-имя в формате:

`pod-name.headless-servicename.namespace.svc.cluster-domain.example`

Если взять пример из схемы выше, то dns-записи для pod-ов будут следующие:

```
mysql-0.mysql-h.default.svc.cluster.local
mysql-1.mysql-h.default.svc.cluster.local
mysql-2.mysql-h.default.svc.cluster.local
```

Теперь мы можем настроить веб-сервер на master pod - `mysql-0.mysql-h.default.svc.cluster.local`

Пример yaml-файла для Headless Service приведен в headless-service.yaml

От обычного Service он отличается опцией `clusterIP: None`

После создания Headless Service dns-записи для pod-ов будут созданы только если выполняются два условия:

- В pod definition файле необходимо указать поле `subdomain` со значением равным имени Headless Service. Когда вы сделаете это, будет создана DNS-запись для Headless Service - `mysql-h.default.svc.cluster.local`. Но DNS-записи для pod-ов все еще не будут созданы.
- В pod definition файле необходимо указать поле `hostname` со значением равным имени pod-а. Например `mysql-pod`. Только после этого будут созданы DNS-записи для pod-ов.

Рассмотрим пример с Deployment, файл deployment-definition.yaml

По умолчанию Deployment не добавляет опции `hostname` или `subdomain` для pod-ов, соответсвенно Headless Service не создаст DNS-записи для pod-ов. Мы можем указать эти опции вручную, но тогда одно и то же DNS-имя `mysql-pod.mysql-h.default.svc.cluster.local` будет создано для всех pod-ов, т.к. Deployment просто дублирует эти значения для всех pod-ов.

И вот где StatefulSet выгодно отличается от Deployment. Пример в файле statefulset-definition.yaml.

В StatefulSet нет необходимости вручную указывать опции `hostname` или `subdomain` для pod-ов, он автоматически назначает `hostname`, основываясь на имени pod-а, и `subdomain`, основываясь на имени Headless Service. Как StatefulSet узнает какой Headless Service использовать? Для этого есть специальная опция `serviceName`.