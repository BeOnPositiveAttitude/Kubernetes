ETCD хранит информацию касательно кластера, такую как nodes, pods, configs, secrets, accounts, roles, role bindings и др. Любая информация, которую вы видите при запуске команды `kubectl get`, поступает от etcd-сервера. Каждое изменение, которое вы вносите в кластер, например добавление дополнительной ноды, деплой pod-а или ReplicaSet, обновляется в etcd-сервере. Только после обновления в etcd-сервере изменение считается завершенным.

В зависимости от того как вы разворачиваете кластер, etcd разворачивается по-разному. В процессе данного курса мы обсудим два типа развертывания. Один разворачивается с нуля (from scratch), другой с помощью инструмента *kubeadm*. Тестовая среда для практики разворачивалась с помощью инструмента kubeadm. Далее в нашем курсе, когда мы будем устанавливать кластер, мы будет делать это с нуля. Поэтому хорошо знать отличия между этими двумя методами.

Если вы устанавливаете кластер с нуля, тогда необходимо разворачивать etcd с помощью самостоятельной загрузки бинарных файлов etcd, их установкой и конфигурированием etcd в качестве сервиса на master-нодах вручную.

<img src="image.png" width="900" height="450"><br>

В сервис передается множество опций, некоторое их количество относится к сертификатам. Другие относятся к конфигурированию etcd в качестве кластера.

Сейчас мы отметим только одну опцию `--advertise-client-urls`. Это адрес, на котором слушает etcd. Это может быть IP сервера и порт 2379, который является дефолтным портом, на котором слушает etcd. Это URL, который должен быть сконфигурирован на kube-apiserver, когда он пытается достучаться до сервера etcd.

Если вы устанавливаете кластер с помощью kubeadm, то данная утилита разворачивает etcd в качестве pod-а в namespace `kube-system`.

Вы можете исследовать БД etcd с помощью утилиты etcdctl в этом pod-е.

Для отображения всех ключей сохраненных K8s, выполните команду:

`kubectl exec etcd-master -n kube-system etcdctl get / --prefix -keys-only`

K8s хранит данные в определенной структуре каталогов. Корневой каталог - это реестр и под ним находятся различные K8s конструкции, такие как minions или nodes, pods, replicasets, deployments и т.д.

<img src="image-1.png" width="700" height="450"><br>

В high availability окружении у вас будет несколько master-нод в кластере, поэтому у вас несколько экземпляров etcd, распространенных по mater-нодам. В этом случае необходимо убедиться, что экземпляры etcd знают друг о друге. Достигается это с помощью параметра `--initial-cluster` в конфигурации сервиса etcd. Здесь вы должны указать различные экземпляры etcd.

<img src="image-2.png" width="900" height="450"><br>

---
---

For example, etcdctl version 2 supports the following commands:

```bash
etcdctl backup
etcdctl cluster-health
etcdctl mk
etcdctl mkdir
etcdctl set
```

Whereas the commands are different in version 3:

```bash
etcdctl snapshot save
etcdctl endpoint health
etcdctl get
etcdctl put
```

When the API version is not set, it is assumed to be set to version 2.

Apart from that, you must also specify the path to certificate files so that etcdctl can authenticate to the etcd API Server. The certificate files are available in the etcd-master at the following path:

```bash
--cacert /etc/kubernetes/pki/etcd/ca.crt
--cert /etc/kubernetes/pki/etcd/server.crt
--key /etc/kubernetes/pki/etcd/server.key
```

So for the commands, I showed in the previous video to work you must specify the etcdctl API version and path to certificate files. Below is the final form:

`kubectl exec etcd-controlplane -n kube-system -- sh -c "ETCDCTL_API=3 etcdctl get / --prefix --keys-only --limit=10 --cacert /etc/kubernetes/pki/etcd/ca.crt --cert /etc/kubernetes/pki/etcd/server.crt --key /etc/kubernetes/pki/etcd/server.key"`