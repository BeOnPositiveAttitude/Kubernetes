Pipelines в Linux: `echo "abcd" | tr a-z A-Z`, команда tr=translate переведет все маленькие буквы в заглавные.

Аналогично в Helm функцию `{{ upper .Values.image.repository }}` как правило пишут через pipe `{{ .Values.image.repository | upper}}`. Результат и там и там будет одинаковый.

С помощью pipelines можно передать несколько функций одна за другой: `{{ .Values.image.repository | upper | quote }}`. В результате получим "NGINX". И далее `{{ .Values.image.repository | upper | quote | shuffle }}`. В результате получим GN"XNI".