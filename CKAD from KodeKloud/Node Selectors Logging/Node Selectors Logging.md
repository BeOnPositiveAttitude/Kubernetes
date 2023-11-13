Пример, у нас есть три ноды в кластере, одна "большая" по ресурсам и две маленькие, а также у нас есть ресурсоемкое приложение, которое мы хотим разместить на "большой" ноде

В этом случае нам поможет поле `nodeSelector`, пример в файле pod-definition.yaml

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: myapp-pod
spec:
  containers:
    - name: data-processor
      image: data-processor
  nodeSelector:
    size: Large
```

Но каким образом K8s знает какая нода считается Large?

Применяется механизм Labels, которыми маркируются ноды и в дальнейшем Scheduler ориентируется по этим Labels на какие ноды назначать pod-ы

`kubectl label nodes <node-name> <label-key>=<label-value>`

`kubectl label nodes node-1 size=Large`

Наличие Label на ноде не означает, что другие pod-ы (без поля nodeSelector) не могу быть размещены на этой ноде

Недостаток Node Selectors - можно задать только один Label, соответственно если требуется использовать более сложные условия, например поместить pod на Large или Medium ноду, или поместить pod НЕ на Small ноду, тогда Node Selectors нам не подойдет

Для этого существует механизм Node Affinity