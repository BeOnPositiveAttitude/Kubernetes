В этом демо мы попробуем настроить политики авторизации - namespaced и workload-wide.

Сначала применим политику авторизации в namespace `default`.

```yaml
apiVersion: security.istio.io/v1beta1
kind: AuthorizationPolicy
metadata:
  name: allow-nothing
  namespace: default
spec:
  {}
```

Т.к. в ней нет селекторов, она будет действовать на весь namespace `default`. Секция `spec` имеет пустое значение, соответственно не разрешен какой-либо трафик и все запросы будут отклоняться. Чтобы политика применились, может потребоваться некоторое время из-за кэширования и другие накладных расходов на ее распространение.

Теперь в браузере при попытке открыть страницу продукта получаем сообщение `RBAC: access denied`. Т.е. Istio теперь не имеет каких-либо правил, разрешающих доступ к нагрузкам в Mesh-е.

Мы также можем создать некоторое количество трафика в Mesh-е с помощью curl-цикла, чтобы проверить его в Kiali. Но сначала проверим наше приложение Product Page в Kiali Dashboard. Видим, что от Product Page мы наблюдаем проблемы со всем трафиком приходящим в Mesh. Трафик не проходит.

Также на вкладке "Workloads" => "productpage-v1" => "Logs" видим множество ошибок `rbac_access_denied_matched_policy`.

Проверим trace-ы. Переходим на вкладку "Workloads" => "productpage-v1" => "Traces". Также видим проблемы.

Остановим поток трафика и создадим viewer-политику для Product Page. Здесь настроено действие ALLOW и секция `rule` сконфигурирована для трафика приходящего К сервису и разрешает только метод GET.

```yaml
apiVersion: security.istio.io/v1beta1
kind: AuthorizationPolicy
metadata:
  name: "productpage-viewer"
  namespace: default
spec:
  selector:
    matchLabels:
      app: productpage
  action: ALLOW
  rules:
  - to:
    - operation:
        methods: ["GET"]
```

Проверим в браузере. Видим, что страницы продукта открылась, но остальные сервисы - Details и Reviews все еще недоступны.

`Sorry, product details are currently unavailable for this book.`

`Sorry, product reviews are currently unavailable for this book.`

Когда мы обновим Kiali Dashboard, то увидим, что стрелка от ingress к Product Page позеленела, показывая тем самым, что теперь часть трафика проходит.

Теперь давайте шаг за шагом создадим оставшиеся политики авторизации, чтобы все наше приложение заработало.

Данная политика будет разрешать трафик, исходящий от Service Account `bookinfo-productpage` для доступа к сервису Details с помощью метода GET.

```yaml
apiVersion: security.istio.io/v1beta1
kind: AuthorizationPolicy
metadata:
  name: "details-viewer"
  namespace: default
spec:
  selector:
    matchLabels:
      app: details
  action: ALLOW
  rules:
  - from:
    - source:
        principals: ["cluster.local/ns/default/sa/bookinfo-productpage"]
    to:
    - operation:
        methods: ["GET"]
```

Теперь в браузере видим, что приложение Details стало доступно. В Kiali Dashboard также видим на графе, что соответствующий участок позеленел.

Также создадим аналогичную политику `reviews-viewer`.

```yaml
apiVersion: security.istio.io/v1beta1
kind: AuthorizationPolicy
metadata:
  name: "reviews-viewer"
  namespace: default
spec:
  selector:
    matchLabels:
      app: reviews
  action: ALLOW
  rules:
  - from:
    - source:
        principals: ["cluster.local/ns/default/sa/bookinfo-productpage"]
    to:
    - operation:
        methods: ["GET"]
```

В браузере видим, что сервис Reviews вновь стал доступен, но без рейтингов. Сервис Ratings все еще отдает ошибку. В Kiali Dashboard также видим на графе, что соответствующие участки позеленели. Reviews v2 и Reviews v3 все еще красные, очевидно из-за того, что трафик через них не доходит до сервиса Ratings.

Пришло время создать аналогичную политику для Ratings.

Также создадим аналогичную политику `reviews-viewer`. Данная политика будет разрешать трафик, исходящий от Service Account `bookinfo-reviews` для доступа к сервису Ratings с помощью метода GET.

```yaml
apiVersion: security.istio.io/v1beta1
kind: AuthorizationPolicy
metadata:
  name: "ratings-viewer"
  namespace: default
spec:
  selector:
    matchLabels:
      app: ratings
  action: ALLOW
  rules:
  - from:
    - source:
        principals: ["cluster.local/ns/default/sa/bookinfo-reviews"]
    to:
    - operation:
        methods: ["GET"]
```

Теперь в браузере видим, что все наше приложение полностью работоспособно. В Kiali Dashboard также видим на графе, что все стрелочки позеленели.

Перейдем в секцию "Istio Config" и отфильтруем по AuthorizationPolicy. Какой-либо другой трафик, например POST-запросы, либо новый источник трафика не будут разрешены.