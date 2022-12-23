Что если указанное для pod-а nodeAffinity не соответствует Label-у ни одной ноды?

Что если кто-то в будущем изменит Laber у ноды? Останутся ли pod-ы на ноде?

Ответ на этот вопрос кроется в свойстве идущем после ключа nodeAffinity в pod-definition.yaml - тип nodeAffinity

Тип nodeAffinity определяет поведение Scheduler-а

Существует два типа nodeAffinity - requiredDuringSchedulingIgnoredDuringExecution и preferredDuringSchedulingIgnoredDuringExecution

Также планируется добавить третий типа - requiredDuringSchedulingRequiredDuringExecution

С точки зрения nodeAffinity для pod-а существует два этапа жизненного цикла - DuringScheduling и DuringExecution

DuringScheduling - когда pod не существует и создается впервые

Предположим мы забыли пометить ноду Label-ом Large, что произойдет? Здесь вступают в игру типы nodeAffinity

requiredDuringScheduling накажет поместить pod на ноду, подходящую под правило указанное в блоке affinity этого pod-а, и если не найдет, то просто не разместит pod на ноду, используется в случае когда обязательно размещение pod-а именно на определенной ноде

preferredDuringScheduling используется, если важнее разместить нагрузку куда-либо, то есть если не будет найдена соответствующая нода, тогда pod будет размещен на любую доступную

Вторая часть этого свойства IgnoredDuringExecution вступает в действие, когда pod уже размещен на ноде, но например изменился Label ноды

Доступные на текущий момент два типа nodeAffinity говорят - ничего не делать с pod-ом если он уже размещен на ноде Scheduler-ом

Третий типа nodeAffinity, который планируется добавить в будущем requiredDuringSchedulingRequiredDuringExecution, говорит - в случае изменения Label ноды следует "выселить" или разрушить pod-ы, которые уже размещены на этой ноде