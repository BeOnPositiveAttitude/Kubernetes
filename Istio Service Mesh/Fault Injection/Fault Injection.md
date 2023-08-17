На текущий момент мы развернули приложение, настроили Gateway, сконфигурировали Virtual Services `productpage` и `reviews`. Все работает как ожидается.

Далее мы хотим добавить некоторое количество ошибок, чтобы проверить, что механизм обработки ошибок работает так как ожидается. Это и называется "Fault Injection". Это подход для тестирования. Он помогает нам увидеть эффективно ли запускаются наши политики и не слишком ли они ограничивающие.

Мы можем ввести ошибки в наши Virtual Services, и это могут быть два типа ошибок - delays и aborts.

В примере ниже мы вводим в Mesh ошибки типа delay для VirtualService `ratings`. Он описывается в процентах и будет добавлять задержку для 10% запросов. Эта задержка настроена на значение 5 секунд.

```yaml
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: my-service
spec:
  hosts:
    - my-service
  http:
  - fault:
      delay:
        percentage:
          value: 0.1
        fixedDelay: 5s
    route:
    - destination:
        host: my-service
        subset: v1
```

Кроме delay вы можете настроить abort для имитации ошибок, когда запрос отклоняется и возвращается определенный код ошибки.

```yaml
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: my-service
spec:
  hosts:
    - my-service
  http:
  - fault:
      abort:
        percentage:
          value: 0.1
        httpStatus: 400
    route:
    - destination:
        host: my-service
        subset: v1
```