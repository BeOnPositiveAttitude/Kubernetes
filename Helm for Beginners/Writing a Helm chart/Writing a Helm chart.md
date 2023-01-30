Кроме деплоя различных объектов в K8s в рамках установки нашего приложения Helm Charts могут делать некоторые дополнительные вещи. Например, при обновлении приложения WordPress может быть автоматически создана резервная копия базы данных перед началом процесса обновления и таким образом у нас будет шанс восстановить данные из бэкапа в случае, если что-то пойдет не так.

Рассмотрим процесс создания Helm Chart с нуля. У нас есть Deployment с образом nginx и двумя репликами и Service для публикации приложения наружу. Как мы узнали в предыдущих уроках Helm Chart - это директория с определенной структурой:
- templates - папка с файлами шаблонов
- values.yaml - конфигурируемые значения переменных
- Chart.yaml - информация о Chart
- LICENSE - файл лицензии
- README.md - файл справки
- charts - папка с зависимыми Charts

Наша цель - создать аналогичную структуру файлов и папок, но нам не нужно делать это вручную. Мы можем сделать это с помощью команды: `helm create nginx-chart`. Далее мы можем редактировать нужные нам файлы. Например обновить Description в файле Chart.yaml и добавить информацию о Maintainers. В директории templates уже будут созданы sample-файлы. Пока мы можем удалить все созданные файлы внутри каталога templates командой: `rm -r templates/*`. Наша задача - перенести файлы Deployment и Service в каталог templates. После перемещения можно считать Chart готовым к установке. Однако все значения переменных в этих файлах "захардкожены", например имя Deployment. И в этом заключается проблема. Например мы установили приложение командой: `helm install hello-world-1 ./nginx-chart`, создастся Deployment с именем `hello-world`. Что если нужно установить еще один Release на основе этого же Chart? Мы получим ошибку, т.к. Deployment с именем `hello-world` уже существует. Имя Deployment должно быть уникальным в каждой инсталляции. Для этого нам нужно использовать шаблонизацию.

Рассмотрим подробнее пример шаблона `{{ .Release.Name }}-nginx`.

`{{ .Release.Name }}` - Template Directive (Go Template Language). Первая точка означает rool-level или top-level scope, подробнее в следующих уроках. `Release.Name` - имя Release из команды `helm install hello-wolrd-1 ./nginx-chart`. В итоге имя Deployment будет равно `hello-world-1-nginx`.

Также для шаблонизации можно использовать следующее:
- Release.Name
- Release.Namespace
- Release.IsUpgrade
- Release.IsInstall
- Release.Revision
- Release.Service

Можно ссылаться на файл Chart.yaml:
- Chart.Name
- Chart.ApiVersion
- Chart.Version
- Chart.Type
- Chart.Keywords
- Chart.Home

И даже можно ссылаться на сам кластер K8s:
- Capabilities.KubeVersion
- Capabilities.ApiVersions
- Capabilities.HelmVersion
- Capabilities.GitCommit
- Capabilities.GitTreeState
- Capabilities.GoVersion

Все что начинается с Values относится к файлу values.yaml:
- Values.replicaCount
- Values.image

Важно рассмотреть соглашение об именовании - для Release, Chart и Capabilities вторая часть после точки всегда начинается с заглавной буквы, для Values вторая часть после точки как правило пишется с маленькой буквы. Первые три - встроенные объекты и они должны следовать соглашению об именовании с заглавной буквы. Для Values соглашение об именовании определяется пользователем.

Аналогичным способом нужно шаблонизировать другие объекты K8s, имена которых должны быть уникальными. Helm не позволит установить два Release с одинаковыми именами, поэтому можно использовать шаблон именования объектов K8s, основываясь на имени Release. В дальнейшем это также поможет нам идентифицировать к какому Release относится тот или иной объект K8s.

Значение любой шаблонизированной переменной можно передать с помощью опции командной строки `--set replicaCount=2` или определить в файле values.yaml. Рассмотрим подробнее поле image. Она может содержать несколько свойств кроме имени образа, например версию образа, pullPolicy и т.д. В файле values.yaml мы можем задать эти свойства по отдельности:

```yaml
replicaCount: 1

image_repository: nginx
image_pullPolicy: IfNotPresent
image_tag: "1.16.0"
```

Но более правильный способ оформить это в формате словаря:

```yaml
replicaCount: 1

image:
  repository: nginx
  pullPolicy: IfNotPresent
  tag: "1.16.0"
```

Тогда мы можем ссылаться на имя образа в формате `{{ .Values.image.repository }}`.

Если нужно добавить tag: `{{ .Values.image.repository }}:{{ .Values.image.tag }}`. В итоге получим: `nginx:1.16.0`.

Когда устанавливается Helm Chart, он использует файлы из каталога templates, объединяет их с информацией о Release (Release.Name), со значениями из values.yaml, а также с данными о Chart. В итоге формируется manifest-файл для конечного объекта K8s.



