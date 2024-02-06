Пример роли приведен в файле developer-role.yaml.

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
`kubectl auth can-i create pods --as dev-user`.

Аналогично проверить для определенного namespace:
`kubectl auth can-i create pods --as dev-user --namespace test`.

Можно выполнить любую команду с опцией `--as` для проверки, например `kubectl --as dev-user get pods`

Объекты Roles и RoleBindings действуют в рамках определенного namespace.

`kubectl auth can-i get namespaces --as=system:serviceaccount:default:green-sa-cka22-arch`