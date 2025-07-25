Zero Trust (нулевое доверие) – это модель безопасности, основанная на принципе "никогда не доверяй, всегда проверяй", даже внутри собственной сети.

Istio осуществляет нулевое доверие путем навязывания (enforce) mTLS для всех взаимодействий между сервисами. Однако навязывание  mTLS не включено "из коробки". Для его настройки нужно использовать ресурс Peer Authentication, который определяет один из двух возможных режимов работы - Strict или Permissive.

В режиме Permissive разрешено взаимодействие по plaint text HTTP, независимо от того, имеет ли нагрузка envoy-прокси или нет.

В режиме Strict разрешено взаимодействие только по mTLS. Это будет работать только если нагрузка имеет инжектированный envoy-прокси.

Пример глобальной политики навязывания mTLS:

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

Т.к. применяется она к namespace `istio-system`, то действие ее распространяется на весь Service Mesh.

Можно переопределить глобальную политику для определенного namespace:

```yaml
apiVersion: security.istio.io/v1beta1
kind: PeerAuthentication
metadata:
  name: default
  namespace: default
spec:
  mtls:
    mode: PERMISSIVE
```

<img src="image.png" width="800" height="300"><br>

Документация:

https://istio.io/latest/docs/reference/config/security/peer_authentication

https://istio.io/latest/docs/tasks/security/authentication/authn-policy/

### Demo

Ставим и включаем istio для namespace `default`, разворачиваем в нем приложение helloworld.

```shell
$ kubectl apply -f https://raw.githubusercontent.com/istio/istio/refs/heads/master/samples/helloworld/helloworld.yaml
```

Создаем тестовый namespace и нагрузку внутри него:

```shell
$ kubectl create ns test
$ kubectl -n test run test --image=nginx
```

Из тестового pod-а проверим доступность сервиса `helloworld`:

```shell
$ kubectl -n test exec -it test -- curl helloworld.default.svc.cluster.local:5000/hello
```

Все работает.

Включим mTLS глобально на уровне всего Service Mesh:

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

Из тестового pod-а вновь проверим доступность сервиса `helloworld`:

```shell
$ kubectl -n test exec -it test -- curl helloworld.default.svc.cluster.local:5000/hello
```

Не работает, т.к. для namespace `test` не включено istio injection и трафик уходит по plain text HTTP.

Включим istio injection для namespace `test` и пересоздадим тестовый pod:

```shell
$ kubectl label ns test istio-injection=enabled
$ kubectl -n test delete pod test
$ kubectl -n test run test --image=nginx
```

Из тестового pod-а вновь проверим доступность сервиса `helloworld`:

```shell
$ kubectl -n test exec -it test -- curl helloworld.default.svc.cluster.local:5000/hello
```