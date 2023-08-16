В этом уроке мы создадим несколько различных subsets, используя Destination Rules и направим трафик на эти service endpoints, сгруппированные вместе. Перед этим давайте посмотрим на уже существующие Destination Rules для проверки.

Мы имеем три разных subsets и они ссылаются на Labels `version: v1`, `version: v2` и `version: v3`.

```yaml
...
spec:
  host: reviews
  subsets:
    - labels:
        version: v1
      name: v1
    - labels:
        version: v2
      name: v2
    - labels:
        version: v3
      name: v3
```

В Virtual Service мы просто используем эти subsets для маршрутизации нашего трафика.

```yaml
...
spec:
  hosts:
    - reviews
  http:
    - match:
        - headers:
            end-user:
              exact: kodekloud
      route:
        - destination:
            host: reviews
            subset: v2
    - match:
        - headers:
            end-user:
              exact: testuser
      route:
        - destination:
            host: reviews
            subset: v3
    - route:
        - destination:
            host: reviews
            subset: v1
```

Но что, если нам однажды понадобится сгруппировать разные Deployments под одним и тем же Service с другим правилом или Label? Чтобы это сделать, сначала нам нужно добавить новый Label для нашего приложения. Этот новый Label поможет нам создать несколько различных Destination Rules. Скопируем секцию, относящуюся к Reviews из файла `samples/bookinfo/platform/kube/bookinfo.yaml`. Пример в файле `reviews.yaml`. Добавим новый Label `test: beta`. Пропускаем наш первый Deployment, т.к. не хотим видеть версию v1 в новой группировке.

Удалим `kubectl delete -f reviews.yaml` и применим созданный манифест `kubectl apply -f reviews.yaml`.

Если пойти в Kiali, то новые Labels можно увидеть на вкладке "Workloads". Label `test: beta` появился в Deployment `reviews-v2` и `reviews-v3`, но не в `reviews-v1`.

На вкладке "Applications" мы можем увидеть, что новый Label также появился на нашем сервисе `reviews`.

Теперь давайте перейдем на вкладку "Istio Config" и создадим наш новый subset в DestinationRule `reviews`. Оставим subset `version: v1` и создадим новый subset `test: beta`. Это поможет нам протестировать две новые различные версии приложения и понять какая окажется предпочтительнее для заказчиков.

```yaml
...
spec:
  host: reviews
  subsets:
    - labels:
        version: v1
      name: v1
    - labels:
        test: beta
      name: test
```

Теперь перейдем в VirtualService `reviews` и т.к. мы только что удалили старые subsets `version: v2` и `version: v3`, Kiali предупредит нас, окрашивая в желтый цвет соответствующие строки. Оставим только `subset: v1` и добавим новый `subset: beta` как единый destination. Также необходимо указать каким образом управлять трафиком между ними. Направим на новую тестовую версию приложения всего лишь 10% от общего трафика.

```yaml
...
spec:
  hosts:
    - reviews
  http:
    - route:
        - destination:
            host: reviews
            subset: v1
          weight: 90
        - destination:
            host: reviews
            subset: test
          weight: 10
```

В браузере мы будем чаще всего видеть v1 и редко v2 и v3. Создадим поток трафика с помощью команды:

`while sleep 1 ; do curl -sS 'http://'"$INGRESS_HOST"':'"$INGRESS_PORT"'/productpage' &> /dev/null ; done`.

Переходим на вкладку "Istio Config", выбираем DR "reviews", далее нажимаем "Host" и видим распределение трафика. Запросов на v1 приходит в 9 раз больше, чем на v2 и v3.

Изменим распределение веса трафика в VirtualService "reviews" еще раз:

```yaml
...
spec:
  hosts:
    - reviews
  http:
    - route:
        - destination:
            host: reviews
            subset: v1
          weight: 10
        - destination:
            host: reviews
            subset: test
          weight: 90
```

Теперь в браузере чаще всего отображаются v2 и v3.

Также мы можем создать политику трафика для `subset: test` в DestinationRule "reviews". Это может быть random loadbalancer. Таким способом мы можем распределять трафик случайный образом в нашем subset.

```yaml
...
spec:
  host: reviews
  subsets:
    - labels:
        version: v1
      name: v1
    - labels:
        test: beta
      name: test
      trafficPolicy:
        loadBalancer:
          simple: RANDOM
```

Теперь в браузере версии v2 и v3 меняются в случайном порядке.

Мы можем удалить все созданные ранее subsets и попробовать другую политику трафика в DestinationRule "reviews".

```yaml
...
spec:
  host: reviews
  trafficPolicy:
    loadBalancer:
      simple: ROUND_ROBIN
```

Теперь все наши приложения Reviews будут работать в round-robin режиме.

Также необходимо удалить эти subsets из VirtualService "reviews".

```yaml
...
spec:
  hosts:
    - reviews
  http:
    - route:
        - destination:
            host: reviews
```

Теперь в браузере версии v1, v2 и v3 меняются в round-robin режиме.

Destination Rules в совокупности с Virtual Services помогают нам конфигурировать сложные политики управления трафиком.