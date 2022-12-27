Существует другой тип нагрузки - выполняется определенная задача за небольшой промежуток времени и затем завершается, например создание отчета или обработка изображения

Например в Docker: `docker run ubuntu expr 3 + 2`

Контейнер посчитает число и затем завершится, в выводе команды `docker ps -a` мы увидим статус `Exited (0)` - успешное выполнение

Если запустить такой контейнер в K8s:
```
apiVersion: v1
kind: Pod
metadata:
  name: math-pod
spec:
  containers:
  - image: ubuntu
    name: math-add
    command: ['expr', '3', '+', '2']
  restartPolicy: Always
```
Он будет успешно выполняться, завершаться, а K8s будет его каждый раз перезапускать до достижения treshold значения, т.к. дефолтное поведение pod-а - поддерживать жизнеспособность контейнера

Это поведение задается опцией restartPolicy, значение по умолчанию которой равно `Always`

Мы можем переопределить это значение на `Never` или `OnFailure`, в таком случае K8s не будет перезапускать контейнер

Допустим у нас есть большой dataset, нужно запустить много pod-ов для параллельной обработки данных и убедиться, что в итоге задача успешно выполнена и завершена

Для этого нам нужен "менеджер", который создаст столько pod-ов сколько нужно и убедится, что работа успешно выполнена

Можно провести аналогию с ReplicaSet

ReplicaSet позволяет нам запустить набор pod-ов и поддерживать их в запущенном состоянии

Job в свою очередь позволяет нам запустить набор pod-ов для выполнения задачи до ее успешного завершения

Смотреть job-ы: `kubectl get jobs`

Смотреть pod-ы созданные job-ой: `kubectl get pods`

При этом будет видно, что pod-ы завершили работу, но не перезапускались

Смотреть результат выполнения job-ы: `kubectl logs pod-name`

Удалить job-у: `kubectl delete job math-add-job`, при этом будет удален и соответствующий pod

Если нужно запустить несколько pod-ов, для этого существует параметр `completions`, точнее это количество успешных выполнений требуемой задачи, после которого завершается job-а

По умолчанию pod-ы будут создаваться один за другим, второй pod будет создан только когда завершится первый

Это можно переопределить через параметр `parallelism`, чтобы pod-ы создавались параллельно пачками