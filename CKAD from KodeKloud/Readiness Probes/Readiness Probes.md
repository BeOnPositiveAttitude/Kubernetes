Pod имеет Status жизненного цикла и несколько Conditions

Когда pod создается впервые он находится в статусе Pending, в этот момент Scheduler пытается понять куда разместить pod

Если pod не удается никуда разместить, он так и остается в статусе Pending

Когда pod определен на какую-либо ноду он переходит в статус ContainerCreating, где скачивается нужный образ и контейнер стартует

Когда все контейнеры в pod-е запущены, pod переходит в статус Running до успешного завершения приложения или пока pod не будет уничтожен

Conditions дополняют информацию о статусе pod-а

Conditions - это массив True/False значений, которые говорят нам о статусе pod-а

- PodScheduled - если True, значит pod запланирован к размещение на ноде
- Initialized - если True, значит pod проинициализирован
- ContainersReady - если True, значит все контейнеры в pod-е готовы
- Ready - если True, значит сам pod готов, приложение внутри pod-а запущено и готово принимать пользовательский трафик

Смотреть Conditions:

`kubectl describe pod pod-name`

Внутри pod-а может находиться скрипт, который выполняется за считанные миллисекунды, а может быть и приложение аля Jenkins, инициализация и запуск которого занимает несколько минут, при этом сам pod уже давно находится в статусе Ready, что не совсем соответствует действительности

Допустим мы опубликовали наше приложение в pod-е через Service, как только Condition "Ready" нашего pod-а станет True, объект Service, опираясь на этот Condition, сразу начнет маршрутизировать трафик на наш pod

Таким образом нам нужно определять, действительно ли Condition "Ready" нашего pod-а соответствует готовности приложения внутри pod-а?

Существуют различные вариант проверки готовности приложения, например HTTP Test до API приложения, TCP Test до определенного порта, запуск скрипта внутри контейнера, который проверяет статус приложения и упешно завершается в случае готовности

В K8s существует механизм readinessProbes, пример в файле pod-definition.yaml

Таким образом до тех пор, пока не выполнится условие readinessProbe, K8s не установит Condition "Ready" нашего pod-а в значение True

Соответственно Service не будет маршрутизировать трафик на наш pod, т.к. его статус еще не Ready

Это особенно полезно в случае, когда у нас есть Deployment или ReplicaSet и несколько pod-ов, а также Service, который направляет пользовательский трафик на эти pod-ы

Если мы захотим добавить новый pod, то без использования Readiness Probe, Service сразу начнет часть запросов направлять на новый pod, приложение в котором фактически еще не готово принимать трафик, это приведет к деградации нашего приложения

**Readiness Probe работает на протяжении всего жизненного цикла pod-а.**

Which of the following would be the result/state of a probe?

- SUCCESS
- UNKNOWN
- FAILURE