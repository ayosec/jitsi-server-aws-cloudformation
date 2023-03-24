#!/bin/bash

PACKAGE_URL=https://github.com/jitsi/docker-jitsi-meet/archive/refs/tags/stable-8319.tar.gz

set -xeuo pipefail

mkdir -p ~/.jitsi-meet-cfg/{web,transcripts,prosody/config,prosody/prosody-plugins-custom,jicofo,jvb,jigasi,jibri}

if [ ! -d /srv/jitsi ]
then

  mkdir -p /srv/jitsi
  cd /srv/jitsi

  wget -qO - "$PACKAGE_URL" | tar --strip-components=1 -xz

  # Copy the .env example withtout the variables found in jitsi.env
  grep -vFf <(grep -Eo '^\w+=' /etc/jitsi.env) env.example > .env

  cat /etc/jitsi.env >> .env
  ./gen-passwords.sh

fi

cd /srv/jitsi
exec docker-compose up
