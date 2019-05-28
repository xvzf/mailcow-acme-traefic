FROM python:3.7-alpine

RUN apk add inotify-tools curl

WORKDIR /app

COPY . .

ENTRYPOINT ["/bin/sh", "entrypoint.sh"]