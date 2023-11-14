Scheduler имеет алгоритм, который равномерно распределяет pod-ы по нодам, а также принимает во внимание различные условия, которые мы задаем через taints & tolerations, node affinity и т.д. Но как быть, если ничего из этого не удовлетворяет вашим нуждам? Например у вас есть специфическое приложение, которое требует, чтобы его компоненты были размещены на ноды после прохождение дополнительных проверок.

Вы решили, что вам нужен собственный scheduling алгоритм для размещения pod-ов на нодах. Соответственно вы можете добавить в  него свои собственные кастомные условия и проверки.

K8s is highly extensible! Вы можете написать свой собственный K8s scheduler, упаковать его и развернуть в качестве дефолтного или дополнительного scheduler. При таком способе большинство приложений могут идти через дефолтный scheduler, а некоторые определенные приложения, которые вы выберете, будут использовать ваш собственный кастомный scheduler.

Ваш кластер K8s может иметь несколько scheduler-ов одновременно. При создании pod-а или Deployment вы можете проинструктировать K8s, чтобы pod был запланирован определенным scheduler-ом.

Если существует несколько scheduler-ов, то они должны иметь разные названия, чтобы мы могли идентифицировать их как отдельные scheduler-ы. Дефолтный scheduler называется `default-scheduler`. Это имя настроено в конфиг-файле kube-scheduler.

**scheduler-config.yaml**
```yaml
apiVersion: kubescheduler.config.k8s.io/v1
kind: KubeSchedulerConfiguration
profiles:
- schedulerName: default-scheduler
```

Дефолтному scheduler-у оно на самом деле не нужно, т.к. если вы не укажете имя, то автоматически будет задано `default-scheduler`.

Для других scheduler-ов мы можем создать отдельные конфиг-файлы и задать их имена.

**my-scheduler-config.yaml**
```yaml
apiVersion: kubescheduler.config.k8s.io/v1
kind: KubeSchedulerConfiguration
profiles:
- schedulerName: my-scheduler
```

**my-scheduler-2-config.yaml**
```yaml
apiVersion: kubescheduler.config.k8s.io/v1
kind: KubeSchedulerConfiguration
profiles:
- schedulerName: my-scheduler-2
```