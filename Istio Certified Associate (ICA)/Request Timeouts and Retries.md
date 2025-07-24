### Demo Timeouts

Ставим и включаем istio для namespace `default`, разворачиваем в нем приложение httpbin.

```shell
$ kubectl apply -f https://raw.githubusercontent.com/istio/istio/refs/heads/master/samples/httpbin/httpbin.yaml
```

Создаем тестовый pod:

```shell
$ kubectl run test --image=nginx
```

Проверим доступность сервиса `httpbin`:

```bash
$ kubectl exec -it test -- curl -I http://httpbin:8000/get

HTTP/1.1 200 OK
access-control-allow-credentials: true
access-control-allow-origin: *
content-type: application/json; charset=utf-8
date: Thu, 24 Jul 2025 08:42:10 GMT
x-envoy-upstream-service-time: 2
server: envoy
transfer-encoding: chunked
```

Создадим Virtual Service, в котором добавим таймаут. Т.е. если сервис (объект k8s) `httpbin` не отвечает в течение двух секунд, то пометить его как "timed out".

```yaml
apiVersion: networking.istio.io/v1beta1
kind: VirtualService
metadata:
  name: httpbin-vs
  namespace: default
spec:
  hosts:
  - httpbin
  http:
  - timeout: 2s
    route:
    - destination:
        host: httpbin
        port:
          number: 8000
```

Проверим доступность сервиса `httpbin` при задержке в 1 секунду (само приложение умеет создавать задержку при обращении к location `/delay`):

```bash
$ kubectl exec -it test -- curl -I http://httpbin:8000/delay/1

HTTP/1.1 200 OK
access-control-allow-credentials: true
access-control-allow-origin: *
content-type: application/json; charset=utf-8
server-timing: initial_delay;dur=1000.00;desc="initial delay"
date: Thu, 24 Jul 2025 08:48:15 GMT
x-envoy-upstream-service-time: 1001
server: envoy
transfer-encoding: chunked
```

Работает. Теперь проверим доступность сервиса при задержке в 2 секунды:

```bash
$ kubectl exec -it test -- curl -I http://httpbin:8000/delay/2

HTTP/1.1 504 Gateway Timeout
content-length: 24
content-type: text/plain
date: Thu, 24 Jul 2025 08:49:29 GMT
server: envoy
```

Получили таймаут.

### Demo Retries

Пересоздадим Virtual Service, добавив в него retries.

```yaml
apiVersion: networking.istio.io/v1beta1
kind: VirtualService
metadata:
  name: httpbin-vs
  namespace: default
spec:
  hosts:
  - httpbin
  http:
  - route:
    - destination:
        host: httpbin
        port:
          number: 8000
    retries:
      attempts: 3         # сколько раз повторить попытку
      perTryTimeout: 1s   # может вернуть "Gateway Timeout" в случае, если упрется в таймаут, например при обращении к /delay/2
      retryOn: 5xx        # повторять попытки при возникновении 500-й ошибки  
```

Сэмулируем  500-ю ошибку (само приложение умеет имитировать ошибки при обращении к location `/status`):

```bash
$ kubectl exec -it test -- curl -I http://httpbin:8000/status/500

HTTP/1.1 500 Internal Server Error
access-control-allow-credentials: true
access-control-allow-origin: *
content-type: text/plain; charset=utf-8
date: Thu, 24 Jul 2025 09:02:24 GMT
x-envoy-upstream-service-time: 157
server: envoy
transfer-encoding: chunked

$ kubectl exec -it test -- curl -I http://httpbin:8000/status/200

HTTP/1.1 200 OK
access-control-allow-credentials: true
access-control-allow-origin: *
content-type: text/plain; charset=utf-8
date: Thu, 24 Jul 2025 09:05:58 GMT
x-envoy-upstream-service-time: 1
server: envoy
transfer-encoding: chunked
```

Посмотрим логи контейнера `istio-proxy`:

```shell
$ kubectl logs httpbin-686d6fc899-t5q4b -c istio-proxy

<...>
[2025-07-24T09:02:24.465Z] "HEAD /status/500 HTTP/1.1" 500 - via_upstream - "-" 0 0 1 0 "-" "curl/7.88.1" "62c62bca-63f5-9b9c-a0ad-3a5c27a9e7ab" "httpbin:8000" "192.168.1.7:8080" inbound|8080|| 127.0.0.6:59665 192.168.1.7:8080 192.168.1.8:46986 outbound_.8000_._.httpbin.default.svc.cluster.local default
[2025-07-24T09:02:24.493Z] "HEAD /status/500 HTTP/1.1" 500 - via_upstream - "-" 0 0 0 0 "-" "curl/7.88.1" "62c62bca-63f5-9b9c-a0ad-3a5c27a9e7ab" "httpbin:8000" "192.168.1.7:8080" inbound|8080|| 127.0.0.6:59665 192.168.1.7:8080 192.168.1.8:46986 outbound_.8000_._.httpbin.default.svc.cluster.local default
[2025-07-24T09:02:24.525Z] "HEAD /status/500 HTTP/1.1" 500 - via_upstream - "-" 0 0 0 0 "-" "curl/7.88.1" "62c62bca-63f5-9b9c-a0ad-3a5c27a9e7ab" "httpbin:8000" "192.168.1.7:8080" inbound|8080|| 127.0.0.6:59665 192.168.1.7:8080 192.168.1.8:46986 outbound_.8000_._.httpbin.default.svc.cluster.local default
[2025-07-24T09:02:24.618Z] "HEAD /status/500 HTTP/1.1" 500 - via_upstream - "-" 0 0 0 0 "-" "curl/7.88.1" "62c62bca-63f5-9b9c-a0ad-3a5c27a9e7ab" "httpbin:8000" "192.168.1.7:8080" inbound|8080|| 127.0.0.6:59665 192.168.1.7:8080 192.168.1.8:46986 outbound_.8000_._.httpbin.default.svc.cluster.local default
[2025-07-24T09:05:58.455Z] "HEAD /status/200 HTTP/1.1" 200 - via_upstream - "-" 0 0 0 0 "-" "curl/7.88.1" "190ec094-2bcf-92cf-88d1-9cd091c118ce" "httpbin:8000" "192.168.1.7:8080" inbound|8080|| 127.0.0.6:58309 192.168.1.7:8080 192.168.1.8:46986 outbound_.8000_._.httpbin.default.svc.cluster.local default
```

Видим три повторные попытки выполнения запроса к location `/status/500`.

Документация: https://istio.io/latest/docs/concepts/traffic-management/#network-resilience-and-testing