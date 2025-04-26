Всякий раз когда мы меняем содержимое configmap/secret нам нужно перезапускать pod-ы, к которым они примонтированы. Это становится проблемой, когда у нас сотни pod/configmap/secret.

Для решения этой проблемы существует контроллер https://github.com/stakater/Reloader

Установить контроллер:

```shell
$ kubectl apply -f https://raw.githubusercontent.com/stakater/Reloader/master/deployments/kubernetes/reloader.yaml
```

В манифест добавляется соответствующая аннотация:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: my-app
  annotations:
    reloader.stakater.com/auto: "true"
spec:
  template:
    metadata:
      labels:
        app: my-app
    spec:
      containers:
        - name: app
          image: your-image
          envFrom:
            - configMapRef:
                name: my-config
            - secretRef:
                name: my-secret
```