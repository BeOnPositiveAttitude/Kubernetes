Пример роли приведен в файле `developer-role.yaml`.

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: developer
  #namespace: finance   #также можно указать определенный namespace
rules:
- apiGroups: [""]   #для Core Group можно оставить пустым, для остальных нужно указывать Group Name
  resources: ["pods"]
  verbs: ["list", "get", "create", "update", "delete"]
  #resourceNames: ["blue", "orange"]   #также можно дать доступ только к определенным pod-ам
- apiGroups: [""]
  resources: ["ConfigMap"]
  verbs: ["create"]
```

Для присваивания роли пользователю нужно создать объект RoleBinding.

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: devuser-developer-binding
subjects:
  - kind: User
    name: dev-user
    apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: Role
  name: developer
  apiGroup: rbac.authorization.k8s.io
```

Смотреть роли: `kubectl get roles`.

Смотреть привязку роли к пользователю: `kubectl get rolebindings`.

Смотреть имеем ли мы права на определенные действия в кластере: `kubectl auth can-i create deployments`.

Если мы как администраторы выдали пользователю набор permissions и хотим проверить все ли работает под этим пользователем:

```shell
$ kubectl auth can-i create pods --as dev-user
```

Аналогично проверить для определенного namespace:

```shell
$ kubectl auth can-i create pods --as dev-user --namespace test
```

Можно выполнить любую команду с опцией `--as` для проверки, например `kubectl --as dev-user get pods`.

Объекты Roles и RoleBindings действуют в рамках определенного namespace.

Проверка прав для сервис-аккаунта:

```shell
$ kubectl auth can-i get namespaces --as=system:serviceaccount:default:green-sa-cka22-arch
```

Смотреть под каким пользователем мы сейчас залогинены и в какие группы входим: `kubectl auth whoami`.

Стандартный вывод команды `kubectl auth can-i` подразумевает односложный ответ - "да/нет". Чтобы понять причину полученного ответа, можно поднять verbosity:

```shell
$ kubectl auth can-i delete pods -v=10
```

Однако важно помнить, что RBAC устроен по принципу "запрещено все, что не разрешено явно".

Проверить, может ли пользователь `Bob`, являющийся членом группы `interns`, смотреть секреты в namespace.

```shell
$ kubectl -n development auth can-i get secrets --as-group=interns --as=Bob
```