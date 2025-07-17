Gateway - это точка входа между внешним миром и Service Mesh. Gateway является опциональным (необязательным), если нет необходимости выставлять сервисы наружу (в public), то нет нужды включать Gateway, достаточно будет только Virtual Service.

Существует два типа Gateway. Ingress Gateway предназначен для управления входящим трафиком (трафик приходяший из внешнего мира в Service Mesh). Egress Gateway используется для управляения исходящим трафиком (трафик от сервисов внутри Service Mesh к внешним ресурсам).

По умолчанию Egress Gateway включен только в профиле "Demo". Однако мы можем настроить любой другой профиль и включить в нем Egress Gateway.

Pod-ы Ingress/Egress Gateway имеют соответствующие метки: `istio=ingress` и `istio=egress`.

Istio Gateway часто используется для терминации TLS. Он может управлять расшифровкой входящего и шифрованием исходяшего трафика, а также обрабатывать TLS-сертификаты. Istio Gateway может обрабатывать несколько протоколов в проходящем трафике - HTTP, HTTPS, TCP, gRPC.

Istio Gateway поддерживает HTTP/HTTPS-маршруты на основе заголовков, URL-путей, портов, а также поддерживаются TCP-соединения, что может быть очень полезно для сервисов основанных не на HTTP, например для баз данных.

gRPC-вызовы обычно используются для взаимодействия микросервисов в Istio, т.к. это как правило быстрее, чем REST API.

Освежим в памяти манифест нашего Virtual Service:

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
        subset: v1
      weight: 50
    - destination:
        host: app-svc.frontend.svc.cluster.local
        port:
          number: 80
        subset: v2
      weight: 50
```

И манфест для Destination Rule:

```yaml
apiVersion: networking.istio.io/v1
kind: DestinationRule
metadata:
  name: app-ds
  namespace: frontend
spec:
  host: app-svc
  subsets:
  - name: v1
    labels:
      version: v1
  - name: v2
    labels:
      version: v2
```

Предположим, что нам нужно выставить нашего приложение наружу, в public. Для этого нам понадобится Gateway:

```yaml
apiVersion: networking.istio.io/v1
kind: Gateway
metadata:
  name: ingress-app-gateway
  namespace: istio-system    # можно размещать в любом namespace
spec:
  selector:
    istio: ingress   # метка дефолтного ingress-gateway pod-а
  servers:
  - port:
      number: 80    # порт и протокол, на котором будет работать Gateway
      name: http
      protocol: HTTP
    hosts:
    - app.example.com   # заголовок Host в запросе пользователя, т.е. публичное имя хоста, к которому будут обращаться пользователи
```

Ingress Gateway должен иметь публичный IP-адрес.

Добавим `gateway` в манифест Virtual Service:

```yaml
apiVersion: networking.istio.io/v1
kind: VirtualService
metadata:
  name: app-vs
  namespace: frontend
spec:
  hosts:
  - app-svc              # имя хоста внутри Service Mesh
  - "app.example.com"    # public-имя хоста, по которому пользователи обращаются извне
  gateways:
  - ingress-app-gateway
  http:
  - match:
    - uri:
        prefix: /
    route:
    - destination:
        host: app-svc.frontend.svc.cluster.local
        port:
          number: 80
        subset: v1
      weight: 50
    - destination:
        host: app-svc.frontend.svc.cluster.local
        port:
          number: 80
        subset: v2
      weight: 50
```

<img src="image.png" width="1200" height="500"><br>

Ingress Gateway представляет собой всего лишь standalone Envoy Proxy.

Важно понимать, что для Ingress Gateway несомненно нужен Virtual Service для маршрутизации трафика. А вот для Virtual Service необязательно нужен Ingress Gateway. Virtual Service может работать независимо, ему даже не требуется Destination Rule.

Ниже представлена конфигурация Egress Gateway:

```yaml
apiVersion: networking.istio.io/v1
kind: Gateway
metadata:
  name: egress-app-gateway
  namespace: istio-system    # можно размещать в любом namespace
spec:
  selector:
    istio: egress   # метка дефолтного egress-gateway pod-а
  servers:
  - port:
      number: 80    # порт и протокол, на котором будет работать Gateway
      name: http
      protocol: HTTP
    hosts:
    - *             # разрешено обращаться к любому внешнем хосту
  - port:
      number: 443
      name: https
      protocol: HTTPS
    hosts:
    - *
```