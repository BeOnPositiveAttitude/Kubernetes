В случае когда service направляет трафик не на те pod-ы, дело может быть в некорректном selector в самом service.

Смотреть какие pod-ы попадают под определенный label:

```shell
$ kubectl get pods -l version=v1
```

Смотреть IP-адреса pod-ов, на которые service направляет трафик:

```shell
$ kubectl get endpoints
```
