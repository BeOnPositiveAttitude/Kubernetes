Secrets используются для хранения чувствительных данных в K8s

Сначала нужно создать Secret, затем вставить его в pod

Существует два способа создания Secret - императивный и декларативный:

`kubectl create secret generic` и `kubectl create -f`

Создать Secret с помощью команды:

`kubectl create secret generic app-secret --from-literal=DB_Host=mysql --from-literal=DB_User=root --from-literal=DB_Password=paswrd`

Создать Secret из имеющегося файла:

`kubectl create secret generic app-confsecretig --from-file=app_secret.properties`

Закодировать:

`echo -n 'mysql' | base64`

Раскодировать:

`echo -n 'bXlzcWw=' | base64 --decode`

При создании секрета командой `kubectl create -f` в definition файле мы должны указать уже закодированное значение переменной

Смотреть секреты:

`kubectl get secret app-secret -o yaml` и `kubectl describe secret app-secret`

Если Secret монтируется как volume, в точке монтирования будут созданы файлы с именем Key, и внутри них вы найдете значение Value

Секреты не шифруют данные, а только кодируют, соответственно любой человек может их раскодировать обратно

Поэтому не стоит помещать секреты в SCM наравне с вашим кодом

По умолчанию секреты не шифруются в etcd, но шифрование можно настроить по документации:
[Encrypting Secret Data at Rest](https://kubernetes.io/docs/tasks/administer-cluster/encrypt-data/)

Любой кто может создавать Deployments/Pods в том же namespace может смотреть и секреты

Для предотвращения подобной ситуации нужно настроить привилегии - RBAC

Также стоит рассмотреть third-party провайдера для хранения секретов не в etcd, например Vault

Также сам K8s обрабатывает секреты следующим способом:

Секрет посылается ноде, только если pod на этой ноде требует его

Kubelet хранит секрет в tmpfs, таким образом секрет не записывается в storage

Если pod зависящий от секрета удален, kubelet также удалит локальную копию секрета