Для чего вообще нужна авторизация?

Мы как администраторы имеем самые широкие полномочия в кластере, например можем удалить ноду из кластера, поменять сетевые настройки и т.д. Разработчики в свою очередь должны иметь возможность только деплоить свои приложения и просматривать некоторые настроки. В случае когда доступ в кластер имеют несколько команд и у каждой команды свой namespace, необходимо чтобы каждая из команд имела доступ только в свой namespace. Вот для чего нужна авторизация.

K8s поддерживает различные механизмы авторизации:
- Role Based Access Control (RBAC)
- Attribute Based Access Control (ABAC)
- Node Authorization
- Webhook mode

**Node Authorization**

Доступ к API серверу имеем мы как пользователи, а также kubelet-агент на нодах. Kubelet обращается к API серверу для получения информации о Services, Endpoints, Nodes и Pods, а сам в свою очередь сообщает API серверу информацию о статусе нод, pod-ов и events. Эти запросы обрабатываются специальным Node Authorizer.

Kublet должен быть частью system node group и иметь имя с префиксом `system:node`. Запрос пришедший от юзера с именем `system:node` и являющегося частью system node group авторизуется с помощью Node Authorizer и ему выдаются соответствующие права. Это доступ внутри кластера.

**ABAC**

Attribute Based Access Control - механизм, когда пользователю или группе пользователей назначается набор permissions.

Например мы назначаем на dev-user права на view, create и delete pods. Делается это путем создания policy-файла с набором политик в формате JSON и дальнейшей его передачи в API сервер:

`{"kind": "Policy", "spec": {"user": "dev-user", "namespace": "*", "resource": "pods", "apiGroup": "*"}}`

Аналогично для dev-user-2:

`{"kind": "Policy", "spec": {"user": "dev-user-2", "namespace": "*", "resource": "pods", "apiGroup": "*"}}`

Для группы пользователей:

`{"kind": "Policy", "spec": {"group": "dev-users", "namespace": "*", "resource": "pods", "apiGroup": "*"}}`

Каждый раз когда нам нужно что-то изменить в параметрах безопасности, мы должны вручную редактировать этот файл и перезапускать kube-apiserver. Таким образом ABAC достаточно сложен в управлении.

**RBAC**

Role Based Access Control - вместо назначения пользователю или группе пользователей набора permissions, мы определяем роль.

Например мы создаем роль developers с необходимым набором permissions и затем назначаем эту роль на каждого разработчика. Достаточно изменить параметры безопасности в настройках роли и тогда изменения применятся ко всем разработчикам, на которых эта роль назначена.

**Webhook**

Предположим, что для авторизации мы хотим использовать стороннее решение, а не встроенные механизмы K8s.

Например Open Policy Agent - сторонняя утилита, которая помогает осуществлять авторизацию и admission control. K8s делает вызов API к Open Policy Agent с информацией о пользователе и запрошенном им доступе, а уже Open Policy Agent решает, разрешить пользователю запрошенную операцию или нет.

Кроме рассмотренных выше существует еще два режима - *AlwaysAllow* и *AlwaysDeny*. AlwaysAllow - разрешает все запросы без авторизации. AlwaysDeny - отклоняет все запросы.

Настраивается в конфигурации kube-apiserver опцией `--authorization-mode=AlwaysAllow`, если опция не указана, то имеет такое значение по умолчанию, можно указать несколько вариантов `--authorization-mode=Node,RBAC,Webhook`.

Когда настроено несколько механизмов авторизации, наш запрос авторизуется каждым механизмом по очереди в порядке указанном в конфиге kube-apiserver. Из примера выше - Node Authorizer обрабатывает запросы только от нод, соответственно запрос пользователя он отклонит, но даже если один authorizer отклонил запрос, то этот запрос все равно будет передан дальше по цепочке к RBAC, который в свою очередь успешно авторизует пользователя и в случае успеха цепочка проверок заканчивается и пользователь получает доступ.