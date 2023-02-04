Когда мы устанавливали WordPress в прошлом уроке, мы установили все с параметрами по умолчанию. Но мы не всегда хотим использовать дефолтные параметры. Например мы не хотим использовать имя сайта по умолчанию "User's Blog!". Приложение WP разворачивается с помощью Deployment и имя сайта в нем задается через переменную окружения `WORDPRESS_BLOG_NAME`, значение которой `User's Blog!` берется из файла values.yaml.

Когда мы устанавливали WordPress, мы делали это с помощью одной команды: `helm install my-release bitnami/wordpress`. Эта команды скачивает Chart и сразу же устанавливает приложение. При этом не появляется никакого окна для возможности изменения значений переменных в values.yaml.

Один из способов изменения дефолтных значений переменных заключается в использовании параметра командной строки `--set`:

`helm install --set wordpressBlogName="Helm Tutorials" --set wordpressEmail="john@example.com" my-release bitnami/wordpress`

С помощью этой опции дефолтные значения из файла values.yaml будут переопределены. Но т.к. подобных переменных может быть очень много, существует еще один способ - перенести их все в наш собственный кастомный файл custom-values.yaml:

```yaml
wordpressBlogName: Helm Tutorials
wordpressEmail: john@example.com
```

Далее мы указываем этот файл в команде для установки приложения: `helm install --values custom-values.yaml my-release bitnami/wordpress`. С помощью этой опции дефолтные значения из файла values.yaml также будут переопределены.

Но что, если мы хотим переопределить дефолтные значения переменных в самом файле values.yaml вместо использования опции командной строки или кастомного файла custom-values.yaml? Вместо использования команды `helm install ...` мы разобьем ее на две части. Сначала скачаем и распакуем Chart с помощью команды: `helm pull --untar bitnami/wordpress`. У нас появится директория wordpress со всеми необходимыми файлами, включая values.yaml. Далее мы можем отредактировать значения переменных в этом файле в любом текстовом редакторе. И уже после установить Chart, указав вместо имени Chart директорию wordpress: `helm install my-release ./wordpress`.
