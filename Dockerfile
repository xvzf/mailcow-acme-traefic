FROM python:3.7-alpine

RUN apk add inotify-tools curl bash

WORKDIR /app

COPY . .

ENTRYPOINT ["/bin/bash", "entrypoint.sh"]