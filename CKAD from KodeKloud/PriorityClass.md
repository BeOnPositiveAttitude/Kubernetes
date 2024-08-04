Pod-у можно задать PriorityClass, который заранее должен быть определен в кластере.

Смотреть список PriorityClasses: `kubectl get pc`.

Чем выше значение Priority у pod-а, тем выше его приоритет.

Например, если мы создадим pod с приоритетом `30000`, то при недостаточном количестве ресурсов на worker-ноде он вытеснит pod с меньшим приоритетом (`20000`).

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: important
  namespace: lion
spec:
  priorityClassName: level3
  containers:
  - image: nginx:1.21.6-alpine
    name: important
    resources:
      requests:
        memory: 1Gi
```