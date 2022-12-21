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
