#!/bin/bash
# This userdata script does the following things.
#
# - Set up Ubuntu unattended-upgrades. Actually it doesn't do that yet, but
#   in the long run, it should.
#
# - Download the Sandstorm install script, verifying it against a GPG key embedded
#   in this script. Actually it doesn't do GPG verification yet, but it should.
#
# - Install Sandstorm using a sandcats domain reservation token. We store that
#   in an environment variable; every time this script gets sent to a server,
#   you must change that variable.
SANDCATS_DOMAIN_RESERVATION_TOKEN="{{REPLACE_ME_SANDCATS_DOMAIN_RESERVATION_TOKEN}}"
DESIRED_SANDCATS_NAME="{{REPLACE_ME_DESIRED_SANDCATS_NAME}}"
ADMIN_TOKEN="{{REPLACE_ME_ADMIN_TOKEN}}"

cd $(mktemp -d sandstorm-installer.XXXXXXXXXXXX)
wget https://install.sandstorm.io/ -O install.sh

# Temporary hack to use port 80 if there's a HTTPS bringup issue. I need to upstream
# this fix into install.sh.
sed -i 's,DEFAULT_PORT=6080,DEFAULT_PORT=80,' install.sh
CHOSEN_INSTALL_MODE=1 REPORT=no HOME=/root \
  SANDCATS_DOMAIN_RESERVATION_TOKEN="${SANDCATS_DOMAIN_RESERVATION_TOKEN}" \
  DESIRED_SANDCATS_NAME="${DESIRED_SANDCATS_NAME}" \
  ADMIN_TOKEN="${ADMIN_TOKEN}" \
  CURL_USER_AGENT=testing \
  OVERRIDE_SANDCATS_BASE_DOMAIN=sandcats-dev.sandstorm.io \
  OVERRIDE_SANDCATS_API_BASE=https://sandcats-dev-machine.sandstorm.io \
  OVERRIDE_SANDCATS_CURL_PARAMS=-k \
  bash install.sh -d

# To be decided:
#
# - Should we also do release upgrades?
#
# - Should we auto-reboot this server on new kernel versions being available?
#
# - Should we
#
# Other notes:
#
# - Sandstorm depends on curl, xz, and /bin/id from the outer operating system. The
#   DreamCompute default image has these programs, so no further package installation
#   is required.
