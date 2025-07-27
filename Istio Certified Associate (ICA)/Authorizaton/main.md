Когда мы приходим на какое-либо мероприятие (спортивный матч, концерт и пр.), то при входе предъявляем билет и удостоверение личности. После входа на стадион мы не можем занять любое место. Мы садимся на место, указанное в билете.

Istio работает схожим образом. Как только вы прошли аутентификацию, то можете взаимодействовать с любым сервисом в Service Mesh. Однако можно создать сущность Authorization Policy, которая определяет что вы можете делать, а что нет.

Например сервис Inventory может делать POST-запросы к сервису Shoes на порт 80, но не может делать GET-запросы к сервису Users на порт 80.

<img src="image.png" width="600" height="300"><br>

Пример разрешающей политики авторизации:

```yaml
apiVersion: security.istio.io/v1beta1
kind: AuthorizationPolicy
metadata:
  name: payments-allow-pol
  namespace: payments
spec:
  action: ALLOW
  rules:
  - from:
    - source:
        namespaces: ["app"]
  - to:
    - operation:
        methods: ["POST"]
```

В данной конфигурации разрешаются POST-запросы из namespace `app` к любой нагрузке в namespace `payments`.

Пример запрещающей политики авторизации:

```yaml
apiVersion: security.istio.io/v1beta1
kind: AuthorizationPolicy
metadata:
  name: payments-deny-pol
  namespace: payments
spec:
  action: DENY
  rules:
  - from:
    - source:
        namespaces: ["app"]
  - to:
    - operation:
        methods: ["GET"]
        paths: ["/credit-cards-info"]
```

В данной конфигурации запрещаются GET-запросы на location `/credit-cards-info` из namespace `app` к любой нагрузке в namespace `payments`.

Политики авторизации могут быть достаточно сложными и запутанными.