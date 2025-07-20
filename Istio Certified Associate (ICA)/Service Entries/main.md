Когда вы устанавливаете Istio с помощью Istio Operator, то можете сконфигурировать режим для Outbound Traffic Policy - `meshConfig.outboundTrafficPolicy.mode`. Он может принимать два значения - `REGISTRY_ONLY` и `ALLOW_ANY`. По умолчанию используется режим `ALLOW_ANY`, т.е. разрешается взаимодействие с любыми внешними сервисами, даже если они не определены в Istio's Internal Service Registry.

Istio's Internal Service Registry отслеживает все сервисы внутри Service Mesh.

https://istio.io/latest/docs/reference/config/istio.mesh.v1alpha1/#MeshConfig-OutboundTrafficPolicy

Если установить режим `REGISTRY_ONLY`, то любой исходящий трафик к внешним сервисам (например БД или ВМ), которые не определены в Istio's Internal Service Registry, будет запрещен. И здесь в игру вступают Service Entries, которые добавляют записи для внешних сервисов в Istio's Internal Service Registry. Соответственно к этим сервисам можно будет маршрутизировать трафик.

Пример конфигурации Istio Operator с включенным режимом `REGISTRY_ONLY`:

```yaml
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
spec:
  components:
    base:
      enabled: true
    cni:
      enabled: false
    egressGateways:
    - enabled: false
      name: istio-egressgateway
    ingressGateways:
    - enabled: true
      name: istio-ingressgateway
    istiodRemote:
      enabled: false
    pilot:
      enabled: true
  hub: docker.io/istio
  meshConfig:
    outboundTrafficPolicy:
      mode: REGISTRY_ONLY
    defaultConfig:
      proxyMetadata: {}
```

Пример манифеста для Service Entry:

```yaml
apiVersion: networking.istio.io/v1beta1
kind: ServiceEntry
metadata:
  name: postgres-db
  namespace: frontend
spec:
  hosts:
  - db.example.com
  ports:
  - number: 5432
    name: db
    protocol: TCP
  resolution: DNS
```

Service Entry добавляется в определенный namespace. Таким образом, если мы включили режим `REGISTRY_ONLY`, то доступ к внешней БД будет работать только в namespace с соответствующим Service Entry и не будет работать в других namespace, где эта Service Entry отсутствует.

<img src="image.png" width="1200" height="500"><br>

Документация по Service Entries: https://istio.io/latest/docs/reference/config/networking/service-entry/

### Demo

Ставим утилиту istioctl и делаем дамп профиля:

```shell
$ istioctl profile dump demo -o yaml > custom-profile.yaml
```

Внесем изменения в дамп профиля `custom-profile.yaml`:

```yaml
<...>
  meshConfig:
    outboundTrafficPolicy:
      mode: REGISTRY_ONLY
<...>
```

Валидируем:

```shell
$ istioctl validate -f custom-profile.yaml
```

Устанавливаем istio из созданного профиля:

```shell
$ istioctl install -f custom-profile.yaml -y
```

Создаем тестовый pod:

```shell
$ kubectl run test --image=nginx
```

Подключимся к тестовому pod-у и проверим доступность какого-нибудь внешнего сервиса, например wikipedia:

