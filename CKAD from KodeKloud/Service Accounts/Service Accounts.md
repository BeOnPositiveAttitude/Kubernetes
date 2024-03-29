В K8s существует два типа аккаунтов - user account (для людей) и service account (для приложений).

Например Jenkins может использовать service account для деплоя приложений в кластере.

Создать service account: `kubectl create serviceaccount dashboard-sa`.

Смотреть service accounts: `kubectl get serviceaccount` и `kubectl describe serviceaccount dashboard-sa`.

При создании service account раньше (до версии K8s 1.22) также создавался токен, который и использовался внешними приложениями для взаимодействия с API кластера.

Токен хранился в формате Secret, соответственно посмотреть токен можно было командой: `kubectl describe secret dashboard-sa-token-kbbdm`.

Имя секрета бралось из вывода команда `kubectl describe serviceaccount dashboard-sa`.

Далее мы могли использовать этот токен в запросе к API: `curl https://192.168.56.70:6443/api -insecure --header "Authorization: Bearer eyJhbG..."`.

Создаем service account => назначаем соответствующие права с помощью RBAC => экспортируем токен для использования внешним приложением.

В случае если приложение расположено в том же кластере K8s, тогда нужно было смонтировать Secret с токеном в качестве volume внутри нашего pod-а.

Для каждого namespace автоматические создается service account с именем `default`.

При создании pod-а токен service account-а с именем `default` автоматически монтируется как volume к этому pod-у.

Внутри pod-а Secret монтируется по пути `/var/run/secrets/kubernetes.io/serviceaccount`.

Если заглянуть внутрь, увидим три файла:

```bash
kubectl exec -it nginx -- ls /var/run/secrets/kubernetes.io/serviceaccount

ca.crt  namespace  token
```

Можем увидеть содержимое токена для доступа к Kubernetes API: `kubectl exec -it nginx -- cat /var/run/secrets/kubernetes.io/serviceaccount/token`.

Важно помнить, что default service account имеет сильные ограничения, у него есть доступ только к основным запросам к API.

Мы можем указать использовать другой service account в спецификации pod-а в поле `serviceAccountName`, пример в файле `pod-definition.yaml`.

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: my-kubernetes-dashboard
spec:
  containers:
    - name: my-kubernetes-dashboard
      image: busybox
  serviceAccountName: dashboard-sa   #можно указать использование другого service account вместо дефолтного
  #automountServiceAccountToken: false   #либо можно вообще отключить автоматическое монтирование токена service account default
```

Изменить service account у бегущего pod-а нельзя, только удалить и создать заново.

В случае Deployment, мы можем изменить спецификацию pod-а и это приведет к новому rollout.

Установить новый service account для Deployment командой: `kubectl set serviceaccount deploy/web-dashboard dashboard-sa`.

Важно помнить, что K8s по умолчанию автоматически монтирует default service account, если явно не указать другое.

**Начиная с версии K8s 1.22 были внесены существенные изменения в механизм service accounts**.

Распарсить токен можно командой: `jq -R 'split(".") | select(length > 0) | .[0],.[1] | @base64d | fromjson' <<< eyJhbG...`, либо на [сайте](https://jwt.io).

*KEP - Kubernetes Enhancement Proposal*.

Был введен механизм TokenRequestAPI.

Пример в файле `pod.yaml`.

В прошлом до версии K8s 1.22 когда создавался service account, автоматически создавался Secret с токеном, который не имел expiration date, и был "not bound to any audience".

После введения механизма TokenRequestAPI у токена появилась expiration data и он стал "bound to any audience".

Начиная с версии 1.24 при создании service account, Secret с токеном теперь не создается автоматически.

Токен теперь нужно генерировать отдельно командой:

`kubectl create token dashboard-sa`, где dashboard-sa - имя service account.

По умолчанию срок действия токен - 1 час, но это можно переопределить в команде создания токена.

Если же нам нужно создать service account старым способом с бесконечным токеном, мы должны создать definition файл `secret-definition.yaml`.