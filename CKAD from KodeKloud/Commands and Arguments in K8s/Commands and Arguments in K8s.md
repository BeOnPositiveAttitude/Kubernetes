Сравнение с командами Docker из лекции "Docker. Commands vs Entrypoint"

Docker файл, из которого собирается образ ubuntu-sleeper:
```
FROM ubuntu
ENTRYPOINT ["sleep"]
CMD ["5"]
```
Запустить контейнер с именем ubuntu-sleeper из образа ununtu-sleeper и переопределить дефолтные 5 секунд сна, заданные в образе ubuntu-sleeper на 10 секунд:

`docker run --name ubuntu-sleeper ubuntu-sleeper 10`

Пример запуска pod-а из образа ubuntu-sleeper и переопределения дефолтных 5 секунд сна, заданных в образе приведен в файле pod-definition.yaml

Запустить контейнер с именем ubuntu-sleeper из образа ununtu-sleeper и переопределить команду sleep на вымышленную команду sleep2.0:

`docker run --name ubuntu-sleeper --entrypoint sleep2.0 ubuntu-sleeper 10`

Пример запуска pod-а из образа ubuntu-sleeper и переопределения команды sleep командой sleep2.0 приведен в файле pod-definition.yaml

Итого:

Поле *args* в pod definition файле соответствует инструкции CMD в Dockerfile

Поле *command* в pod definition файле соответствует инструкции ENTRYPOINT в Dockerfile