```
$ kubectl exec -it test -- /bin/bash

root@test:/# curl -I -L http://www.wikipedia.org

HTTP/1.1 301 Moved Permanently
content-length: 0
location: https://www.wikipedia.org/
server: HAProxy
x-cache: cp3071 int
x-cache-status: int-tls
connection: close

HTTP/2 200 
date: Sat, 19 Jul 2025 00:56:18 GMT
cache-control: s-maxage=86400, must-revalidate, max-age=3600
server: ATS/9.2.11
etag: W/"1654e-637b242ff5500"
last-modified: Mon, 16 Jun 2025 15:43:48 GMT
content-type: text/html
age: 29432
accept-ranges: bytes
x-cache: cp3072 miss, cp3072 hit/1491993
x-cache-status: hit-front
server-timing: cache;desc="hit-front", host;desc="cp3072"
strict-transport-security: max-age=106384710; includeSubDomains; preload
report-to: { "group": "wm_nel", "max_age": 604800, "endpoints": [{ "url": "https://intake-logging.wikimedia.org/v1/events?stream=w3c.reportingapi.network_error&schema_uri=/w3c/reportingapi/network_error/1.0.0" }] }
nel: { "report_to": "wm_nel", "max_age": 604800, "failure_fraction": 0.05, "success_fraction": 0.0}
set-cookie: WMF-Last-Access=19-Jul-2025;Path=/;HttpOnly;secure;Expires=Wed, 20 Aug 2025 00:00:00 GMT
set-cookie: WMF-Last-Access-Global=19-Jul-2025;Path=/;Domain=.wikipedia.org;HttpOnly;secure;Expires=Wed, 20 Aug 2025 00:00:00 GMT
x-client-ip: 74.220.27.36
set-cookie: GeoIP=DE:HE:Frankfurt_am_Main:50.12:8.64:v4; Path=/; secure; Domain=.wikipedia.org
set-cookie: NetworkProbeLimit=0.001;Path=/;Secure;SameSite=None;Max-Age=3600
set-cookie: WMF-Uniq=Fea-M1zT9wo4bYOAITxqZAI1AAAAAFvdRKaztGjeYoq6n4Feb6_3fTi3rHnxRSxH;Domain=.wikipedia.org;Path=/;HttpOnly;secure;SameSite=None;Expires=Sun, 19 Jul 2026 00:00:00 GMT
content-length: 91470
```

Доступ есть, т.к. для namespace `default` еще не включено istio injection.

Включим istio injection для namespace `default`:

```shell
$ kubectl label ns default istio-injection=enabled
```

Пересоздадим тестовый pod:

```shell
$ kubectl delete pod test
$ kubectl run test --image=nginx
```

Вновь подключимся к тестовому pod-у и проверим доступность wikipedia:

```
$ kubectl exec -it test -- /bin/bash

root@test:/# curl -I -L http://www.wikipedia.org

HTTP/1.1 502 Bad Gateway
date: Sat, 19 Jul 2025 09:12:58 GMT
server: envoy
transfer-encoding: chunked
```

Теперь доступа нет, т.к. мы включили istio с настроенной Outbound Traffic Policy.

Добавим Service Entry:

```yaml
apiVersion: networking.istio.io/v1beta1
kind: ServiceEntry
metadata:
  name: wikipedia-egress
  namespace: default
spec:
  hosts:
  - www.wikipedia.org
  ports:
  - number: 80
    name: http
    protocol: HTTP
  - number: 443
    name: https
    protocol: HTTPS
  resolution: DNS
```

Вновь подключимся к тестовому pod-у и проверим доступность wikipedia:

```
$ kubectl exec -it test -- /bin/bash

root@test:/# curl -I -L http://www.wikipedia.org

HTTP/1.1 301 Moved Permanently
content-length: 0
location: https://www.wikipedia.org/
server: envoy
x-cache: cp3071 int
x-cache-status: int-tls
x-envoy-upstream-service-time: 19
date: Sat, 19 Jul 2025 09:19:43 GMT

HTTP/2 200 
date: Sat, 19 Jul 2025 00:56:18 GMT
cache-control: s-maxage=86400, must-revalidate, max-age=3600
server: ATS/9.2.11
etag: W/"1654e-637b242ff5500"
last-modified: Mon, 16 Jun 2025 15:43:48 GMT
content-type: text/html
age: 30205
accept-ranges: bytes
x-cache: cp3072 miss, cp3072 hit/1551599
x-cache-status: hit-front
server-timing: cache;desc="hit-front", host;desc="cp3072"
strict-transport-security: max-age=106384710; includeSubDomains; preload
report-to: { "group": "wm_nel", "max_age": 604800, "endpoints": [{ "url": "https://intake-logging.wikimedia.org/v1/events?stream=w3c.reportingapi.network_error&schema_uri=/w3c/reportingapi/network_error/1.0.0" }] }
nel: { "report_to": "wm_nel", "max_age": 604800, "failure_fraction": 0.05, "success_fraction": 0.0}
set-cookie: WMF-Last-Access=19-Jul-2025;Path=/;HttpOnly;secure;Expires=Wed, 20 Aug 2025 00:00:00 GMT
set-cookie: WMF-Last-Access-Global=19-Jul-2025;Path=/;Domain=.wikipedia.org;HttpOnly;secure;Expires=Wed, 20 Aug 2025 00:00:00 GMT
x-client-ip: 74.220.27.36
set-cookie: GeoIP=DE:HE:Frankfurt_am_Main:50.12:8.64:v4; Path=/; secure; Domain=.wikipedia.org
set-cookie: NetworkProbeLimit=0.001;Path=/;Secure;SameSite=None;Max-Age=3600
set-cookie: WMF-Uniq=4uvoqhkBygxIWroQtNxkGgI1AAAAAFvdDFQHe8t1uWEMFTlTabU0q-dmy1H4qx3U;Domain=.wikipedia.org;Path=/;HttpOnly;secure;SameSite=None;Expires=Sun, 19 Jul 2026 00:00:00 GMT
content-length: 91470
```

