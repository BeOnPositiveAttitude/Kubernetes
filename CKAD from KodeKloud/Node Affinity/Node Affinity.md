Механизм Node Affinity предоставляет нам расширенные возможности для ограничения размещения pod-ов на определенные ноды.

With great power comes great complexity!

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: myapp-pod
spec:
  containers:
    - name: data-processor
      image: data-processor
  affinity:
    nodeAffinity:
      requiredDuringSchedulingIgnoredDuringExecution:
        nodeSelectorTerms:
          - matchExpressions:
              - key: size
                operator: In   # pod будет помещен на ноду, у которой Label "size" имеет значение из указанного списка, т.е. это будет либо Large либо Medium нода
                values:
                  - Large
                  - Medium
```

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: myapp-pod
spec:
  containers:
    - name: data-processor
      image: data-processor
  affinity:
    nodeAffinity:
      requiredDuringSchedulingIgnoredDuringExecution:
        nodeSelectorTerms:
          - matchExpressions:
              - key: size
                operator: NotIn   # pod будет помещен на ноду, у которой Label "size" НЕ равен Small
                values:
                  - Small
```

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: myapp-pod
spec:
  containers:
    - name: data-processor
      image: data-processor
  affinity:
    nodeAffinity:
      requiredDuringSchedulingIgnoredDuringExecution:
        nodeSelectorTerms:
          - matchExpressions:
              - key: size
                operator: Exists   # pod будет помещен на ноду, у которой вообще есть Label "size", значение не проверяется
```

Что если указанное для pod-а `nodeAffinity` не соответствует Label-у ни одной ноды?

Что если кто-то в будущем изменит Label у ноды? Останутся ли pod-ы на ноде?

Ответ на этот вопрос кроется в свойстве идущем после свойства `nodeAffinity` - типе `nodeAffinity`.

Тип `nodeAffinity` определяет дальнейшее поведение Scheduler-а.

Существует два типа `nodeAffinity` - `requiredDuringSchedulingIgnoredDuringExecution` и `preferredDuringSchedulingIgnoredDuringExecution`.

Также планируется добавить еще два типа - `requiredDuringSchedulingRequiredDuringExecution` и `preferredDuringSchedulingRequiredDuringExecution`.

С точки зрения `nodeAffinity` для pod-а существует два этапа жизненного цикла - `DuringScheduling` и `DuringExecution`.

`DuringScheduling` - когда pod не существует и создается впервые.

Предположим мы забыли пометить ноду Label-ом `Large`, что произойдет? Здесь вступают в игру типы `nodeAffinity`.

`requiredDuringScheduling` накажет поместить pod на ноду, подходящую под правило указанное в блоке affinity этого pod-а, и если не найдет, то просто не разместит pod на ноду, используется в случае когда обязательно размещение pod-а именно на определенной ноде.

`preferredDuringScheduling` используется, если важнее разместить нагрузку куда-либо, то есть если не будет найдена соответствующая нода, тогда pod будет размещен на любую доступную.

Вторая часть этого свойства `IgnoredDuringExecution` вступает в действие, когда pod уже размещен на ноде, но например изменился Label ноды.

Доступные на текущий момент два типа `nodeAffinity` говорят - ничего не делать с pod-ом если он уже размещен на ноде Scheduler-ом.

Два новых типа `nodeAffinity`, которые планируется добавить в будущем, говорят - в случае изменения Label ноды следует "выселить" или разрушить pod-ы, которые уже размещены на этой ноде.