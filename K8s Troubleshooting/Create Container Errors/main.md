Основные этапы создания и запуска контейнера в K8s, а также присущие этим этапам ошибки:

<img src="image.png" width="800" height="400"><br>

`CreateContainerError` - причина может быть в том, что не задана инструкция  `ENTRYPOINT`/`CMD` в самом образе, либо не заданы параметры `command`/`args` в манифесте объекта K8s.

`RunContainerError` - причина может быть в том, что при старте контейнера исполняемый файл/команда не найдена в PATH.

Сначала генерируется конфигурация контейнера, которая берется из различных ConfigMaps/Secrets, а уже после выполняется entrypoint!