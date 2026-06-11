Проверяем установлен ли нужный пакет:

```bash
$ type _init_completion
```

Если не установлен, то ставим:

```bash
$ apt-get install bash-completion
# or
$ yum install bash-completion
```

Далее непосредственно настройка:

```bash
$ echo 'source <(kubectl completion bash)' >> ~/.bashrc
$ echo 'alias k=kubectl' >> ~/.bashrc
$ echo 'complete -o default -F __start_kubectl k' >> ~/.bashrc
```

Команда `<(kubectl completion bash)` - это подстановка процессов (process substitution). Эта конструкция запускает команду и представляет её вывод как временный файл (точнее, как файловый дескриптор, например `/dev/fd/63`).

#### Пример: выводит путь к временному файлу

```bash
$ echo <(kubectl -h)
/dev/fd/63
```

Bash создаёт анонимный именованный канал (FIFO) или файл в `/dev/fd/`, куда направляется вывод команды. Это позволяет обращаться к выводу команды так, будто это файл.