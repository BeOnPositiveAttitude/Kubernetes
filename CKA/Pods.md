Два контейнера, находящиеся в одном pod-е, могут взаимодействовать напрямую, обращаясь друг к другу через localhost, т.к. разделяют общее сетевое пространство. Плюс они также легко могут делить общий storage space.

Создать манифест pod-а, в котором используется опция `command`:

```shell
$ kubectl run --restart=Never --image=busybox static-busybox --dry-run=client -o yaml --command -- sleep 1000 > static-busybox.yaml
```

Рассмотрим пример:

```yaml
ports:
- name: mysql
  containerPort: 3306
```

`containerPort` - list of ports to expose from the container. Exposing a port here gives the system additional information about the network connections a container uses, **but is primarily informational**. Not specifying a port here DOES NOT prevent that port from being exposed. Any port which is listening on the default "0.0.0.0" address inside a container will be accessible from the network.

So it is exactly same with docker `EXPOSE` instruction. Both are informational.