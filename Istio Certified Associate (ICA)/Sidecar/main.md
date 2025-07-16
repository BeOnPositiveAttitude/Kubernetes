Если в каком-либо namespace не включены envoy-прокси, а в другом включены, то трафик между этими namespace все равно будет проходить (при условии отсутствия включенной политики peer authentication).

По умолчанию istio применяет дефолтное поведение для sidecar, которое является разрешающим (permissive) и позволяет работать основным функциям mesh. Данный permissive mode разрешает входящий и исходящий трафик к любой другой нагрузке, независимо от того есть у этой нагрузки envoy-прокси или нет. Разрешается взаимодействие как по mTLS, так и по plain text.

При дефолтном поведении sidecar весь входящий и исходяший трафик перехватывается и управляется envoy-прокси. Весь исходящий трафик, включая трафик к сервисам в других namespace или к внешним сервисам, управляется sidecar. **mTLS-режим не навязывается**, пока вы не настроите его глобально. По умолчанию доступны основные функции mesh, такие как load balancing, timeouts, retries, logging, circuit breaking, rate limiting и т.д.

Вы можете использовать поведение по умолчанию и чаще всего этого достаточно. Однако вам может потребоваться более тонкая настройка поведения sidecar для определенных namespace. Например, чтобы namespace `payments` мог взаимодействовать только с namespace `app` и `istio-system` и не мог взаимодействовать с какими-либо другими namespace.

Чтобы переопределить дефолтное поведение sidecar, нужно создать yaml-файл:

```yaml
apiVersion: networking.istio.io/v1v1beta1
kind: Sidecar
metadata:
  name: default
  namespace: payments
spec:
  egress:
  - hosts:
    - "./*"     # точка означает сам namespace "payments", звёздочка означает любую нагрузку в указанном namespace 
    - "app/*"
    - "istio-system/*"
```

Как уже говорилось ранее, по умолчанию mTLS не включен и находится в режиме permissive, который разрешает взаимодействие как по mTLS, так и по plain text. Можно включить mTLS для определенного namespace:

```yaml
apiVersion: security.istio.io/v1beta1
kind: PeerAuthentication
metadata:
  name: default
  namespace: app
spec:
  mtls:
    mode: STRICT
```

Это значит, что любая другая нагрузка, которая будет взаимодействовать с приложением в namespace `app`, должна иметь включенный istio sidecar. Т.е. разрешено взаимодейтсвие только по mTLS.

Пример конфигурации sidecar:

```yaml
apiVersion: networking.istio.io/v1
kind: Sidecar
metadata:
  name: ratings
  namespace: bookinfo
spec:
  workloadSelector:   # к каким pod-ам применяется
    labels:
      app: ratings
  ingress:
  - port:
      number: 9080
      protocol: HTTP
      name: somename
    defaultEndpoint: unix:///var/run/someuds.sock   # принимается входящий трафик на порт 9080 и перенаправляется на unix-сокет
  egress:
  - port:
      number: 9080    # отправляется только трафик на порт 9080 в namespace "bookinfo"
      protocol: HTTP
      name: egresshttp
    hosts:
    - "bookinfo/*"
  - hosts:
    - "istio-system/*"

```

The workload accepts inbound HTTP traffic on port 9080. The traffic is then forwarded to the attached workload instance listening on a Unix domain socket. In the egress direction, in addition to the `istio-system` namespace, the sidecar proxies only HTTP traffic bound for port 9080 for services in the `bookinfo` namespace.

Документация: https://istio.io/latest/docs/reference/config/networking/sidecar/

### Demo

Ставим и включаем istio для namespace `default`, разворачиваем в нем приложение bookinfo.

Создаем тестовый namespace и нагрузку внутри него:

```shell
$ kubectl create ns test
$ kubectl -n test run test --image=nginx
```

Подключимся к тестовому pod-у и проверим доступность главной страницы приложения bookinfo:

```
$ kubectl -n test exec -it test -- /bin/bash

root@test:/# curl -I productpage.default.svc.cluster.local:9080
HTTP/1.1 200 OK
content-type: text/html; charset=utf-8
content-length: 1683
server: istio-envoy
date: Tue, 15 Jul 2025 08:30:48 GMT
x-envoy-upstream-service-time: 5
x-envoy-decorator-operation: productpage.default.svc.cluster.local:9080/*
```

