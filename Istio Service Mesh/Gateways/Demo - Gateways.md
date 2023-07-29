У нас уже есть сконфигурированный Gateway. Давайте сначалаа проверим его. Ранее мы применили этот Gateway из каталога `samples/` и он работал.

Редактируем созданный ранее Gateway: `kubectl edit gateway` и видим, что поле `hosts` содержит wildcard `'*'`.

Как нам сконфигурировать Gateway с правильным hostname? Перед тем как сделать это, давайте заново создадим Deployment для Product Page из манифеста `bookinfo.yaml`, чтобы убедиться, что все наши приложения запущены:

`kubectl apply -f samples/bookinfo/platform/kube/bookinfo.yaml`.

Удаляем созданный ранее Gateway: `kubectl delete gateway bookinfo-gateway`.

Теперь давайте создадим Gateway с определенным hostname. Он использует `istio-ingressgateway` и разрешает трафик с 80-го порта по протоколу http. Он будет разрешать только трафик приходящий на хост `bookinfo.app`.

```bash
kubectl apply -f - <<EOF
apiVersion: networking.istio.io/v1alpha3
kind: Gateway
metadata:
  name: bookinfo-gateway
spec:
  selector:
    istio: ingressgateway
  servers:
  - port:
      number: 80
      name: http
      protocol: HTTP
    hosts:
    - "bookinfo.app"
EOF
```

Чтобы этот Gateway начал работать, нам нужно создать VirtualService для обработки входящего трафика. Важно отметить, что поле `hosts` должно совпадать для Gateway и VirtualService. Данный VirtualService cвязан с Gateway `bookinfo-gateway`, который мы только что создали. В конфигурации VirtualService существует несколько match-правил и одно route-правило.

```bash
kubectl apply -f - <<EOF
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: bookinfo
spec:
  hosts:
  - bookinfo.app
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
EOF
```

`curl -s -HHost:bookinfo.app http://$INGRESS_HOST:$INGRESS_PORT/productpage | grep -o "<title>.*</title>"`.