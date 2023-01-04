Persistent Volumes и Persistent Volume Claims - два отдельных объекта в K8s namespace

Администратор создает набор Persistent Volumes, а пользователи создают Persistent Volume Claims, чтобы использовать storage

Как только создан Persistent Volume Claims, K8s связывает Persistent Volume с Claim, основываясь на запросе и свойствах volume

Каждый Persistent Volume Claim связан с одним Persistent Volume

В процессе связывания K8s пытается найти Persistent Volume, соответствующий емкости, запрошенной в Claim, а также другим параметрам - Access Modes, Volume Modes, Storage Class и т.д.

В случае если для Claim найдено несколько возможных совпадений, но мы хотим определенный volume, возможно использовать Labels & Selectors

Для PV указываем Labels:
```
labels:
  name: my-pv
```

Для PVC указываем Selector:
```
selector:
  matchLabels:
    name: my-pv
```

Стоит заметить, что меньший Claim может быть связан с бОльшим Volume, если удовлетворяют все остальные критерии и нет более подходящих вариантов. В этом случае другие Claims не могут использовать оставшееся место в этом Volume

Это отношение один-к-одному между Claims и Volumes

В случае если для Persistent Volume Claim не нашлось подходящего Volume, этот PVC останется в статусе Pending до тех пор пока в кластере не появятся новые подходящие Volumes

Как только в кластере появится новый подходящий Volume, тогда PVC автоматически будет связан с этим новым Volume

Смотреть PVC: `kubectl get pvc`

Пример PVC приведен в файле pvc-definition.yaml, в предыдущем уроке мы определили PV в файле pv-definition.yaml, в итоге AccessModes совпадают, запрошенная в Claim емкость 500Mi, емкость Volume 1Gi, но т.к. более подходящих Volumes нет, поэтому PVC будет связан с PV

Удалить PVC: `kubectl delete pvc myclaim`

Что произойдет с нижестоящим Persistent Volume, если будет удален PVC? Вы можете определить это поведение с помощью параметра `persistentVolumeReclaimPolicy`, по умолчанию он имеет значение `Retain`. Это означает, что PV будет храниться, пока не будет удален администратором, при этом он недоступен для переиспользования другими PVC или может быть удален автоматически (значение `Delete`)

Соответственно при удалении PVC будет удален и Volume, а место на конечном storage device будет освобождено

Третий вариант значения этой политики `Recycle`, данные в Volume будут очищены перед тем как сделать его доступным для других PVC