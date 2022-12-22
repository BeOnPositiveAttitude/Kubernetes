В K8s cуществует два типа аккаунтов - user account (для людей) и service account (для приложений)

Например Jenkins может использовать service account для деплоя приложений в кластере

Создать service account:

`kubectl create serviceaccount dashboard-sa`

Смотреть service accounts:

`kubectl get serviceaccount` и `kubectl describe serviceaccount dashboard-sa`

При создании service account также создается токен, который и используется внешними приложениями для взаимодействия с API кластера

Токен хранится в формате Secret, соответственно посмотреть токен можно командой:

`kubectl describe secret dashboard-sa-token-kbbdm`

Имя секрета берется из вывода команда `kubectl describe serviceaccount dashboard-sa`

Создаем service account => назначаем соответствующие права => экспортируем токен для использования внешним приложением

В случае если приложение расположено в нашем же кластере K8s, тогда нужно просто смонтировать Secret с токеном в качестве volume внутри нашего pod-а

Для каждого namespace автоматические создается service account с именем default

При создании pod-а токен service account-а с именем default автоматически монтируется как volume к этому pod-у

Внутри по Secret монтируется по пути /var/run/secrets/kubernetes.io/serviceaccount

Если заглянуть внутрь, увидим три файла:

```
kubectl exec -it nginx -- ls /var/run/secrets/kubernetes.io/serviceaccount
ca.crt  namespace  token
```

Можем увидеть содержимое токен для доступа к Kubernetes API:
`kubectl exec -it nginx -- cat /var/run/secrets/kubernetes.io/serviceaccount/token`

Важно помнить, что default service account имеет сильные ограничения, у него есть доступ только к основным запросам к API

Мы можем указать использовать другой service account в спецификации pod-а в поле serviceAccountName

Изменить service account у бегущего pod-а нельзя, только удалить и создать заново

В случае Deployment, мы можем изменить спецификацию pod-а и это приведет к новому rollout

Важно помнить, что K8s по умолчанию автоматически монтирует default service account, если явно не указать другое
