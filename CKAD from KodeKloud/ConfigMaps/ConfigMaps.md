ConfigMaps используются для передачи конфигурационных данных в формате пары key/value в K8s.

Сначала нужно создать ConfigMap, затем вставить ее в pod.

Существует два способа создания ConfigMap - императивный и декларативный: `kubectl create configmap` и `kubectl create -f`.

Создать ConfigMap передав key/value пару непосредственно в команде:

```shell
$ kubectl create configmap app-config --from-literal=APP_COLOR=blue --from-literal=APP_MOD=prod
```

Создать ConfigMap из имеющегося файла:

```shell
$ kubectl create configmap app-config --from-file=app_config.properties
```

You can pass in the `--from-file` argument multiple times to create a ConfigMap from multiple data sources.

Смотреть ConfigMap: `kubectl get configmaps` и `kubectl describe configmaps`.

Пример ConfigMap:

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: app-config
data:
  APP_COLOR: blue
  APP_MOD: prod
```

Примеры использования ConfigMap в pod-е.

В данном варианте **все** переменные из ConfigMap будут импортированы в environment variables:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: simple-webapp-color
  labels:
    name: simple-webapp-color
spec:
  containers:
  - name: simple-webapp-color
    image: simple-webapp-color
    ports:
    - containerPort: 8080
    envFrom:
    - configMapRef:
        name: app-config
```

Вариант, когда нужно импортировать только определенные переменные из ConfigMap:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: simple-webapp-color
  labels:
    name: simple-webapp-color
spec:
  containers:
  - name: simple-webapp-color
    image: simple-webapp-color
    ports:
    - containerPort: 8080
    env:
    - name: APP_COLOR        # имя environment variable в приложении
      valueFrom:
        configMapKeyRef:
          name: app-config   # имя ConfigMap
          key: APP_COLOR     # название переменной в ConfigMap
```

Пример монтирования ConfigMap в качестве volume:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: pod1
spec:
  containers:
  - image: nginx:alpine
    name: container1
    env:
    - name: TREE1
      valueFrom:
        configMapKeyRef:
          name: trauerweide
          key: tree
    volumeMounts:
    - name: config-vol
      mountPath: /etc/birke
  volumes:
  - name: config-vol
    configMap:
      name: birke
```