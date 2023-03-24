#!/bin/bash

set -xeuo pipefail

exec docker run                \
  --name etherpad              \
  --restart=always             \
  --publish 9001:9001          \
  --env-file /etc/etherpad.env \
  etherpad/etherpad:1.8
