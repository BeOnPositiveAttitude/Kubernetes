Каким образом мы можем ограничить какие pod-ы на какие ноды можно размещать?

В уроке приведена аналогия с насекомыми и человеком.

Человек (нода) может "нанести" на себя Taint (аэрозоль), чтобы насекомое (pod) не садилось на него.

Однако другое насекомое (pod) может обладать Toleration (терпимостью) к нанесенной на человека (ноду) Taint (аэрозоли) и все равно сесть на человека (ноду).

Например у нас есть кластер из трех нод и четыре pod-а A, B, C, D.

По умолчанию pod-ы не имеют Tolerations ни к каким Taints, и если мы пометим первую ноду кластера `Taint=blue`, тогда ни один pod не сможет быть размещен Scheduler-ом на эту ноду.

Однако мы можем повесить например на pod "D" Toleration к `Taint=blue` и этот pod сможет быть помещен на первую ноду.

Таким образом Taints устанавливаются на ноды, а Tolerations на pod-ы.

`kubectl taint nodes node-name key=value:taint-effect`

taint-effect означает действие над pod-ом, который не имеет Toleration против Taint нанесенного на ноду.

Существует три типа действия над pod-ом в этом случае:

- `NoSchedule` - pod не будет помещен на ноду Scheduler-ом
- `PreferNoSchedule` - система попытается не размещать pod на ноду, но это не гарантированно
- `NoExecute` - новые pod-ы не будут помещаться на ноду Scheduler-ом, а уже существующие на ноде pod-ы, которые не имеют Toleration против Taint нанесенного на ноду, будут "выселены" с ноды (а точнее уничтожены)

`kubectl taint nodes node1 app=blue:NoSchedule`

Пример Tolerations для pod-а приведен ниже. Все значения в секции `tolerations` должны быть в двойных кавычках (хотя в лабе без кавычек).

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: myapp-pod
spec:
  containers:
    - name: nginx-container
      image: nginx
  tolerations:                  #из команды "kubectl taint nodes node1 app=blue:NoSchedule"
    - key: "app"
      operator: "Equal"
      value: "blue"
      effect: "NoSchedule"
```

Запомните, механизм Taints и Tolerations предназначен только для ограничения нод кластера от принятия на себя определенных pod-ов.

Также важно понимать, что применение Taints и Tolerations не означает, что pod гарантированно будет размещен на определенной ноде.

Рассмотрим пример выше, где у нас три ноды и одна имеет Taint=blue и 4 pod-а, из которых pod "D" имеет Toleration к `Taint=blue`.

Pod-ы "A", "B", "C" не будут размещены на ноде с `Taint=blue`, однако и pod "D" с одинаковым успехом может быть размещен и на нодах без `Taint=blue`.

Таким образом нода с `Taint=blue` принимает только pod-ы с Toleration к `Taint=blue`.

Запомните, механизм Taints и Tolerations НЕ указывает pod-у разместиться на определенной ноде! Вместо этого он говорит ноде принимать только pod-ы с определенным Toleration.

Если же нам нужно, чтобы pod размещался на определенной ноде, то это достигается за счет Node Affinity.

После установки кластера мастер нода сразу же получает Taint, благодаря которому pod-ы не размещаются на мастер-ноде, хотя технически это та же worker нода + инструменты управления.

Смотреть Taints на мастер ноде:

`kubectl describe node kubemaster | grep Taint`

Убрать Taint с ноды:

`kubectl taint nodes controlplane node-role.kubernetes.io/control-plane:NoSchedule-`