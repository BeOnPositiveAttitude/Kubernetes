Как мы знаем namespaces нужны для изоляции таких объектов как Pods, Deployments, Services.

А как насчет других ресурсов, например нод кластера? Можем ли мы сгруппировать или изолировать ноды в рамках namespace? Например сказать node1 является частью dev namespace? Нет. Это cluster wide (cluster scoped) ресурсы и они не могут быть ассоциированы с определенным namespace.

Таким образом ресурсы делятся на две категории - namespaced и cluster scoped.

Смотреть список namespaced ресурсов: `kubectl api-resources --namespaced=true`.

Смотреть список non-namespaced ресурсов: `kubectl api-resources --namespaced=false`.

<img src="namespaced.png" width="400" height="300">
<img src="non-namespaced.png" width="400" height="300"><br>

Ранее мы рассмотрели механизмы авторизации пользователей в namespaced ресурсы - Roles и RoleBindings.

Каким образом авторизовать пользователя в cluster wide ресурс, например ноды или PVs?

Для этого нужно использовать объекты ClusterRoles и ClusterRoleBindings.

Отметим, что ClusterRole можно создать и для namespaced ресурса. В таком случае пользователь будет иметь доступ к заданному типу ресурса (например pods) во всех namespace-ах кластера.

Создать ClusterRole для доступа к операциям с нодами: `kubectl create clusterrole node-admin --verb=get,watch,list,create,delete --resource=nodes`.

Еще вариант, создать ClusterRole для доступа к операциям со StorageClasses и PersistentVolumes:

`kubectl create clusterrole storage-admin --verb=get,watch,list,create,delete --resource=storageclasses,persistentvolumes`

То же самое в виде манифеста:

```yaml
kind: ClusterRole
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: storage-admin
rules:
- apiGroups: [""]
  resources: ["persistentvolumes"]
  verbs: ["get", "watch", "list", "create", "delete"]
- apiGroups: ["storage.k8s.io"]
  resources: ["storageclasses"]
  verbs: ["get", "watch", "list", "create", "delete"]
```

Создать ClusterRoleBinding (смапить созданную выше роль на пользователя michelle):

`kubectl create clusterrolebinding michelle-storage-admin --clusterrole=storage-admin --user=michelle`

То же самое в виде манифеста:

```yaml
kind: ClusterRoleBinding
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: michelle-storage-admin
subjects:
- kind: User
  name: michelle
  apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: ClusterRole
  name: storage-admin
  apiGroup: rbac.authorization.k8s.io
```

