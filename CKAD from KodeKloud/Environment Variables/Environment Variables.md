Так мы задаем environment variable в команде docker:

```shell
docker run -e APP_COLOR=pink simple-webapp-color
```

Пример указания environment variable приведен в `pod-definition.yaml` файле.

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: simple-webapp-color
spec:
  containers:
  - name: simple-webapp-color
    image: simple-webapp-color
    ports:
    - containerPort: 8080
    env:
    - name: APP_COLOR
      value: pink
```

Вариант, когда значение переменной берется из ConfigMap:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: simple-webapp-color
spec:
  containers:
  - name: simple-webapp-color
    image: simple-webapp-color
    ports:
    - containerPort: 8080
    env:
    - name: APP_COLOR
      valueFrom:
        configMapKeyRef:
```

Вариант, когда значение переменной берется из Secret:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: simple-webapp-color
spec:
  containers:
  - name: simple-webapp-color
    image: simple-webapp-color
    ports:
    - containerPort: 8080
    env:
    - name: APP_COLOR
      valueFrom:
        secretKeyRef:
```