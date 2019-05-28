FROM python:3.7-alpine

RUN apk add inotify-tools curl bash jq

WORKDIR /app

COPY . .

ENTRYPOINT ["/bin/bash", "entrypoint.sh"]