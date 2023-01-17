Пример роли приведен в файле developer-role.yaml

Для присваивания роли пользователю нужно создать объект RoleBinding.

Смотреть роли: `kubectl get roles`.

Смотреть привязку роли к пользователю: `kubectl get rolebindings`.

Смотреть имеем ли мы права на определенные действия в кластере: `kubectl auth can-i create deployments`.

Если мы как администраторы выдали пользователю набор permissions и хотим проверить все ли работает:
`kubectl auth can-i create pods --as dev-user`.

Аналогично проверить для определенного namespace:
`kubectl auth can-i create pods --as dev-user --namespace test`.

Можно выполнить любую команду с опцией `--as` для проверки, например `kubectl --as dev-user get pods`

Объекты Roles и RoleBindings действуют в рамках определенного namespace.