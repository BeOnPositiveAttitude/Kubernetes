Теперь, когда нас есть Gateway `bookinfo-gateway`, пользователи, идущие на URL http://bookinfo.app, будут попадать на Gateway. Но куда идти дальше? Как мы будем маршрутизировать трафик через этот Gateway к нашим сервисам? Существует множество разных сервисов. Каким образом мы можем указать, что трафик к URL http://bookinfo.app/productpage должен идти на Service `productpage`?

Service `productpage` также обслуживает статический HTML/CSS и JavaScript контент по пути `/static`. Также существуют пути `/login`, `/logout` и `/api`. Все они должны маршрутизироваться на Service `productpage`.

Все правила маршрутизации конфигурируются с помощью Virtual Services. Virtual Services определяют набор правил маршрутизации для трафика приходящего в Service Mesh от `ingressgateway`. Virtual Services являются гибкими и мощными и обладают богатым набором опций для маршрутизации трафика. Вы можете задать поведение трафика для одного и более hostname, управлять трафиком в пределах разных версий сервиса, поддерживаются стандартные и regex-пути.

Когда Virtual Service создан, Istio control plane применяет новую конфигурацию ко всем Envoy sidecar proxies.

<img src="screen1.png" width="1000" height="500"><br>

Давайте создадим Virtual Service для маршрутизации указанных URL к Service `productpage`. Мы создаем объект с версией API равной `networking.istio.io/v1alpha3`. Это может поменяться в последующих версиях. Поэтому всегда обращайтесь к документации Istio при создании Virtual Services для получения самой свежей поддерживаемой версии API.

Первым делом мы указываем, чтобы только трафик для хоста `bookinfo.app` попадал на Virtual Service. Для этого редактируем секцию `hosts`. Также здесь может быть настроено несколько Gateways. Каким образом мы можем ассоциировать этот Virtual Service с Gateway, созданным для нашего приложения? Для этого мы добавляем секцию `gateways` и указываем имя созданного нами Gateway - `bookinfo-gateway`. И наконец у нас есть секция `http`, где мы добавляем правила маршрутизации. Секция `match` определяет URIs, который должны совпадать. Это URIs, которые мы обсуждали ранее. `exact` означает, что URI совпадает "as is", а `prefix` означает URIs, которые начинаются с заданного URI, например `/static/something` или `/api/v1/products/something`. Весь трафик, подходящий под заданные URI-паттерны, затем маршрутизируется в точку назначения, указанную в секции `route`.

```yaml
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: bookinfo
spec:
  hosts:
  - "bookinfo.app"
  gateways:
  - bookinfo-gateway
  http:
  - match:
    - uri:
        exact: /productpage
    - uri:
        prefix: /static
    - uri:
        exact: /login
    - uri:
        exact: /logout
    - uri:
        prefix: /api/v1/products
    route:
    - destination:
        host: productpage
        port:
          number: 9080
```

Теперь у нас есть Virtual Service для Product Page. Весь трафик приходящий через `bookinfo-gateway` с hostname равным `bookinfo.app` теперь попадает на Virtual Service.