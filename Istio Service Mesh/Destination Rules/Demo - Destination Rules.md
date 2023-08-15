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

Теперь перейдем в VirtualService `reviews` и т.к. мы только что удалили старые subsets `version: v2` и `version: v3`, Kiali предупредит нас, окрашивая в желтый цвет соответствующие строки. Оставим только `subset: v1` и добавим новый `subset: beta` как единый destination. Также необходимо указать каким образом управлять трафиком между ними.

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
            subset: beta
          weight: 10
```