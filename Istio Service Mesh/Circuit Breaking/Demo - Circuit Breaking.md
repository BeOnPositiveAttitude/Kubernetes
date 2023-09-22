Давайте создадим circuit breaker (автоматический выключатель) для предотвращения отказа наших сервисов, в момент когда они находятся под высокой нагрузкой.

Для этого в первую очередь удалим все subsets из Destination Rule и Virtual Service `productpage`:

```yaml
apiVersion: networking.istio.io/v1alpha3
kind: DestinationRule
metadata:
  name: productpage
spec:
  host: productpage
#   subsets:
#   - name: v1
#     labels:
#       version: v1
```

```yaml
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: productpage
spec:
  hosts:
  - productpage
  http:
  - route:
    - destination:
        host: productpage
        # subset: v1
```

Далее настроим наши политики для трафика со строгими правилами. В секции `http` мы говорим Istio ограничить максимальное количество соединений к нашему сервису до одного. Опцией `http1MaxPendingRequests` мы определяем количество запросов, которые мы будем продолжать ждать, если наш сервис занят, остальные будут отклонены. Опция `maxRequestsPerConnection` определяет как много запросов наш сервис может обработать из расчета на одно соединение.

```yaml
apiVersion: networking.istio.io/v1alpha3
kind: DestinationRule
metadata:
  name: productpage
spec:
  host: productpage
  trafficPolicy:
    connectionPool:
      http:
        http1MaxPendingRequests: 1
        maxRequestsPerConnection: 1
      tcp:
        maxConnections: 1
```

Теперь давайте попробуем посмотреть как это работает с помощью утилиты `h2load`, которая также будет полезна в создании одновременных вызовов.

Команда для запуска: `h2load -n1000 -c1 'http://'"$INGRESS_HOST"':'"$INGRESS_PORT"'/productpage'`.

Здесь опция `-n` показывает количество запросов, опция `-c` показывает количество одновременных клиентов. Давайте попробуем сделать 1000 вызовов к сервису Product Page. При работе утилиты мы можем увидеть прогресс в процентах. По итогу видим, что все наши запросы был успешно обработаны нашим сервисом.

Давайте добавим еще немного.

Теперь зададим два одновременных клиента: `h2load -n1000 -c2 'http://'"$INGRESS_HOST"':'"$INGRESS_PORT"'/productpage'`.

Если наш сервис зависнет с одним запросом, оставшиеся будут отклонены. По итогу видим всего 14 отклоненных запросов (failed).

Давайте попробуем увеличить количество одновременных клиентов до трех: `h2load -n1000 -c3 'http://'"$INGRESS_HOST"':'"$INGRESS_PORT"'/productpage'`.

Теперь в итоговом результате видим, что большая часть наших запросов была отклонена - 853 failed.

Увеличим количество одновременных клиентов до четырех: `h2load -n1000 -c4 'http://'"$INGRESS_HOST"':'"$INGRESS_PORT"'/productpage'`.

По итогу видим, что наш сервис смог обработать всего лишь 46 запросов.

На вкладке Graph в Kiali видим, что у сервиса Product Page имеются проблемы, из-за строго настроенного circuit breaker.