Доступ появился, т.к. мы добавили Service Entry. Однако, если посмотреть на логи Egress Gateway, то там будет пусто. Это значит, что трафик не проходит через Egress Gateway.

```shell
$ kubectl -n istio-system logs -f istio-egressgateway-644589b977-n7nr7 
```

Как объединить Egress Gateway с Service Entry, чтобы убедиться, что весь исходящий трафик проходит через Egress Gateway?

Для этого нам нужны три ресурса - Gateway, Virtual Service и Destination Rule.

Создадим Gateway:

```yaml
apiVersion: networking.istio.io/v1beta1
kind: Gateway
metadata:
  name: istio-egressgateway
  namespace: default
spec:
  selector:
    istio: egressgateway
  servers:
  - port:
      number: 80
      name: http
      protocol: HTTP
    hosts:
    - www.wikipedia.org
```

Создадим Destination Rule:

```yaml
apiVersion: networking.istio.io/v1beta1
kind: DestinationRule
metadata:
  name: egressgateway-for-wikipedia
  namespace: default
spec:
  host: istio-egressgateway.istio-system.svc.cluster.local
  subsets:
  - name: wikipedia
```

Также созадим Virtual Service:

```yaml
apiVersion: networking.istio.io/v1beta1
kind: VirtualService
metadata:
  name: wikipedia-egress-gateway
  namespace: default
spec:
  hosts:
  - www.wikipedia.org
  gateways:
  - istio-egressgateway
  - mesh
  http:
  - match:
    - gateways:
      - mesh
      port: 80
    route:
    - destination:
        host: istio-egressgateway.istio-system.svc.cluster.local
        subset: wikipedia
        port:
          number: 80
      weight: 100
  - match:
    - gateways:
      - istio-egressgateway
      port: 80
    route:
    - destination:
        host: www.wikipedia.org
        port:
          number: 80
      weight: 100
```

The reserved word `mesh` is used to imply (подразумевать) all the sidecars in the mesh. When this field is omitted, the default gateway (`mesh`) will be used, which would apply the rule to all sidecars in the mesh. If a list of gateway names is provided, the rules will apply only to the gateways. To apply the rules to both gateways and sidecars, specify `mesh` as one of the gateway names.

В случае входящего трафика мы указывали имя только одного Ingress Gateway при конфигурировании соответствующего Virtual Service. В случае же исходящего трафика мы указываем два Egress Gateway - один для трафика, входящего через Egress Gateway и один для трафика, исходящего изнутри Service Mesh, например наш тестовый pod, который обращается к сайту Wikipedia.

При совпадении (`match`) с хостом `www.wikipedia.org` трафик пойдет через `istio-egressgateway`.

Если трафик исходит от Service Mesh (тестовый pod, который обращается к сайту Wikipedia), то будет совпадение с `mesh` и трафик будет направлен на сервис `istio-egressgateway.istio-system.svc.cluster.local` и далее **петлей** снова придет на этот же Virtual Service, затем вновь сработает второй `match` и далее запрос пойдет на сайт Wikipedia.

В данном случае в логах Egress Gateway мы увидим записи об обращении к сайту Wikipedia.

Документация: https://istio.io/latest/docs/tasks/traffic-management/egress/egress-gateway/

Трафик из Mesh перехватывается VS, далее по совпадению с `mesh` попадает на сервис `istio-egressgateway.istio-system.svc.cluster.local`, снова перехватывается VS и дальше отправляется на внешний ресурс.