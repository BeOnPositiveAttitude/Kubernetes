У нас уже есть сконфигурированный Gateway. Давайте сначала проверим его. Ранее мы применили этот Gateway из каталога `samples/` и он работал.

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

Мы должны использовать `bookinfo.app` в качестве хоста в нашем запросе. В `curl` мы можем добавить флаг `-H`, чтобы установить для HTTP-заголовка значение `bookinfo.app`.

Команда для проверки: `curl -s -HHost:bookinfo.app http://$INGRESS_HOST:$INGRESS_PORT/productpage | grep -o "<title>.*</title>"` в итоге должна вернуть: `<title>Simple Bookstore App</title>`.

Сейчас наше приложение "Bookinfo" открыто для внешнего трафика с помощью Gateway `bookinfo-gateway`.

Посмотрим секцию IstioConfig в WebUI Kiali. Здесь мы также можем увидеть наш Gateway `bookinfo-gateway` и внести изменения в его конфигурацию с помощью Kiali. Также здесь присутствует VirtualService, который мы только что настроили.

Теперь давайте пойдем в браузер и попробуем ввести hostname. Чтобы сделать это, мы можем добавить IP и hostname в наш файл `/etc/hosts` с помощью команды: `echo -e "$(minikube ip)\tbookinfo.app" | sudo tee -a /etc/hosts`. Здесь `-e` - enable interpretation of backslash escapes, `-a` - append to the given files, do not overwrite.

В адресной строке браузера вводим `http://bookinfo.app:$INGRESS_PORT/productpage`, должна открыться страница приложения, в Chrome и Firefox редиректит на https и не открывается, ставить браузер Falcon. Таким образом мы смогли пройти через Gateway, который мы настроили, используя hostname `bookinfo.app`.

Теперь нам нужно перейти обратно в настройки Gateway и вернуть wildcard для hostname, т.к. в процессе прохождения курса нам может понадобиться вернуться к дефолтной конфигурации, используя yaml-файлы из каталога `samples/`.

```yaml
apiVersion: networking.istio.io/v1alpha3
kind: Gateway
metadata:
  name: bookinfo-gateway
spec:
  selector:
    istio: ingressgateway
  servers:
  - port:
      name: http
      number: 80
      protocol: HTTP
    hosts:
    - "*"
```