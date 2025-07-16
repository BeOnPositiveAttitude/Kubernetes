Virtual Services позволяет конфгурировать правила маршрутизации трафика для наших K8s-сервисов.

Предположим у нас есть простой Deployment:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: app-deployment
  namespace: frontend
spec:
  replicas: 1
  <...>
  template:
    metadata:
      labels:
        app: app
    spec:
      containers:
      - name: app
        image: app:1.1
```

И Service:

```yaml
apiVersion: v1
kind: Service
metadata:
  name: app-svc
  namespace: frontend
spec:
  ports:
    - port:80
      name: http
  selector:
    app: spp
```

Пример простого Virtual Service:

```yaml
apiVersion: networking.istio.io/v1
kind: VirtualService
metadata:
  name: app-vs
  namespace: frontend
spec:
  hosts:
  - app-svc   # The address used by a client when attempting to connect to a service
  http:
  - match:
    - uri:
        prefix: /
    route:
    - destination:
        host: app-svc.frontend.svc.cluster.local
        port:
          number: 80
  - match:
    - uri:
        prefix: /login
    rewrite:
      uri: /
    route:
    - destination:
        host: app-svc.frontend.svc.cluster.local
        port:
          number: 80
```

Зачем использовать Virtual Services, если есть стандартный объект Service? Стандартный Service не дает нам возможности управления трафиком на уровне L7.

<img src="image.png" width="800" height="350"><br>

<img src="image-1.png" width="800" height="250"><br>

Документация: https://istio.io/latest/docs/reference/config/networking/virtual-service/

### Demo

Ставим и включаем istio для namespace `default`, разворачиваем в нем приложение httpbin.

```shell
$ kubectl apply -f https://raw.githubusercontent.com/istio/istio/refs/heads/master/samples/httpbin/httpbin.yaml
```

Создаем тестовый namespace и нагрузку внутри него:

```shell
$ kubectl create ns test
$ kubectl -n test run test --image=nginx
```

Подключимся к тестовому pod-у и проверим доступность сервиса `httpbin`:

```
$ kubectl -n test exec -it test -- /bin/bash

root@test:/# curl -I httpbin.default.svc.cluster.local:8000
HTTP/1.1 200 OK
access-control-allow-credentials: true
access-control-allow-origin: *
content-security-policy: default-src 'self'; style-src 'self' 'unsafe-inline'; img-src 'self' camo.githubusercontent.com
content-type: text/html; charset=utf-8
date: Wed, 16 Jul 2025 09:58:29 GMT
x-envoy-upstream-service-time: 1
server: istio-envoy
x-envoy-decorator-operation: httpbin.default.svc.cluster.local:8000/*
transfer-encoding: chunked

root@test:/# curl httpbin.default.svc.cluster.local:8000/ip
{
  "origin": "127.0.0.6:48335"
}

root@test:/# curl httpbin.default.svc.cluster.local:8000/user-agent
{
  "user-agent": "curl/7.88.1"
}
```

Создадим Virtual Service:

```yaml
apiVersion: networking.istio.io/v1beta1
kind: VirtualService
metadata:
  name: httpbin
  namespace: default
spec:
  hosts:
  - httpbin
  http:
  - match:
    - uri:
        prefix: /
    route:
    - destination:
        host: httpbin.default.svc.cluster.local
        port:
          number: 8000
```

Вновь подключимся к тестовому pod-у и проверим доступность сервиса `httpbin`:

```
$ kubectl -n test exec -it test -- /bin/bash

root@test:/# curl httpbin.default.svc.cluster.local:8000/ip
{
  "origin": "127.0.0.6:53759"
}
```

Все работает. Попробуем сломать. Изменим порт  на 9000:

```yaml
apiVersion: networking.istio.io/v1beta1
kind: VirtualService
metadata:
  name: httpbin
  namespace: default
spec:
  hosts:
  - httpbin
  http:
  - match:
    - uri:
        prefix: /
    route:
    - destination:
        host: httpbin.default.svc.cluster.local
        port:
          number: 9000
```

Вновь подключимся к тестовому pod-у и проверим доступность сервиса `httpbin`:

```
$ kubectl -n test exec -it test -- /bin/bash

root@test:/# curl httpbin.default.svc.cluster.local:8000/ip
{
  "origin": "127.0.0.6:40567"
}
```

Все равно работает! Почему? Дело в том, что для namespace `test` не включен istio sidecar, поэтому трафик беспрепятственно ходит к namespace `default` (видимо минуя service mesh).

Включим istio injection для namespace `test`:

```shell
$ kubectl label ns test istio-injection=enabled
```

Пересоздадим тестовый pod:

```shell
$ kubectl -n test delete po test
$ kubectl -n test run test --image=nginx
```

Вновь подключимся к тестовому pod-у и проверим доступность сервиса `httpbin`:

```
$ kubectl -n test exec -it test -- /bin/bash

root@test:/# curl -I httpbin.default.svc.cluster.local:8000
HTTP/1.1 503 Service Unavailable
date: Wed, 16 Jul 2025 10:19:50 GMT
server: envoy
transfer-encoding: chunked
```

Не работает, т.к. трафик теперь перехватывается Virtual Service и отправляется на порт 9000, который не слушается сервисом. Починим:

```yaml
apiVersion: networking.istio.io/v1beta1
kind: VirtualService
metadata:
  name: httpbin
  namespace: default
spec:
  hosts:
  - httpbin
  http:
  - match:
    - uri:
        prefix: /
    route:
    - destination:
        host: httpbin.default.svc.cluster.local
        port:
          number: 8000
```

Вновь подключимся к тестовому pod-у и проверим доступность сервиса `httpbin`:

```
$ kubectl -n test exec -it test -- /bin/bash

root@test:/# curl httpbin.default.svc.cluster.local:8000/ip
{
  "origin": "127.0.0.6:46165"
}
```

Теперь посмотрим на работу rewrite. Вновь подключимся к тестовому pod-у и проверим доступность несуществующего location:

```
$ kubectl -n test exec -it test -- /bin/bash

root@test:/# curl httpbin.default.svc.cluster.local:8000/hello
404 page not found
```

Настроим rewrite:

```yaml
apiVersion: networking.istio.io/v1beta1
kind: VirtualService
metadata:
  name: httpbin
  namespace: default
spec:
  hosts:
  - httpbin
  http:
  - match:
    - uri:
        prefix: /hello
    rewrite:
      uri: /
    route:
    - destination:
        host: httpbin.default.svc.cluster.local
        port:
          number: 8000
  - match:
    - uri:
        prefix: /
    route:
    - destination:
        host: httpbin.default.svc.cluster.local
        port:
          number: 8000
```

Вновь подключимся к тестовому pod-у и проверим доступность несуществующего location:

```
$ kubectl -n test exec -it test -- /bin/bash

root@test:/# curl httpbin.default.svc.cluster.local:8000/hello  
<!DOCTYPE html>
<html>
<head>
  <meta http-equiv='content-type' value='text/html;charset=utf8'>
  <...>
```

Нас перенаправило на корневой localtion.