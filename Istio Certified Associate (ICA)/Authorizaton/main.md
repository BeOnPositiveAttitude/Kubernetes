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
    to:
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
    to:
    - operation:
        methods: ["GET"]
        paths: ["/credit-cards-info"]
```

В данной конфигурации запрещаются GET-запросы на location `/credit-cards-info` из namespace `app` к любой нагрузке в namespace `payments`.

Политики авторизации могут быть достаточно сложными и запутанными.

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
        principals: ["cluster.local/ns/identity/sa/app"]   # разрешено ИЛИ от service account "app" в namespace "identity"
    - source:
        namespaces: ["app"]   # ИЛИ от чего угодно в namespace "app"
    to:
    - operation:
        methods: ["GET"]
        paths: ["/data"]
    - operation:
        methods: ["POST"]
        paths: ["/purchases"]
    when:
    - key:
      values: ["https://accounts.google.com"]   # если от google-аккаунта
```

Возможно вы задались вопросом - а зачем вообще использовать Authorization Policies, если есть встроенные в K8s Network Policies?

Network Policies работают на уровнях L3-L4 модели OSI.

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: payments-allow-pol
  namespace: payments
spec:
  podSelector:
    matchLabels:
      app: payments
  policyTypes:
  - Ingress
  ingress:
  - from:
    - namespaceSelector:
        matchLabels:
          app: app
    ports:
    - protocol: TCP
      port: 8080
```

В данном примере разрешается входящий трафик от любого pod-а, находящегося в namespace `app`, на порт 8080. Здесь не учитываются запрашиваемые пути, методы и т.д.

Теперь посмотрим на схожую Authorization Policy:

```yaml
apiVersion: security.istio.io/v1beta1
kind: AuthorizationPolicy
metadata:
  name: payments-allow-pol
  namespace: payments
spec:
  action: ALLOW
  rules:
  - selector:
      matchLabels:
        app: payments
  - from:
    - source:
        namespaces: ["app"]
    to:
    - operation:
        methods: ["GET"]
        paths: ["/api"]
        ports: ["8080"]
```

В данном примере также разрешается входящий трафик от любого pod-а, находящегося в namespace `app`, на порт 8080, но только с использованием метода GET и на location `/api`. В этом заключается главное отличие от Network Policies. Authorization Policies работает на уровне L7 модели OSI.

<img src="image-1.png" width="800" height="300"><br>

Документация:

https://istio.io/latest/docs/reference/config/security/authorization-policy/

https://istio.io/latest/docs/tasks/security/authorization/

### Demo

### Demo Timeouts

Ставим и включаем istio для namespace `default`, разворачиваем в нем приложение httpbin.

```shell
$ kubectl apply -f https://raw.githubusercontent.com/istio/istio/refs/heads/master/samples/httpbin/httpbin.yaml
```

Создаем новый namespace и тестовый pod внутри него:

```shell
$ kubectl create ns test
$ kubectl -n test run test --image=nginx
```

Включаем Istio Injection на созданном namespace:

```shell
$ kubectl label ns test istio-injection=enabled
```

Проверим доступность сервиса `httpbin` из тестового pod-а:

```bash
$ kubectl -n test exec -it test -- curl -I http://httpbin.default.svc.cluster.local:8000

```

Включим mTLS глобально на уровне всего Service Mesh (*mesh-wide policy*):

```yaml
apiVersion: security.istio.io/v1beta1
kind: PeerAuthentication
metadata:
  name: default
  namespace: istio-system
spec:
  mtls:
    mode: STRICT
```

Создадим политику авторизации:

```yaml
apiVersion: security.istio.io/v1beta1
kind: AuthorizationPolicy
metadata:
  name: httpbin-auth-policy
  namespace: default
spec:
  action: ALLOW
  rules:
  - from:
    - source:
        namespaces: ["test"]
    to:
    - operation:
        methods: ["GET"]
```