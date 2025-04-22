Кроме деплоя различных объектов в K8s в рамках установки нашего приложения Helm Charts могут делать некоторые дополнительные вещи. Например, при обновлении приложения WordPress может быть автоматически создана резервная копия базы данных перед началом процесса обновления и таким образом у нас будет шанс восстановить данные из бэкапа в случае, если что-то пойдет не так. Это реализуется с помощью Hooks.

Типичный workflow событий в Helm: `helm upgrade` => verify => render => upgrade. Когда пользователь устанавливает или обновляет Chart, сначала Helm верифицирует файлы, затем собирает итоговые manifest-файлы и в конце разворачивает объекты в кластере (фаза обновления). Наша задача выполнить бэкап БД непосредственно перед началом установки Chart (фазы обновления). Мы используем pre-upgrade hook, который запускает предопределенное действие, это может быть что угодно, в нашем случае - бэкап БД. В процессе выполнения pre-upgrade hook Helm будет ждать его полного завершения и только после этого начнет установку приложения в кластер. После завершения установки приложения (фазы обновления) нам возможно понадобится выполнить какую-либо очистку или послать нотификацию по почте например. Здесь нам понадобится post-upgrade hook, который запускается после успешного завершения фазы обновления.

Аналогично при выполнении команды установки приложения `helm install` могут запускаться pre-install и post-install hooks, pre-delete и post-delete hooks при удалении приложения, pre-rollback и post-rollback при откате приложения.

<img src="flow.png" width="600" height="300"><br>

Каким образом мы можем запустить скрипт для выполнения бэкапа в K8s? С помощью запуска его в pod-е. Однако как мы знаем pod остается запущенным всегда, а нам нужно выполнить скрипт всего один раз. Для этого мы создаем job вместо pod:
```yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: {{ .Release.Name }}-nginx
spec:
  template:
    metadata:
      name: {{ .Release.Name }}-nginx
    spec:
      containers:
      - image: alpine
        name: pre-upgrade-backup-job
        command: [ "/bin/script.sh" ]
      restartPolicy: Never
```

Файл с Job помещается внутри каталога templates нашего Chart. Как мы знаем все файлы внутри каталога templates собираются в manifest-файлы K8s, когда устанавливается Chart. Однако эта Job не будет работать так. Она будет запускаться перед фазой обновления как pre-upgrade hook. Каким образом Helm понимает, что созданная Job является не обычным шаблоном, а pre-upgrade hook-ом? Для этого нужно добавить аннотацию:
```yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: {{ .Release.Name }}-nginx
  annotations:
    "helm.sh/hook": pre-upgrade
spec:
  template:
    metadata:
      name: {{ .Release.Name }}-nginx
    spec:
      containers:
      - image: alpine
        name: pre-upgrade-backup-job
        command: [ "/bin/script.sh" ]
      restartPolicy: Never
```
Теперь эта Job будет запускаться только перед фазой обновления в случае upgrade Chart. Аналогично настраиваются другие типы Hooks.

Иногда нам нужно запускать сразу несколько pre-upgrade hooks, например сначала послать нотификацию по e-mail, затем установить баннер на сайте о проводимых работах и в конце выполнить бэкап БД. Как определить очередность выполнения hooks? Мы можем задать weights для каждого hook. Это может быть положительное или отрицательное число. Helm выстраивает очередность выполнения по возврастанию weights. Например -4, 3, 5. Для этого нужно добавить аннотацию и задать значение в формате string:
```yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: {{ .Release.Name }}-nginx
  annotations:
    "helm.sh/hook": pre-upgrade
    "helm.sh/hook-weight": "5"
spec:
  template:
    metadata:
      name: {{ .Release.Name }}-nginx
    spec:
      containers:
      - image: alpine
        name: pre-upgrade-backup-job
        command: [ "/bin/script.sh" ]
      restartPolicy: Never
```

Стоит заметить, что можно задать одинковое значение для нескольких hooks. Тогда они будут отсортированы по типу ресурса и далее по имени в порядке возрастания.

Что произойдет, когда бэкап job завершится? Ресурс, созданный с помощью hook, job в нашем случае, останется в кластере. Мы можем настроить его дальнейшее удаление с помощью hook deletion policies. Для этого нужно добавить аннотацию:
```yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: {{ .Release.Name }}-nginx
  annotations:
    "helm.sh/hook": pre-upgrade
    "helm.sh/hook-weight": "5"
    "helm.sh/hook-delete-policy": hook-succeeded
spec:
  template:
    metadata:
      name: {{ .Release.Name }}-nginx
    spec:
      containers:
      - image: alpine
        name: pre-upgrade-backup-job
        command: [ "/bin/script.sh" ]
      restartPolicy: Never
```

`hook-succeeded` - удалит ресурс в случае успешного завершения hook, и соответственно не удалит в случае failure. Это может помочь в дальнейшем дебаге проблемы, т.к. объект останется в кластере `hook-failed` - удалит ресурс даже в случае фейла hook. И наконец политика по умолчанию, если она не определена явно, `before-hook-creation` - удаляет предыдущий ресурс перед запуском нового hook. Когда hook запускается первый раз, никаких объектов еще не создано и удалять нечего. Далее например при обновлении pre-upgrade hook создает job для бэкапа БД. При следующем обновлении pre-upgrade hook удалит старый объект K8s. После удаления старой Job будет создана новая.
