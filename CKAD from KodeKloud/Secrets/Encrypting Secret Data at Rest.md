Подключаемся к pod-у с etcd командой:

`kubectl exec -it etcd-minikube -n kube-system -- sh`

Мы можем увидеть, что секрет my-secret в etcd хранится в незашифрованном виде:

```
ETCDCTL_API=3 etcdctl \
   --cacert=/var/lib/minikube/certs/etcd/ca.crt   \
   --cert=/var/lib/minikube/certs/etcd/server.crt \
   --key=/var/lib/minikube/certs/etcd/server.key  \
   get /registry/secrets/default/my-secret
```

Подключаемся `minikube ssh` и проверяем, что шифрование секретов в etcd еще не настроено, если вывод команды пустой, значит не настроено:

`ps -aux | grep kube-api | grep encryption-provider-config`

Или смотрим содержимое файла:

`cat /etc/kubernetes/manifests/kube-apiserver.yaml`

Генерируем ключ командой:

`head -c 32 /dev/urandom | base64`

Создаем из под root-а каталог `mkdir /etc/kubernetes/enc`

Внутри создаем наш файл enc.yaml

Редактируем файл `vi /etc/kubernetes/manifests/kube-apiserver.yaml`

Добавляем в него строки:

`- --encryption-provider-config=/etc/kubernetes/enc/enc.yaml` в секцию commands

В секцию volumeMounts:
```
- name: enc
  mountPath: /etc/kubernetes/enc
  readonly: true
```

В секцию volumes:
```
- name: enc
  hostPath:
    path: /etc/kubernetes/enc
    type: DirectoryOrCreate
```

После этого pod с apiserver должен автоматически перезапуститься и подхватить изменения

Проверяем, создаем новый секрет командой:

`kubectl create secret generic my-secret-2 --from-literal=key2=topsecret`

Подключаемся к pod-у с etcd

Мы можем увидеть, что теперь секрет my-secret-2 в etcd хранится в зашифрованном виде:

```
ETCDCTL_API=3 etcdctl \
   --cacert=/var/lib/minikube/certs/etcd/ca.crt   \
   --cert=/var/lib/minikube/certs/etcd/server.crt \
   --key=/var/lib/minikube/certs/etcd/server.key  \
   get /registry/secrets/default/my-secret-2
```

Шифроваться будут только вновь создаваемые секреты, старые останутся незашифрованными

Можно пересоздать старые секреты командой:

`kubectl get secrets --all-namespaces -o json | kubectl replace -f -`