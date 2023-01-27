Helm - это утилита командной строки. Соответственно мы не передаем ей на вход много информации, а просто говорим - "Я хочу установить вот это приложение". Как Helm понимает каким образом достигнуть этой цели? Helm понимает как выполнить свою работу с помощью Charts. Chart похож на инструкцию для выполнения этой работы. Путем чтения и интерпретации содержимого Chart Helm понимает, что нужно сделать, чтобы выполнить запрос пользователя. С точки зрения человека Chart является лишь набором текстовых файлов. Каждый файл именуется определенным образом и имеет четко определенные цели. Как обсуждалось ранее в предыдущем уроке в файле values.yaml содержатся параметры, которые мы можем передать в Chart, чтобы приложение установилось с нужными нам параметрами. 

Кроме этого каждый Chart также содержит файл chart.yaml. Он содержит информацию о самом Chart, например Сhart apiVersion, которая может быть v1 или v2, appVersion, которая содержит информацию о версии приложения, также имя Chart, его описание, тип и др. Рассмотрим подбронее содержимое файла chart.yaml для WordPress:

```yaml
apiVersion: v2
appVersion: 6.1.1
version: 15.2.35
name: wordpress
description: WordPress is the world's most popular blogging and content management
  platform. Powerful yet simple, everyone from students to global corporations use
  it to build beautiful, functional websites.
type: application
dependencies:
- condition: memcached.enabled
  name: memcached
  repository: https://charts.bitnami.com/bitnami
  version: 6.x.x
- condition: mariadb.enabled
  name: mariadb
  repository: https://charts.bitnami.com/bitnami
  version: 11.x.x
- name: common
  repository: https://charts.bitnami.com/bitnami
  tags:
  - bitnami-common
  version: 2.x.x
keywords:
- application
- blog
- cms
- http
- php
- web
- wordpress
maintainers:
- name: Bitnami
  url: https://github.com/bitnami/charts
home: https://github.com/bitnami/charts/tree/main/bitnami/wordpress
icon: https://bitnami.com/assets/stacks/wordpress/img/wordpress-stack-220x234.png
```

`apiVersion` - версия API самого Chart. Во времена Helm 2 этого поля не существовало. Когда вышел Helm 3, в нем появились дополнительные фичи, которые привнесли изменения в yaml-файлы, которых не было раньше. Например секция `dependencies` и поле `type` были недоступны в Helm 2. Соответственно для Helm 3 понадобился способ определения в какой версии Helm был создан Chart. Таким образом поле `apiVersion` впервые появилось в Helm 3. С помощью этого поля Helm теперь может различать для какой версии Helm был создан Chart. На всех Charts либо вообще не будет установлено это значение либо, если вы специально создаете Chart для Helm 2, оно должно быть установлено в значение `v1`. Для Charts созданных для Helm 3 оно должно быть установлено в значение `v2`.

Стоит отметить, если вы создаете Chart с `apiVersion: v2`, но используете его с Helm 2, Helm 2 будет игнорировать эти дополнительные поля, которые предназначены только для Helm 3, и это может привести к неожиданным результатам.

Подводя черту, когда вы разрабатываете Chart убедитесь, что вы установили `apiVersion: v2`, поскольку в дальнейшем мы будет писать Charts под Helm 3. Если в каком-либо Chart отсутствует это поле, то скорее всего он был написан под Helm 2.

`appVersion` - версия приложения внутри Chart, в нашем примере это версия WordPress, которая будет установлена. Это поле предназначено сугубо для информации.

`version` - версия самого Chart. Каждый Chart должен иметь свою собственную версию. Она не зависит от версии приложения, которое разворачивается с помощью этого Chart. Это позволяет отслеживать изменения в самом Chart.

`name` - название Chart. `description` - описание.

`type` - тип Chart. Существует два типа Charts - `application` и `library`. `application` - тип по умолчанию, когда создаваемый Chart используется для деплоя приложений. `library` - тип Chart, который предоставляет инструменты для создания Charts.

`dependencies` - зависимости приложения. WordPress для своей работы требует еще сервер БД, в нашем примере MariaDB, которая имеет свой собственный Chart. Мы можем просто добавить ее как зависимость для нашего приложения. Таким образом нам не нужно мерджить manifest-файлы MariaDB или какие-либо другие в этот Chart.

`keywords` - ключевые слова, которые могут быть полезны при поиске Chart в публичном репозитории.

`maintainers` - информация о разработчике.

`home` - домашняя страница проекта.

Директория с Chart имеет следующую структуру:
- templates - папка с файлами шаблонов
- values.yaml - конфигурируемые значения переменных
- Chart.yaml - информация о Chart
- LICENSE - файл лицензии
- README.md - файл справки
- charts - папка с зависимыми Charts
