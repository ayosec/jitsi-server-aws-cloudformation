#!/bin/bash

set -euo pipefail

source /etc/jitsi.env

waitfor() {
  cmd=("$@")
  while ! "${cmd[@]}"
  do
    sleep 10
  done
}

set -x

waitfor [ -d /srv/jitsi ]

cd /srv/jitsi

waitfor docker-compose exec -T prosody prosodyctl --config /config/prosody.cfg.lua status

waitfor \
  docker-compose exec -T prosody \
    prosodyctl --config /config/prosody.cfg.lua \
    register admin meet.jitsi "$ADMIN_USER_PASSWORD"
