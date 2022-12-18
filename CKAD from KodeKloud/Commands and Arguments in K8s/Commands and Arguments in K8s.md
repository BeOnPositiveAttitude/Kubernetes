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

Поле *args* в pod definition файле переопределяет инструкцию CMD в Dockerfile

Поле *command* в pod definition файле переопределяет инструкцию ENTRYPOINT в Dockerfile

Пример ниже из лабы, нужно переопределить дефолтный синий цвет приложения на зеленый
Мы можем сделать это непосредственно командой, все что слева от "--" является опциями утилиты kubectl
Все что справа от "--" является аргументами приложения в контейнере

`kubectl run webapp-grenn --image=kodekloud/webapp-color -- --color green`