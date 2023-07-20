Теперь, когда нас есть Gateway `bookinfo-gateway`, пользователи, идущие на URL http://bookinfo.app, будут попадать на Gateway. Но куда идти дальше? Как мы будем маршрутизировать трафик через этот Gateway к нашим сервисам? Существует множество разных сервисов. Каким образом мы можем указать, что трафик к URL http://bookinfo.app/productpage должен идти на Service `productpage`?

Service `productpage` также обслуживает статический HTML/CSS и JavaScript контент по пути `/static`. Также существуют пути `/login`, `/logout` и `/api`. Все они должны маршрутизироваться на Service `productpage`.

Все правила маршрутизации конфигурируются с помощью Virtual Services. Virtual Services определяют набор правил маршрутизации для трафика приходящего в Service Mesh от `ingressgateway`. Virtual Services являются гибкими и мощными и обладают богатым набором опций для маршрутизации трафика. Вы можете задать поведение трафика для одного и более hostname, управлять трафиком в пределах разных версий сервиса, поддерживаются стандартные и regex-пути.

Когда Virtual Service создан, Istio control plane применяет новую конфигурацию ко всем Envoy sidecar proxies.

<img src="screen1.png" width="1000" height="500"><br>

Давайте создадим Virtual Service для маршрутизации указанных URL к Service `productpage`. Мы создаем объект с версией API равной `networking.istio.io/v1alpha3`. Это может поменяться в последующих версиях. Поэтому всегда обращайтесь к документации Istio при создании Virtual Services для получения самой свежей поддерживаемой версии API.

```yaml
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: bookinfo
spec:
  hosts:
  - reviews.prod.svc.cluster.local
  http:
  - name: "reviews-v2-routes"
    match:
    - uri:
        prefix: "/wpcatalog"
    - uri:
        prefix: "/consumercatalog"
    rewrite:
      uri: "/newcatalog"
    route:
    - destination:
        host: reviews.prod.svc.cluster.local
        subset: v2
  - name: "reviews-v1-route"
    route:
    - destination:
        host: reviews.prod.svc.cluster.local
        subset: v1
```