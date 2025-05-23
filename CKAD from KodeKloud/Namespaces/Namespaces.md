При развертывании кластера автоматически создается `default` namespace.

Также K8s создает различные pod-ы и services для своих внутренних нужд (сеть, DNS и т.д.). Чтобы изолировать эти системные pod-ы и services от объектов пользователя, а также защитить их от случайного удаления или изменения, они создаются K8s автоматически в специальном отдельном namespace `kube-system`.

Третий по счету namespace, который создается автоматически, называется `kube-public`, в нем размещаются ресурсы доступные всем пользователям.

В небольших организациях или в учебных кластерах возможно использовать только `default` namespace.

В крупных организациях уже может потребоваться разграничение по разным namespace, например `dev` и `prod`.

Каждый namespace может иметь свой собственный набор политик, определяющий кто и что может делать.

Мы можем выделять определенное количество ресурсов для каждого namespace, соответственно namespace использует строго заданное количество ресурсов и не выйдет за разрешенный лимит.

Объекты внутри одного namespace могу обращаться друг к другу по коротким именам, например `web-pod` может обратиться к Service по имени `db-service` следующим образом: `mysql.connect("db-service")`.

Если этот же `web-pod` из `default` namespace хочет подключиться к Service `db-service`, находящемуся внутри `dev` namespace, строка подключения будет следующей: `mysql.connect("db-service.dev.svc.cluster.local")`.

Это возможно, потому что при создании Service автоматически создается запись в DNS.

- `cluster.local` - доменное имя кластера по умолчанию
- `svc` - поддомен для объектов типа Service
- `dev` - поддомен для namespace
- `db-service` - имя Service

Смотреть pod-ы в заданном namespace:

```shell
$ kubectl get pods --namespace=kube-system
```

Создать pod в заданном namespace:

```shell
$ kubectl create -f pod-definition.yaml --namespace=dev
```

Либо мы можем задать ключ `namespace` в секции `metadata` в pod definition файле.

Создать namespace можно из definition файла:

```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: dev
```

```shell
$ kubectl create -f namespace-dev.yaml
```

Или командой:

```shell
$ kubectl create namespace dev
```

Переключиться в определенный namespace, чтобы не указывать в каждой команде опцию `--namespace`:

```shell
$ kubectl config set-context $(kubectl config current-context) --namespace=dev
```

Contexts используются для управления множеством кластеров из одной консоли.

Смотреть pod-ы сразу во всех namespace-ах:

```shell
$ kubectl get pods --all-namespaces
$ kubectl get pods -A
```

Для ограничения ресурсов в namespace используйте объект ResourceQuota.

```yaml
apiVersion: v1
kind: ResourceQuota
metadata:
  name: compute-quota
  namespace: ckad-ns3
spec:
  hard:
    pods: "10"
    requests.cpu: "4"
    requests.memory: 5Gi
    limits.cpu: "10"
    limits.memory: 10Gi
```