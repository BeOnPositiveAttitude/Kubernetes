Полезная опция `--recursive` помогает вывести список всех возможных полей, без детального описания:

```shell
$ kubectl explain pod.spec.securityContext --recursive
```

Важно отметить, что команда `kubectl explain` работает в том числе и с Custom Resource Definitions (CRDs).