**kubectx** is a tool to switch between contexts (clusters) on kubectl faster.

**kubens** is a tool to switch between Kubernetes namespaces (and configure them for kubectl) easily.

[Ссылка на репозиторий GitHub](https://github.com/ahmetb/kubectx)

Установка:

```bash
sudo git clone https://github.com/ahmetb/kubectx /opt/kubectx
sudo ln -s /opt/kubectx/kubectx /usr/local/bin/kubectx
sudo ln -s /opt/kubectx/kubens /usr/local/bin/kubens
```

To list all contexts: `kubectx`.

To switch to a new context: `kubectx coffee`.

To switch back to the previous context: `kubectx -`.

To see the current context: `kubectx -c`.


To switch to a new namespace: `kubens dev`.

To switch back to previous namespace: `kubens -`.