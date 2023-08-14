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

Если пойти в Kiali, то новые Labels можно увидеть на вкладке "Workloads". Label `test: beta` появился в Deployment v2 и v3, но не в v1.