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

Проверяем, что шифрование секретов в etcd еще не настроено, если вывод команды пустой, значит не настроено:

`ps -aux | grep kube-api | grep encryption-provider-config`

Или смотрим содержимое файла:

`cat /etc/kubernetes/manifests/kube-apiserver.yaml`