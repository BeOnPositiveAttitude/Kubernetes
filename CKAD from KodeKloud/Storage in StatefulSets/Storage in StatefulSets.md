Рассмотрим пример StatefulSet в файле statefulset-definition.yaml

Если мы укажем в секции template какой-либо volume, тогда все pod-ы созданные в рамках этого StatefulSet будут пытаться использовать один и тот же volume. Это возможно, если это действительно нам подходит - вариант когда несколько pod-ов используют shared storage.

Также это зависит от типа созданного volume и используемого provisioner (из урока про Storage Classes), т.к. не все типы storage поддерживают чтение/запись одновременно с нескольких клиентов.

Что если мы хотим для каждого pod-а отдельный volume, как это было описано в примере с репликацией MySQL?

Каждый pod в этом случае требует отдельного PVC. Как мы можем автоматически создавать PVC для каждого pod-а в рамках StatefulSet?

Для этого мы можем использовать Volume Claim Template, по сути это Persistent Volume Claim, но шаблонизированный.

То есть вместо создания PVC вручную и дальнейшего его указания в StatefulSet definition файле, мы переносим описание PVC в сам StatefulSet definition файле в секцию `volumeClaimTemplates`. Пример в файле statefulset-pvc-definition.yaml

Так как секция `volumeClaimTemplates` это массив, мы можем указать несколько шаблонов.

Итак, у нас есть StatefulSet definition файл и Storage Class definition файл. Как это работает?

Когда создан StatefulSet, сначала он создает первый pod, в процессе создания которого создается PVC. PVC ассоциирован со Storage Class, Storage Class выделяет volume в GCP, создает PV, ассоциирует PV с volume в GCP и далее связывает PV и PVC. Далее создается второй pod, Storage Class выделяет новый volume в GCP, создает PV, ассоциирует PV с volume в GCP и далее связывает PV и PVC. Аналогично для третьего pod-а.

Что если pod будет пересоздан? StatefulSet автоматически не удаляет PVC или связанный volume. Он реаттачит pod к тому же самому PVC, к которому pod был приаттачен до этого.