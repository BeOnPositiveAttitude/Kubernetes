Ниже представлена диаграмма flow ключей и сертификатов в Istio.

<img src="screen.svg" width="500" height="500"><br>

Когда сервис запускается, он должен идентифицировать себя на уровне mesh control plane и получить сертификат для того, чтобы обслуживать трафик.

Как мы говорили ранее Istiod имеет встроенный центр сертификации (CA). Istio-агент создает приватный ключ и запрос на подпись сертификата (CSR) и затем посылает этот CSR с credentials в Istiod для подписания. CA в Istiod проверяет credentials передаваемые в CSR. После успешной проверки он подписывает CSR для генерации сертификата. 

Istio-агент посылает сертификат и ключ полученные от Istiod к Envoy. Istio-агент мониторит дату окончания срока действия сертификата рабочей нагрузки.

Описанный выше процесс периодически повторяется для ротации ключей и сертификатов.

Важно заметить, что для кластеров prod-уровня вы должны использовать CA соответствующего уровня, такие как HashiCorp Vault.