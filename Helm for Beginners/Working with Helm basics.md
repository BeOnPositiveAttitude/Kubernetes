Смотреть базовую справку по командам Helm: `helm --help`.

Можно также посмотреть справку по определенной подкоманде: `helm repo --help`.

И "провалиться" еще глубже внутри подкоманды: `helm repo update --help`.

Чтобы найти "качественный" Chart на artifacthub.io стоит обратить внимание на те, что имеют official или verified publisher badge. Как правило на страничке Chart указаны команды, необходимые для установки данного Chart.

Также мы можем искать Charts через cli: `helm search hub wordpress` для поиска в Hub или `helm search repo wordpress` для поиска по добавленному репозиторию.

Как правило установка приложения сводится к двум командам:

Добавление нужного репозитория: `helm repo add bitnami https://charts.bitnami.com/bitnami`.

И непосредственно сама установка: `helm install my-release bitnami/wordpress`.

В конце установки выводится краткая информация о том как использовать установленное приложение.

Смотреть список установленных Releases: `helm list`.

Удалить Release: `helm uninstall my-release`. Эта команда удаляет все связанные с нашим приложением объекты K8s.

Смотреть список добавленных репозиториев: `helm repo list`.

Команда `helm repo update` действует по аналогии с командой `sudo apt-get update` в ОС Linux и обновляет информацию в нашем локальном репозитории.
