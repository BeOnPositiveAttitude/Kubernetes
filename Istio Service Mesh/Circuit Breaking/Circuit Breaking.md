Мы знаем, что сервис Product Page взаимодействует с другими сервисами, например Reviews и Details. Если по каким-либо причинам сервис Details упал либо начал тормозить и не в состоянии обслуживать сервис Product Page, тогда все запросы от сервиса Product Page будут скапливаться в очереди к сервису Details, по сути создавая задержку, т.к. сервис Product Page будет ждать ответа от сервиса Details.

В таких случаях мы хотели бы маркировать запросы как неуспешные сразу же после их отправки сервису Details. Это известно как Circuit Breaking и позволяет нам создавать устойчивые микросервисные приложения, которые позволяют нам ограничивать влияние сбоев или других сетевых проблем.

То же самое верно, если мы хотим ограничить количество запросов, приходящих к самой Product Page.

Circuit Breakers настраиваются внутри Destination Rules. В данном примере мы ограничили число конкурентных подключений до трех:

```yaml
apiVersion: networking.istio.io/v1alpha3
kind: DestinationRule
metadata:
  name: productpage
spec:
  host: productpage
  subsets:
  - name: v1
    labels:
      version: v1
    trafficPolicy:
      connectionPool:
        tcp:
          maxConnections: 3
```