Когда один сервис пытается достучаться до другого и по какой-либо причине не может, мы можем настроить VirtualService, чтобы он повторил операцию снова. При таком подходе вам не нужно обрабатывать повторные попытки подключения в коде самого приложения. Вы можете сконфигурировать настройку `retries`, которая по сути сообщает количество повторных попыток и интервал между ними.

Istio по умолчанию настроено на две повторные попытки прежде чем вернуть ошибку и 25 мс задержки между повторами.

Подобно таймаутам повторные попытки подключения настраиваются на уровне VirtualService:

```yaml
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: my-service
spec:
  hosts:
  - my-service
  http:
  - route:
    - destination:
        host: my-service
        subset: v1
    retries:
      attempts: 3
      perTryTimeout: 2s
```