ConfigMaps используются для передачи конфигурационных данных в формате пары key/value в K8s.

Сначала нужно создать ConfigMap, затем вставить ее в pod.

Существует два способа создания ConfigMap - императивный и декларативный: `kubectl create configmap` и `kubectl create -f`.

Создать ConfigMap передав key/value пару непосредственно в команде: `kubectl create configmap app-config --from-literal=APP_COLOR=blue --from-literal=APP_MOD=prod`.

Создать ConfigMap из имеющегося файла: `kubectl create configmap app-config --from-file=app_config.properties`.

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

Пример использования ConfigMap в pod-е:

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
            name: app-config   # все key/value из ConfigMap выше прилетят как environment variables
#     env:
#       - name: APP_COLOR   # имя environment variable в приложении
#         valueFrom:
#           configMapKeyRef:     # вставить только одну определенную key/value пару из ConfigMap
#             name: app-config
#             key: APP_COLOR    # имя environment variable в ConfigMap
#     volumes:
#       - name: app-config-volume
#         configMap:
#           name: app-config     # вставить как volume
```