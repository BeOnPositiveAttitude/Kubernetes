В сервисно-ориентированной архитектуре нам нужно убедиться, что взаимодействие между двумя сервисами аутентифицировано. Это значит, что когда один сервис пытается взаимодействовать с другим сервисом, должен существовать способ подтвердить, что они действительно являются теми за кого себя выдают. 

Это делается путем hardening трафика с помощью различных вариантов верификации - mTLS (mutual TLS) и валидация JWT (JSON Web Token).

Например когда сервис Product Page обращается к сервису Reviews, то сервис Reviews должен знать, что запрос действительно пришел от сервиса Product Page, а не от внешнего источника, который "притворяется" сервисом Product Page. Соответственно трафик от одного сервиса к другому должен быть верифицирован.

При использовании mTLS каждый сервис получает свою собственную identity (уникальность), которая обеспечивается использованием пары ключ-сертификат. Выпуск и распространение сертификатов управляются автоматически с помощью istiod. Нет ничего лишнего, что вам нужно делать с сервисами.

Другая область для аутентификации - конечные пользователи, получающие доступ к сервисам. Для этого Istio поддерживает аутентификацию запросов с помощью валидации JWT или с помощью провайдеров OpenID Connect, некоторые из которых ORY Hydra, Keycloak, Firebase и Google. 

Далее приведен пример конфигурации PeerAuthentication. Политики аутентификации определяются объектами типа `PeerAuthentication` и `RequestAuthentication`. Они будут применены в namespace `book-info`. Это политика будет иметь эффект только на рабочих нагрузках с Labels `app: reviews`. Это говорит о том, что рабочие нагрузки строго должны использовать mutual TLS. В данном случае мы включили аутентификацию только для приложения Reviews, т.е. включили ее для одной рабочей нагрузки. Это называется *workload-specific policy*.

```yaml
apiVersion: security.istio.io/v1beta1
kind: PeerAuthentication
metadata:
  name: "example-peer-policy"
  namespace: "book-info"
spec:
  selector:
    matchLabels:
      app: reviews
  mtls:
    mode: STRICT
```

Если мы удалим `selector`, тогда политика будет включен для всего namespace. Это называется *namespace-wide policy*. В данном примере она применяется ко всем рабочим нагрузкам в пределах namespace `book-info`.

```yaml
apiVersion: security.istio.io/v1beta1
kind: PeerAuthentication
metadata:
  name: "example-peer-policy"
  namespace: "book-info"
spec:
  mtls:
    mode: STRICT
```

Если мы изменим namespace на корневой `istio-system`, тогда это становится *mesh-wide policy* и применяется ко всему Mesh-у.

```yaml
apiVersion: security.istio.io/v1beta1
kind: PeerAuthentication
metadata:
  name: "example-peer-policy"
  namespace: "istio-system"
spec:
  mtls:
    mode: STRICT
```