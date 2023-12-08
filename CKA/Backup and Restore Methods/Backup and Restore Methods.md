<img src="image.png" width="600" height="200"><br>

При создании объектов в кластере мы можем использовать как императивный, так и декларативный подходы. Если вы хотите сохранить свою конфигурацию, более предпочтительным является декларативный подход. Хорошей практикой является хранение object definition файлов в репозитории. Репозиторий в свою очередь должен бекапироваться.

Но, не смотря на то, что декларативный подход является предпочтительным, это вовсе не означает, что все члены вашей команды будут его придерживаться. Что если кто-то из коллег создаст объект императивным способом без документирования этой информации где-либо?

Более подходящий способ для бекапирования конфигурации ресурсов - использовать запрос к apiserver с помощью утилиты kubectl или прямым вызовом API.

Сохранить конфигурацию всех Deployments, Services и Pods во всех namespace: `kubectl get all --all-namespaces -o yaml > all-deploy-services.yaml`.

И это только для некоторых resource groups. Существует множество других resource groups, которые должны учитываться. Для существует инструмент *Velero*.

Перейдем к etcd. Etcd хранит информацию о состоянии нашего кластера, его нод, каждого ресурса созданного в нем. Вместо бекапирования ресурсов описанного в предыдущем подходе, вы можете выбрать бекапирование самого etcd-сервера.

Etcd-кластер располагается на master-нодах. При конфигурировании etcd мы указываем путь, где будут храниться все данные. Эта директория может быть настроена для бекапа с помощью вашего инструмента бекапирования.

<img src="image-1.png" width="400" height="300"><br>

Также у etcd есть встроенное решения для создания snapshot-ов.

Создать snapshot БД etcd: `ETCDCTL_API=3 etcdctl snapshot save snapshot.db`. Файл `snapshot.db` будет создан в текущей директории. Если нужно создать файл в другом каталоге, укажите полный путь.

Посмотреть статус бекапа: `ETCDCTL_API=3 etcdctl snapshot status snapshot.db`.

Для восстановление кластера из бекапа сначала нужно остановить kube-apiserver: `service kube-apiserver stop`, т.к. процесс восстановления потребует рестарта etcd-кластера, а kube-apiserver зависит от него.

Затем выполняем команду: `ETCDCTL_API=3 etcdctl snapshot restore snapshot.db --data-dir=/var/lib/etcd-from-backup`.

Когда etcd восстанавливается из бекапа, он инициализирует новую конфигурацию кластера и настраивает членов etcd как новых членов нового кластера. Это сделано для предотвращения случайного присоединения нового участника к существующему кластеру. При запуске данной команды будет создана новая data directory `/var/lib/etcd-from-backup`.

Затем мы настраиваем конфигурацию etcd для использования новой data directory.

<img src="image-2.png" width="400" height="300"><br>

Затем перезапускаем сервис etcd:

```bash
systemctl daemon-reload
service etcd restart
```

И в конце запускаем kube-apiserver: `service kube-apiserver start`. После этого кластер должен вернуться в исходное состояние.

Для всех etcd-команд нужно указывать файлы сертификатов для аутентификации, endpoint для etcd-кластера и ключ.

```bash
ETCDCTL_API=3 etcdctl \
  snapshot save snapshot.db \
  --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/etcd/ca.crt \
  --cert=/etc/etcd/etcd-server.crt \
  --key=/etc/etcd/etcd-server.key
```

Если вы используете managed K8s окружение, то у вас может не быть доступа к etcd-кластеру. В этом случае бэкап с помощью запроса к kube-apiserver возможно будет более подходящим решением.

Помощь по командам etcd: `etcdctl snapshot save -h`. Плюс можно задать переменную окружения сразу для всей сессии: `export ETCDCTL_API=3`.

Узнать версию etcd в кластере можно двумя способами. Посмотреть логи pod-а:

`kubectl -n kube-system logs etcd-controlplane | grep -i 'etcd-version'`

Либо посмотреть версию образа: `kubectl -n kube-system describe pod etcd-controlplane | grep Image:`.

