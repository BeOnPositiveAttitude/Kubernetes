При тестировании приложения в `development` namespace оно прекрасно работало, при переносе в `production` namespace появилась ошибка `CrashLoopBackOff`.

<img src="image.png" width="500" height="60"><br>

Ошибка означает, что список аргументов/переменных окружения в контейнере слишком большой.

В K8s существует два способа сделать наши приложения доступными - использовать **DNS Plugin** (например CoreDNS) либо **Environment Variables**.

Вариант с использованием Environment Variables реализован следующим образом - переменные окружения всех pod-ов инжектируются абсолютно в каждый pod. Т.е. в переменных окружения указывается соответствие названия service и его IP-адрес (`LOGGING_SERVICE_HOST=172.31.246.106`), целевой порт service и т.д. Отсюда возможно большое количество переменных окружения в namespace-ах с множеством приложений.

В случае, когда мы используем CoreDNS нам не нужны все эти переменные окружения.

За инжектирование переменных окружения в pod-ы отвечает опция `enableServiceLinks`, которая имеет значение по умолчанию `true`.

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: my-super-app
  labels:
    app: web
spec:
  selector:
    matchLabels:
      app: web
  template:
    metadata:
      labels:
        app: web
    spec:
      enableServiceLinks: true
      containers:
      - name: webapp
        image: my-custom-image:latest
        ports:
        - containerPort: 8080
```

<img src="image-1.png" width="600" height="300"><br>