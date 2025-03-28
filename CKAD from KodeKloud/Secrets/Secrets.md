Secrets используются для хранения чувствительных данных в K8s.

Сначала нужно создать Secret, затем вставить его в pod.

Существует два способа создания Secret - императивный и декларативный: `kubectl create secret generic` и `kubectl create -f`.

Создать Secret с помощью команды:

```shell
$ kubectl create secret generic app-secret --from-literal=DB_Host=mysql --from-literal=DB_User=root --from-literal=DB_Password=paswrd
```

Создать Secret из имеющегося файла:

```shell
$ kubectl create secret generic app-confsecretig --from-file=app_secret.properties
```

Закодировать строку в base64:

```shell
$ echo -n 'mysql' | base64
```

Раскодировать строку:

```shell
$ echo -n 'bXlzcWw=' | base64 --decode
```

При создании секрета командой `kubectl create -f` в definition файле мы должны указать уже закодированное значение переменной.

Смотреть секреты:

```shell
$ kubectl get secret app-secret -o yaml
$ kubectl describe secret app-secret
```

Пример манифеста Secret:

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: app-secret
data:
  DB_Host: bXlzcWw=
  DB_User: cm9vdA==
  DB_Password: cGFzd3Jk
```

Пример использования Secret в pod-е.

В данном примере все переменные, заданные в секрете, будут импортированы в переменные окружения pod-а:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: simple-webapp-color
  labels:
    name: simple-webapp-color
spec:
  containers:
  - name: simple-webapp-color
    image: simple-webapp-color
    ports:
    - containerPort: 8080
    envFrom:
    - secretRef:
        name: app-secret
```

Вариант, когда нужно импортировать только определенную переменную из секрета:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: simple-webapp-color
  labels:
    name: simple-webapp-color
spec:
  containers:
  - name: simple-webapp-color
    image: simple-webapp-color
    ports:
    - containerPort: 8080
    env:
    - name: DB_Password      # имя environment variable в нашем приложении
      valueFrom:
        secretKeyRef:
          name: app-secret   # имя секрета
          key: DB_Password   # соответствующий key из секрета
```

Вариант, когда секрет монтируется в виде тома:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: simple-webapp-color
  labels:
    name: simple-webapp-color
spec:
  containers:
  - name: simple-webapp-color
    image: simple-webapp-color
    ports:
    - containerPort: 8080
    volumeMounts:
    - name: app-secret-volume
      mountPath: "/etc/my-super-secret"
  volumes:
  - name: app-secret-volume
    secret:
      secretName: app-secret   # имя секрета
```

Если секрет монтируется как volume, в точке монтирования будут созданы файлы с именем равным key, и внутри них вы найдете значение value.

Секреты не шифруют данные, а только кодируют, соответственно любой человек может их раскодировать обратно. Поэтому не стоит помещать секреты в SCM наравне с вашим кодом.

По умолчанию секреты не шифруются в etcd, но шифрование можно настроить по документации: [Encrypting Secret Data at Rest](https://kubernetes.io/docs/tasks/administer-cluster/encrypt-data/)

Любой кто может создавать Deployments/Pods в том же namespace может смотреть и секреты. Для предотвращения подобной ситуации нужно настроить привилегии - RBAC.

Также стоит рассмотреть third-party провайдера для хранения секретов не в etcd, а например в Vault.

Также сам K8s обрабатывает секреты следующим способом:
- секрет посылается ноде, только если pod на этой ноде требует его
- kubelet хранит секрет в tmpfs, таким образом секрет не записывается на диск
- если pod зависящий от секрета удален, kubelet также удалит локальную копию секрета