Virtual Service перехватывает трафик, предназначенный для сервиса (нагрузки), и маршрутизирует его, основываясь на заданой политике. Virtual Service работает в сочетании с Destination Rules.

Destination Rules определяет политики, которые применяются к трафику, предназначенному для сервиса (нагрузки), после того как маршрутизация уже произошла. Это означает, что как только трафик "приземлился" на Virtual Service, вы можете добавить различные правила. Например, у нас есть две версии приложения и мы хотим разделить трафик между ними в соотношении 50/50. Для этого мы можем использовать Destination Rules.

Предположим у нас есть две версии одного приложения:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: app-deployment-v1
  namespace: frontend
spec:
  replicas: 3
  selector:
    matchLabels:
      labels:
        app: frontend
        version: v1
  template:
    metadata:
      labels:
        app: frontend
        version: v1
    spec:
      containers:
      - name: app
        image: app:1.1
```

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: app-deployment-v2
  namespace: frontend
spec:
  replicas: 3
  selector:
    matchLabels:
      labels:
        app: frontend
        version: v2
  template:
    metadata:
      labels:
        app: frontend
        version: v2
    spec:
      containers:
      - name: app
        image: app:2.1
```

И Service:

```yaml
apiVersion: v1
kind: Service
metadata:
  name: app-svc
  namespace: frontend
spec:
  ports:
    - port:80
      name: http
  selector:
    app: frontend
```

Для разделения трафика создадим Destination Rule:

```yaml
apiVersion: networking.istio.io/v1
kind: DestinationRule
metadata:
  name: app-ds
  namespace: frontend
spec:
  host: app-svc
  subsets:
  - name: v1
    labels:
      version: v1
  - name: v2
    labels:
      version: v2
```

Subsets по сути являются набором pod-ов, сгруппированных по меткам.

Также созадим Virtual Service:

```yaml
apiVersion: networking.istio.io/v1
kind: VirtualService
metadata:
  name: app-vs
  namespace: frontend
spec:
  hosts:
  - app-svc   # The address used by a client when attempting to connect to a service
  http:
  - match:
    - uri:
        prefix: /
    route:
    - destination:
        host: app-svc.frontend.svc.cluster.local
        port:
          number: 80
        subset: v1
      weight: 50
    - destination:
        host: app-svc.frontend.svc.cluster.local
        port:
          number: 80
        subset: v2
      weight: 50
```

<img src="image.png" width="1000" height="550"><br>

Документация: https://istio.io/latest/docs/reference/config/networking/destination-rule/