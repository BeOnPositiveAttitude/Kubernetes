Destination Rules применяют политики маршрутизации после того как трафик смаршрутизирован на определенный сервис.

Ранее мы говорили о Virtual Services и каким образом сервис Reviews может быть сконфигурирован с помощью VirtualService для распределения определенного процента трафика на разные версии. Мы знаем, что 99% трафика посылается на subset v1 и 1% трафика посылается на subset v2.

```yaml
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: reviews
spec:
  hosts:
    - reviews
  http:
  - route:
    - destination:
        host: reviews
        subset: v1
      weight: 99
    - destination:
        host: reviews
        subset: v2
      weight: 1
```

Где и как определяются эти subsets? Subsets определяются в Destination Rules. Мы создаем объект с типом DestinationRule, задаем имя `reviews-destination` и host `reviews`. Далее мы определяем два subsets - v1 и v2, а также указываем Labels под ними.

```yaml
apiVersion: networking.istio.io/v1alpha3
kind: DestinationRule
metadata:
  name: reviews-destination
spec:
  host: reviews
  subsets:
  - name: v1
    labels:
      version: v1
  - name: v2
    labels:
      version: v2
```

Мы задали версии Version 1 и Version 2 соответственно. Это Labels, установленные на pod-ах для соответствующей версии Deployment `reviews`.

Вот как мы определяем отдельное подмножество (subset) сервисов, чтобы