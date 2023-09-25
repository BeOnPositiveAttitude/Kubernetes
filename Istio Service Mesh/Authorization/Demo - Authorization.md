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

Т.к. в ней нет селекторов, она будет действовать на весь namespace `default`. Секция `spec` имеет пустое значение, соответственно не разрешен какой-либо траффик и все запросы будут отклоняться. Чтобы политика применились, может потребоваться некоторое время из-за кэширования и другие накладных расходов на ее распространение.

Теперь в браузере при попытке открыть страницу продукта получаем сообщение `RBAC: access denied`. Т.е. Istio теперь не имеет каких-либо правил, разрешающих доступ к нагрузкам в Mesh-е.

Мы также можем создать некоторое количество траффика в Mesh-е с помощью curl-цикла, чтобы проверить его в Kiali. Но сначала проверим наше приложение Product Page в Kiali Dashboard. Видим, что от Product Page мы наблюдаем проблемы со всем траффиком приходящим в Mesh. Траффик не проходит.

Также на вкладке "Workloads" => "productpage-v1" => "Logs" видим множество ошибок `rbac_access_denied_matched_policy`.

Проверим trace-ы. Переходим на вкладку "Workloads" => "productpage-v1" => "Traces". Также видим проблемы.

Остановим поток трафика и создадим viewer-политику для Product Page.

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