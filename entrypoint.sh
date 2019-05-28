#!/bin/sh

# Based on https://github.com/mailcow/mailcow-dockerized/blob/master/data/Dockerfiles/acme/docker-entrypoint.sh
restart_container(){
  for container in $*; do
    echo "Restarting ${container}..."
    echo $(curl -X POST --insecure https://dockerapi/containers/${container}/restart | jq -r '.msg')
  done
}

# Based on https://github.com/mailcow/mailcow-dockerized/blob/master/data/Dockerfiles/acme/docker-entrypoint.sh
# Removed NGINX as Traefik is handling ssl termination
reload_configurations(){
  # Reading container IDs
  # Wrapping as array to ensure trimmed content when calling $NGINX etc.
  local DOVECOT=($(curl --silent --insecure https://dockerapi/containers/json | jq -r '.[] | {name: .Config.Labels["com.docker.compose.service"], id: .Id}' | jq -rc 'select( .name | tostring | contains("dovecot-mailcow")) | .id' | tr "\n" " "))
  local POSTFIX=($(curl --silent --insecure https://dockerapi/containers/json | jq -r '.[] | {name: .Config.Labels["com.docker.compose.service"], id: .Id}' | jq -rc 'select( .name | tostring | contains("postfix-mailcow")) | .id' | tr "\n" " "))
  # Reloading
  echo "Reloading Dovecot..."
  DOVECOT_RELOAD_RET=$(curl -X POST --insecure https://dockerapi/containers/${DOVECOT}/exec -d '{"cmd":"reload", "task":"dovecot"}' --silent -H 'Content-type: application/json' | jq -r .type)
  [[ ${DOVECOT_RELOAD_RET} != 'success' ]] && { echo "Could not reload Dovecot, restarting container..."; restart_container ${DOVECOT} ; }
  echo "Reloading Postfix..."
  POSTFIX_RELOAD_RET=$(curl -X POST --insecure https://dockerapi/containers/${POSTFIX}/exec -d '{"cmd":"reload", "task":"postfix"}' --silent -H 'Content-type: application/json' | jq -r .type)
  [[ ${POSTFIX_RELOAD_RET} != 'success' ]] && { echo "Could not reload Postfix, restarting container..."; restart_container ${POSTFIX} ; }
}


# Initial extract
python extract.py /acme.json ${MAILCOW_HOSTNAME} /ssl
reload_configurations # Reload just to be safe

while inotifywait -e close_write "/acme.json"
do
    # Extract on file change. not optimal as there might be other domains but it should work for now
    python extract.py /acme.json ${MAILCOW_HOSTNAME} /ssl
    reload_configurations # Certs updated, reload services
done