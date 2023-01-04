FROM ubuntu   #Layer 1

RUN apt-get update && apt-get -y install python   #Layer 2

RUN pip install flask flask-mysql   #Layer 3

COPY . /opt/source-code   #Layer 4

ENTRYPOINT FLASK_APP=/opt/source-code/app.py flask run   #Layer 5