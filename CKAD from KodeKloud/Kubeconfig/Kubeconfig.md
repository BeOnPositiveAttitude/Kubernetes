Пример запроса на авторизацию с использованием сертификатов, который валидируется API-сервером:

`curl https://my-kube-playground:6443/api/v1/pods --key admin.key --cert admin.crt --cacert ca.crt`

Аналогично с помощью утилиты kubectl:

`kubectl get pods --server my-kube-playground:6443 --client-key admin.key --client-certificate admin.crt --certificate-authority ca.crt`

Вводить эти опции каждый раз вручную достаточно утомительный процесс. Мы можем перенести эти настройки в конфигурационный файл kubeconfig:
```
--server my-kube-playground:6443
--client-key admin.key
--client-certificate admin.crt
--certificate-authority ca.crt
```
И далее указывать этот файл при запуске утилиты kubectl: `kubectl get pods --kubeconfig config`

По умолчанию утилита kubectl ищет конфиг в домашней директории пользователя `$HOME/.kube/config`. Соответственно если мы поместим конфиг файл в эту директорию, тогда нам не придется каждый раз указывать опцию `--kubeconfig`

Файл kubeconfig содержит три секции:
- Clusters
- Contexts
- Users

`Clusters` содержит информацию о K8s кластерах, к которым мы подключаемся, например Development, Production и Google.
`Users` содержит информацию об аккаунтах пользователей, под которыми мы подключаемся к этим кластерам, например Admin, Dev User, Prod User. Эти пользователи могут иметь разные привилегии на разных кластерах.
`Contexts` нужен для того, чтобы подружить Clusters и Users секции, то есть под каким пользователем на какой кластер нужно идти. Например Admin@Production - идти под пользователем Admin на кластер Production.

Важно понимать, что это НЕ способ создания новых пользователей или настройки авторизации в кластере. Мы просто берем уже существующего пользователя с определенными правами и указываем под каким пользователем на какой кластер идти.

Файл kubeconfig не создается утилитой kubectl как обычный объект K8s. Это обычный файл, который читается утилитой kubectl as-is.

Каким образом kubectl определяет какой контекст использовать из множества указанных в конфиге? Для этого в конфиге существует поле `current-context`.

Смотреть дефолтный kubeconfig: `kubectl config view`.

Смотреть конкретный kubeconfig: `kubectl config view --kubeconfig=my-custom-config`.

Мы можем переместить наш кастомный конфиг в директорию `$HOME/.kube/`, чтобы он стал дефолтным.

Сменить текущий контекст: `kubectl config use-context prod-user@production`. Изменения отразятся и в файле конфига.

Справка по конфигу: `kubectl config -h`.

В секции `Contexts` в конфиге также можно указать определенный namespace, в который мы сразу попадем при переключении на этот контекст.