ConfigMaps используются для передачи конфигурационных данных в формате пары key/value в K8s

Сначала нужно создать ConfigMap, затем вставить ее в pod

Существует два способа создания ConfigMap - императивный и декларативный:

`kubectl create configmap` и `kubectl create -f`

Создать ConfigMap передав key/value пару непосредственно в команде:

`kubectl create configmap app-config --from-literal=APP_COLOR=blue --from-literal=APP_MOD=prod`

Создать ConfigMap из имеющегося файла:

`kubectl create configmap app-config --from-file=app_config.properties`

Смотреть ConfigMap:

`kubectl get configmaps` и `kubectl describe configmaps`