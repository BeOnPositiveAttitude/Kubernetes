В уроке "Volumes in Kubernetes" мы создавали volume в рамках pod definition файла

Когда у нас большая инфрастуктура с множеством пользователей, разворачивающих больше количество pod-ов, пользователи будут вынуждены каждый конфигурировать storage для каждого pod-а в рамках pod definition файлов

Плюс каждый раз, когда будет происходить изменение storage, пользователи должны будут внести соответствующие изменения во всех pod-ах

Вместо этого нам бы хотелось управлять storage более централизованно

Например администратор создал бы объемный пул storage, а пользователи "отрезали" от него кусочки по мере необходимости

Здесь нам приходит на помощь Persistent Volumes - cluster wide pool of storage volumes, настроенный администратором для использования юзерами, разворачивающими приложения в кластере

Пользователи могут выбирать storage из пула, используя Persistent Volume Claims (PVC)

Смотреть Persistent Volumes: `kubectl get pv`