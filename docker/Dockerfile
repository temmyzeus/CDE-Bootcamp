FROM python:3.13

ARG DEBIAN_FRONTEND=noninteractive

RUN mkdir -p /home/etl

WORKDIR /home/etl

COPY ./etl/requirements.txt requirements.txt

RUN pip install -r requirements.txt

COPY ./etl/*.py /home/etl

ENV PG_HOST=

ENV PG_PORT=

ENV PG_USER=

ENV PG_PASSWD=

ENV PG_DB="postgres"

ENTRYPOINT [ "python3" ]

CMD [ "main.py" ]
