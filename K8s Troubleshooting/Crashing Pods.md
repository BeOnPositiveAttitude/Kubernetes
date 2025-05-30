Статус pod-а `CrashLoopBackOff` сам по себе не является ошибкой. Это реакция на ошибку, когда контейнер в pod-е запускается и падает снова и снова. Интервал между рестартами будет расти по экспоненте.

Параметр `restartPolicy` для pod-а по умолчанию имеет значения `Always`. Это значит, что всякий раз, когда контейнер в pod-е по какой-либо причине падает, он будет перезапущен оркестратором. Также `restartPolicy` может иметь значения:

- `Never` - никогда не перезапускать контейнер
- `OnFailure` - перезапускать контейнер, если exit code отличен от нуля

Если exit code равен `1`, это означает ошибку в самом приложении.

Если exit code равен `137`, это значит, что пришел внешний сигнал для завершения контейнера (например не прошла liveness probe и оркестратор перезапустил контейнер).

Если exit code равен `127`, это значит не найдена команда либо необходимый для ее работы файл.