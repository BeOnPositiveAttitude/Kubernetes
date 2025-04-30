Когда мы впервые создаем deployment, это вызывает rollout (выкатывание). Новый rollout создает новый deployment revision (например Revision 1).

Предположим мы обновили приложение в контейнере, это вызовет новый rollout и будет создан новый deployment revision (например Revision 2).

Это помогает нам отслеживать изменения в Deployment и позволяет в случае надобности откатиться на предыдущую версию.

Смотреть статус rollout:

```shell
kubectl rollout status deployment/myapp-deployment
```

Смотреть историю rollout:

```shell
kubectl rollout history deployment/myapp-deployment
```

Существует два типа Deployment Strategy:

- `Recreate` - сначала убить все контейнеры со старой версией приложения и затем поднять новые, приводит к простою, не является дефолтной стратегией
- `RollingUpdate` - поочередно обновлять контейнер за контейнером, не приводит к простою. Если не указать Deployment Strategy явно, то будет использована именно `RollingUpdate`


`.spec.strategy.rollingUpdate.maxUnavailable` is an optional field that specifies the maximum number of Pods that can be unavailable during the update process. The value can be an absolute number (for example, `5`) or a percentage of desired Pods (for example, `10%`).

`.spec.strategy.rollingUpdate.maxSurge` is an optional field that specifies the maximum number of Pods that can be created over the desired number of Pods. The value can be an absolute number (for example, `5`) or a percentage of desired Pods (for example, `10%`).

Here are some Rolling Update Deployment examples that use the maxUnavailable and maxSurge:

Как выполнить обновление приложения? Можно отредактировать yaml-файл и выполнить команду:

```shell
kubectl apply -f deployment-definition.yaml
```

Это вызовет новый rollout (выкатывание) и будет создан новый deployment revision.

Или можно обновить версию образа для запущенного Deployment (при этом в yaml-файле ничего не изменится), `nginx` - имя контейнера, `nginx:1.9.1` - имя образа:

```shell
kubectl set image deployment/myapp-deployment nginx=nginx:1.9.1
```

При обновлении нашего приложения Deployment создает новую ReplicaSet, в которой начинают создаваться pod-ы с новой версией приложения, при этом в старой ReplicaSet pod-ы будут по одному убиваться по мере появления новых (Rolling Update).

Откатить изменения на предыдущий revision:

```shell
kubectl rollout undo deployment/myapp-deployment
```

При откате pod-ы в новой RS будут поочередно удаляться, а pod-ы в старой RS подниматься.

При этом номер revision на которую мы откатились исчезнет из history и станет последней текущей версией.