Посмотреть по какому адресу доступен etcd для подключения: `kubectl describe pod etcd-controlplane -n kube-system` и смотрим на опцию `--listen-client-urls`.

Посмотреть где лежит серверный сертификат etcd: `kubectl describe pod etcd-controlplane -n kube-system` и смотрим на опцию `--cert-file`.

Посмотреть где лежит серверный сертификат etcd: `kubectl describe pod etcd-controlplane -n kube-system` и смотрим на опцию `--trusted-ca-file`.

Сделать snapshot можно непосредственно с master-ноды:

```bash
etcdctl --endpoints=https://[127.0.0.1]:2379 \
--cacert=/etc/kubernetes/pki/etcd/ca.crt \
--cert=/etc/kubernetes/pki/etcd/server.crt \
--key=/etc/kubernetes/pki/etcd/server.key \
snapshot save /opt/snapshot-pre-boot.db
```

Восстановить из snapshot сервер etcd: `ETCDCTL_API=3 etcdctl snapshot restore /opt/snapshot-pre-boot.db --data-dir /var/lib/etcd-from-backup`. В случае восстановления из snapshot мы не взаимодействуем непосредственно с etcd, поэтому не указываем файлы сертификатов и ключа.

В опции `--data-dir` указываем путь до нового каталога `/var/lib/etcd-from-backup`, который будет создан автоматически.

Обновляем файл манифеста `/etc/kubernetes/manifests/etcd.yaml`. Т.к. мы восстановили snapshot etcd по новому пути на master-ноде - `/var/lib/etcd-from-backup`, поэтому нужно изменить значение `hostPath` для volume под названием `etcd-data`:

```yaml
  volumes:
  - hostPath:
      path: /var/lib/etcd-from-backup
      type: DirectoryOrCreate
    name: etcd-data
```

Теперь каталог `/var/lib/etcd` в контейнере будет мапиться на каталог `/var/lib/etcd-from-backup` на master-ноде.

После обновления манифеста etcd pod будет автоматически пересоздан, т.к. это статический pod из каталога `/etc/kubernetes/manifests`.

Т.к. pod etcd изменился, он будет автоматически перезапущен, а также pod-ы kube-controller-manager и kube-scheduler.

Командой `watch "crictl ps | grep etcd"` можно смотреть статус перезапуска pod-ов.

---
---

This means that ETCD is set up as a *Stacked ETCD Topology* where the distributed data storage cluster provided by etcd is stacked on top of the cluster formed by the nodes managed by kubeadm that run control plane components.

Смотреть членов кластера etcd:

```bash
ETCDCTL_API=3 etcdctl \
--endpoints=https://127.0.0.1:2379 \
--cacert=/etc/etcd/pki/ca.pem \
--cert=/etc/etcd/pki/etcd.pem \
--key=/etc/etcd/pki/etcd-key.pem \
member list
```
---
---

В случае если сервер etcd является внешним по отношению к кластеру K8s, шаги восстановление из snapshot следующие.

Восстанавливаемся из snapshot в новую директорию:

`ETCDCTL_API=3 etcdctl --endpoints=https://127.0.0.1:2379 --cacert=/etc/etcd/pki/ca.pem --cert=/etc/etcd/pki/etcd.pem --key=/etc/etcd/pki/etcd-key.pem snapshot restore /opt/cluster2.db --data-dir /var/lib/etcd-data-new`

Редактируем файл сервиса: `/etc/systemd/system/etcd.service` и меняем значение `--data-dir` на новое:

```bash
[Unit]
Description=etcd key-value store
Documentation=https://github.com/etcd-io/etcd
After=network.target

[Service]
User=etcd
Type=notify
ExecStart=/usr/local/bin/etcd \
  --name etcd-server \
  --data-dir=/var/lib/etcd-data-new \
...
```

Рекурсивно меняем владельца новой директории на etcd: `chown -R etcd:etcd /var/lib/etcd-data-new`.

В конце перезапускаем сервис: `systemctl daemon-reload` и `service etcd restart`.

(Optional): It is recommended to restart controlplane components (e.g. kube-scheduler, kube-controller-manager, kubelet) to ensure that they don't rely on some stale data.