В K8s мы можем сконфигурировать настройки безопасности на уровне pod-а или на уровне контейнера.

Если настройки безопасности сконфигурированы на уровне pod-а, то эти настройки применятся ко всем контейнерам внутри него.

Если настройки безопасности сконфигурированы на уровне контейнера, то эти настройки переопределяют настройки безопасности заданные на уровне pod-а.

Пример настройки security contexts на уровне pod-а:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: web-pod
spec:
  securityContext:
    runAsUser: 1000
  containers:
    - name: ubuntu
      image: ubuntu
      command: ["sleep", "3600"]
```

Пример настройки security contexts на уровне контейнера:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: web-pod
spec:
  containers:
    - name: ubuntu
      image: ubuntu
      command: ["sleep", "3600"]
      securityContext:
        runAsUser: 1000
        capabilities:
          add: ["MAC_ADMIN", "SYS_TIME"]
```

Capabilities поддерживаются только на уровне контейнера, не на уровне pod-а.

Смотреть под каким пользователем запущен контейнер: `kubectl exec -it ubuntu-sleeper -- whoami`.