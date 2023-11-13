Два контейнера, находящиеся в одном pod-е, могут взаимодействовать напрямую, обращаясь друг к другу как localhost, т.к. разделяют общее сетевое пространство. Плюс они также легко могут делить общий storage space.

Создать манифест pod-а, в котором используется опция `command`:

`kubectl run --restart=Never --image=busybox static-busybox --dry-run=client -o yaml --command -- sleep 1000 > static-busybox.yaml`