Как видно трафик успешно проходит от тестового pod-а (у которого нет istio sidecar) к главной странице приложения bookinfo (у которого включен istio sidecar).

Применим в namespace `default` политику, навязывающую использование mTLS:

```yaml
apiVersion: security.istio.io/v1beta1
kind: PeerAuthentication
metadata:
  name: default
  namespace: default
spec:
  mtls:
    mode: STRICT
```

Вновь подключимся к тестовому pod-у и проверим доступность главной страницы приложения bookinfo:

```
$ kubectl -n test exec -it test -- /bin/bash

root@test:/# curl -I productpage.default.svc.cluster.local:9080   
curl: (56) Recv failure: Connection reset by peer
```

Как видим, соединение сбрасывается из-за настроенной политики.

Включим istio для namespace `test`:

```shell
$ kubectl label ns test istio-injection=enabled
```

Пересоздадим тестовый pod:

```shell
$ kubectl -n test delete po test
$ kubectl -n test run test --image=nginx
```

Вновь подключимся к тестовому pod-у и проверим доступность главной страницы приложения bookinfo:

```
$ kubectl -n test exec -it test -- /bin/bash

root@test:/# curl -I productpage.default.svc.cluster.local:9080   
HTTP/1.1 200 OK
content-type: text/html; charset=utf-8
content-length: 1683
server: envoy
date: Tue, 15 Jul 2025 08:46:24 GMT
x-envoy-upstream-service-time: 20
```

Создадим объект sidecar, тем самым переопределив его дефолтное поведение:

```yaml
apiVersion: networking.istio.io/v1beta1
kind: Sidecar
metadata:
  name: default
  namespace: test
spec:
  egress:
  - hosts:
    - "./*"
    - "istio-system/*"
```

Вновь подключимся к тестовому pod-у и проверим доступность главной страницы приложения bookinfo:

```
$ kubectl -n test exec -it test -- /bin/bash

root@test:/# curl -I productpage.default.svc.cluster.local:9080   
curl: (52) Empty reply from server
```

Как видим трафик не проходит, т.к. он открыт только внутри namespace `test` и к namespace `istio-system`.

Настроим объект sidecar, добавив в список разрешенных namespace `default`:

```yaml
apiVersion: networking.istio.io/v1beta1
kind: Sidecar
metadata:
  name: default
  namespace: test
spec:
  egress:
  - hosts:
    - "./*"
    - "default/*"
    - "istio-system/*"
```

Вновь подключимся к тестовому pod-у и проверим доступность главной страницы приложения bookinfo:

```
$ kubectl -n test exec -it test -- /bin/bash

root@test:/# curl -I productpage.default.svc.cluster.local:9080   
HTTP/1.1 200 OK
content-type: text/html; charset=utf-8
content-length: 1683
server: envoy
date: Tue, 15 Jul 2025 08:58:57 GMT
x-envoy-upstream-service-time: 10
```

Настроим объект sidecar таким образом, чтобы он применялся только к тестовому pod-у:

```yaml
apiVersion: networking.istio.io/v1beta1
kind: Sidecar
metadata:
  name: default
  namespace: test
spec:
  workloadSelector:
    labels:
      run: test
  egress:
  - hosts:
    - "./*"
    - "istio-system/*"
```

Вновь подключимся к тестовому pod-у и проверим доступность главной страницы приложения bookinfo:

```
$ kubectl -n test exec -it test -- /bin/bash

root@test:/# curl -I productpage.default.svc.cluster.local:9080   
curl: (52) Empty reply from server
```

Не работает, т.к. мы убрали namespace `default` из списка разрешенных.

Создадим второй тестовый pod, но с другим label:

```shell
$ kubectl -n test run nginx --image=nginx
```

Подключимся ко второму тестовому pod-у и проверим доступность главной страницы приложения bookinfo:

```
$ kubectl -n test exec -it nginx -- /bin/bash

root@test:/# curl -I productpage.default.svc.cluster.local:9080   
HTTP/1.1 200 OK
content-type: text/html; charset=utf-8
content-length: 1683
server: envoy
date: Tue, 15 Jul 2025 09:07:29 GMT
x-envoy-upstream-service-time: 19
```