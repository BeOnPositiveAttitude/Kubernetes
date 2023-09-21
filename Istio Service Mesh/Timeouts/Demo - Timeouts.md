Для того, чтобы была возможность попробовать таймаут, нам нужно заставить один из наших сервисов отвечать медленнее. Мы сделаем это путем добавления задержки в наш Mesh. Затем мы создадим таймаут, таким образом Mesh будет работать сплоченно и наши сервисы не будут ждать слишком долго, даже чтобы просто получить сообщение об ошибке.

Чтобы сделать задание таймаута заметным, давайте добавим его к сервису Product Page, так мы сможем увидеть это в браузере.

Далее представлен Virtual Service, который мы будем использовать для добавления задержки. Это означает, что Istio заставит сервис Details ждать 5 секунд, прежде чем вернуть ответ для 100% приходящего на него трафика.

```yaml
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: details
spec:
  hosts:
    - details
  http:
  - fault:
      delay:
        percent: 100
        fixedDelay: 5s
    route:
    - destination:
        host: details
        subset: v1
```

Применим данный манифест.

Когда мы попытаемся открыть приложение в браузере, то увидим, что сервис Details отдает ошибку. Давайте попробуем уменьшить значение `percent` до 70.

Теперь в браузере мы периодически видим ответ от Details, но большую часть времени он выдает ошибку.

Давайте настроим конфигурацию таким образом - если сервису Details требуется более 3 секунд для загрузки, тогда сам сервис Product Page будет выдавать таймаут. Для этого добавим секцию `timeout` в Virtual Service `bookinfo`:

```yaml
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: bookinfo
spec:
  hosts:
  - "*"
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
    timeout: 3s
```

Также уменьшим значение `percent` до 50 в VirtualService `details`.

Теперь, если сервис Details не отвечает своевременно на запрос, то в браузере вместо страницы продукта мы начнем видеть настроенные таймауты в виде сообщения `upstream request timeout`.

Вы можете использовать таймауты, когда сервисы зависят друг от друга (как в случае с микросервисами), и когда вы хотите задать четкие определения между этими зависимостями.