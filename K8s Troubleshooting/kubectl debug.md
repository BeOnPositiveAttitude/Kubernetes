`kubectl debug` позволяет подключить контейнер к существующему запущенному pod-у.

Вы разумеется можете подумать "зачем использовать `kubectl debug`, если я могу подключиться к контейнеру в pod-е напрямую с помощью `kubectl exec` и выполнять команды прямо в нем"?

Первая причина - **минимизировать сбои** pod-ов в production-окружении. Представим, что у нас есть pod, в котором мы начали выполнять различные debug-команды и случайно запустили команду, которая "вмешалась" в процесс, обслуживающий production трафик. С помощью `kubectl debug` мы можем подключить контейнер к существующему контейнеру без влияния на запущенную нагрузку.

Вторая причина - когда у нас есть **distroless-образы**, запущенные в pod-ах. Distroless-образы - это максимально "голые" образы, которые имеют на борту только те зависимости, которые требуются непосредственно для работы приложения. Такие образы могут вовсе не иметь какого-либо shell и соответственно каких-либо инструментов для траблшутинга. Причина использования distroless-образов - это хорошая security practice, т.к. минимизируется поверхность атаки (attack surface). Также это улучшает производительность, т.к. образы намного меньше по размеру.

Третья причина - когда у нас есть **"падающие" контейнеры** и мы не успеваем подключиться к ним с помощью `kubectl exec`.

Кроме того `kubectl debug` можно использовать для дебага чего-либо на нодах.

```shell
$ kubectl debug -it distroless-pod --image=busybox
```

Здесь `distroless-pod` - название pod-а, который нам нужно дебажить, `busybox` - имя образа, содержащего необходимые нам для дебага инструменты. Debug-контейнер получит название `debugger-xxxxx`.

При выходе из debug-контейнера мы получим сообщение:

```shell
Session ended, the ephemeral container will not be restarted but may be reattached using 'kubectl attach distroless-pod -c debugger-25snh -i -t' if it is still running
```

Т.е. при необходимости мы сможем к нему переподключиться.

С помощью опции `--target` мы можем указать debug-контейнеру имя целевого контейнера, который мы хотим дебажить. Таким образом главный контейнер и debug-контейнер будут разделять общий process namespace.

Сначала проверим как выглядит список процессов в debug-контейнере без использования опции `--target`. Запустим pod с nginx:

```shell
$ kubectl run nginx-pod --image=nginx
```

Подключимся к нему через debug:

```shell
$ kubectl debug -it nginx-pod --image=busybox
Defaulting debug container name to debugger-p5c4p.
If you don't see a command prompt, try pressing enter.
/ # ps aux
PID   USER     TIME  COMMAND
    1 root      0:00 sh
    7 root      0:00 ps aux
```

Теперь проверим с опцией `--target`. В опции `--target` указываем название целевого **контейнера**.

```shell
$ kubectl debug -it nginx-pod --image=busybox --target=nginx
Targeting container "nginx". If you don't see processes from this container it may be because the container runtime doesn't support this feature.
Defaulting debug container name to debugger-zqhff.
If you don't see a command prompt, try pressing enter.
/ # ps aux
PID   USER     TIME  COMMAND
    1 root      0:00 nginx: master process nginx -g daemon off;
   28 101       0:00 nginx: worker process
   29 101       0:00 nginx: worker process
   30 root      0:00 sh
   37 root      0:00 ps aux
```

Через файловую систему proc мы можем перейти к ФС определенного процесса, например с PID 1:

```
/ # cd /proc/1/root
/proc/1/root # ls -l
total 64
lrwxrwxrwx    1 root     root             7 Apr  7 00:00 bin -> usr/bin
drwxr-xr-x    2 root     root          4096 Mar  7 17:30 boot
drwxr-xr-x    5 root     root           360 Apr 24 08:17 dev
drwxr-xr-x    1 root     root          4096 Apr 16 17:02 docker-entrypoint.d
-rwxr-xr-x    1 root     root          1620 Apr 16 17:01 docker-entrypoint.sh
drwxr-xr-x    1 root     root          4096 Apr 24 08:17 etc
drwxr-xr-x    2 root     root          4096 Mar  7 17:30 home
lrwxrwxrwx    1 root     root             7 Apr  7 00:00 lib -> usr/lib
lrwxrwxrwx    1 root     root             9 Apr  7 00:00 lib64 -> usr/lib64
drwxr-xr-x    2 root     root          4096 Apr  7 00:00 media
drwxr-xr-x    2 root     root          4096 Apr  7 00:00 mnt
drwxr-xr-x    2 root     root          4096 Apr  7 00:00 opt
dr-xr-xr-x  259 root     root             0 Apr 24 08:17 proc
drwx------    2 root     root          4096 Apr  7 00:00 root
drwxr-xr-x    1 root     root          4096 Apr 24 08:17 run
lrwxrwxrwx    1 root     root             8 Apr  7 00:00 sbin -> usr/sbin
drwxr-xr-x    2 root     root          4096 Apr  7 00:00 srv
dr-xr-xr-x   13 root     root             0 Apr 24 08:17 sys
drwxrwxrwt    2 root     root          4096 Apr  7 00:00 tmp
drwxr-xr-x    1 root     root          4096 Apr  7 00:00 usr
drwxr-xr-x    1 root     root          4096 Apr  7 00:00 var
```

Видим ФС контейнера с nginx.

```
/proc/1/root # ls -l /proc/1/root/etc/nginx/
total 32
drwxr-xr-x    1 root     root          4096 Apr 24 08:17 conf.d
-rw-r--r--    1 root     root          1007 Apr 16 12:01 fastcgi_params
-rw-r--r--    1 root     root          5349 Apr 16 12:01 mime.types
lrwxrwxrwx    1 root     root            22 Apr 16 12:14 modules -> /usr/lib/nginx/modules
-rw-r--r--    1 root     root           644 Apr 16 12:14 nginx.conf
-rw-r--r--    1 root     root           636 Apr 16 12:01 scgi_params
-rw-r--r--    1 root     root           664 Apr 16 12:01 uwsgi_params
```

Также мы можем создать копию pod-а, который хотим дебажить и подключить debug-контейнер к этой копии:

```shell
$ kubectl debug -it nginx-pod --image=busybox --copy-to=debugging-pod --share-processes
```