Предположим у нас есть файл Deployment, в котором повторяются одни и те же строки с Labels:
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ .Release.Name }}-nginx
  labels:
    app.kubernetes.io/name: nginx
    app.kubernetes.io/instance: nginx
spec:
  selector:
    matchLabels:
      app.kubernetes.io/name: nginx
      app.kubernetes.io/instance: nginx
  template:
    metadata:
      labels:
        app.kubernetes.io/name: nginx
        app.kubernetes.io/instance: nginx
    spec:
      containers:
      - name: nginx
        image: "nginx:1.16.0"
        imagePullPolicy: ifNotPresent
        ports:
          - name: http
            containerPort: 80
            protocol: tcp
```

А также файл Service, в котором также есть аналогичный Label:
```yaml
apiVersion: v1
kind: Service
metadata:
  name: {{ .Release.Name }}-nginx
  labels:
    app.kubernetes.io/name: nginx
    app.kubernetes.io/instance: nginx
spec:
  ports:
  - name: http
    port: 80
    protocol: TCP
    targetPort: http
  selector:
    app: hello-world
```

Как нам не запутаться и быть уверенными, что во всех файлах (которых может быть множество) строки с Labels одинаковые? Как мы можем переиспользовать код и убрать дублирование строк? Мы можем перенести повторяющиеся строки в так называемый Named Template. Это будет файл с именем _helpers.tpl. Нижнее подчеркивание в имени указывает Helm не рассматривать этот как обычный template. Когда мы запускаем helm-команду, Helm читает все файлы внутри каталога tepmplates и конвертирует их в manifest-файлы K8s. В нашем случае это всего лишь helper-файл и нам не нужно, чтобы он рассматривался как K8s manifest. Таким образом файлы, имя которых начинается с нижнего подчеркивания, не будут сконвертированы в manifest-файлы K8s. Перенесем переиспользуемый код в файл _helpers.tpl:
```yaml
{{- define "labels" }}
    app.kubernetes.io/name: nginx
    app.kubernetes.io/instance: nginx
{{- end }}
```

Далее указываем в файле Service использовать код из Named Template:
```yaml
apiVersion: v1
kind: Service
metadata:
  name: {{ .Release.Name }}-nginx
  labels:
    {{- template "labels" }}
spec:
  ports:
  - name: http
    port: 80
    protocol: TCP
    targetPort: http
  selector:
    app: hello-world
```

Стоит обратить внимание, что в файле _helpers.tpl у нас "захардкожено" имя Release, попробуем это исправить:
```yaml
{{- define "labels" }}
    app.kubernetes.io/name: {{ .Release.Name }}
    app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}
```

Однако в итоговом файле Service вместо имени Release у нас будут пустые значения. Это связано со scope, который применим к template-файлам, но не передается к helper-файлам. Чтобы передать текущий scope в helper-файл, в template-файле нужно указать точку:
```yaml
apiVersion: v1
kind: Service
metadata:
  name: {{ .Release.Name }}-nginx
  labels:
    {{- template "labels" . }}
spec:
  ports:
  - name: http
    port: 80
    protocol: TCP
    targetPort: http
  selector:
    app: hello-world
```

Также важно помнить об отступах при использовании helper-файлов. Рассмотрим это на примере файла Deployment:
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ .Release.Name }}-nginx
  labels:
    {{- template "labels" . }}
spec:
  selector:
    matchLabels:
      {{- template "labels" . }}
  template:
    metadata:
      labels:
        {{- template "labels" . }}
    spec:
      containers:
      - name: nginx
        image: "nginx:1.16.0"
        imagePullPolicy: ifNotPresent
        ports:
          - name: http
            containerPort: 80
            protocol: tcp
```

Количество пробелов в отступах везде будет одинаковым, как задано в helper-файле:
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: my-rel-nginx
  labels:
    app.kubernetes.io/name: my-rel
    app.kubernetes.io/instance: my-rel
spec:
  selector:
    matchLabels:
    app.kubernetes.io/name: my-rel
    app.kubernetes.io/instance: my-rel
  template:
    metadata:
      labels:
    app.kubernetes.io/name: my-rel
    app.kubernetes.io/instance: my-rel
    spec:
      containers:
      - name: nginx
        image: "nginx:1.16.0"
        imagePullPolicy: ifNotPresent
        ports:
          - name: http
            containerPort: 80
            protocol: tcp
```

Чтобы устранить эту проблему, нам поможет функция `indent`. Однако есть проблема, template - это не функция, а действие. Соответственно мы не можем передать через pipe действие | функция: `{{- template "labels" . | indent 2 }}`. Чтобы все заработало, нужно заменить действие `template` на функцию `include`, которая делает то же самое, что и template:
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ .Release.Name }}-nginx
  labels:
    {{- template "labels" . }}
spec:
  selector:
    matchLabels:
      {{- include "labels" . | indent 2 }}
  template:
    metadata:
      labels:
        {{- include "labels" . | indent 4 }}
    spec:
      containers:
      - name: nginx
        image: "nginx:1.16.0"
        imagePullPolicy: ifNotPresent
        ports:
          - name: http
            containerPort: 80
            protocol: tcp
```