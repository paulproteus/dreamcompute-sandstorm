#!/bin/bash
# This script creates a new DreamCompute VM running Sandstorm with the sandcats hostname
# auto-provisioned.
source ~/openstack-rc.sh

ORIG_PWD="$PWD"

cd "$(mktemp -d /tmp/dreamcompute-sandstorm.$(date -I).XXXXXXXXXX)"

# Generate the admin token for the user.
ADMIN_TOKEN="$(pwgen -s 24 1)"

# Ask the user what hostname they want. Actually this is mocked-out for now;
# use pwgen to generate this, too.
DESIRED_SANDCATS_NAME="$(pwgen -v -s -0 -A 16 1)"

# Use a hard-coded email address for now.
EMAIL_ADDRESS="asheesh-2016-07-20@asheesh.org"

# Register it with sandcats dev (could use prod later on)
curl -k https://sandcats-dev-machine.sandstorm.io/reserve --data 'email='"${EMAIL_ADDRESS}"'&rawHostname='"${DESIRED_SANDCATS_NAME}" > json

# TODO: Notice HTTP status codes != 200 above, and set a timeout.

# Extract the token into a variable
DOMAIN_RESERVATION_TOKEN="$(cat json | jq '.token' | sed 's,",,g')"

# Make a copy of the userdata and fill in the details.
cp "$ORIG_PWD"/userdata.sh .
sed -i s,'{{REPLACE_ME_ADMIN_TOKEN}}',"$ADMIN_TOKEN", userdata.sh
sed -i s,'{{REPLACE_ME_SANDCATS_DOMAIN_RESERVATION_TOKEN}}',"$DOMAIN_RESERVATION_TOKEN", userdata.sh
sed -i s,'{{REPLACE_ME_DESIRED_SANDCATS_NAME}}',"$DESIRED_SANDCATS_NAME", userdata.sh

# Create the VM
openstack server create --image Ubuntu-14.04 --flavor gp1.semisonic --security-group default --key-name slittingmill --user-data userdata.sh "$DESIRED_SANDCATS_NAME"

# Loop until it's running...
echo -n "Waiting for server to boot.. (up to 30 seconds)"
for i in $(seq 0 30) ; do
  if openstack server show "$DESIRED_SANDCATS_NAME" | grep -q 'address.*public=' ; then
    break
  else
    echo -n "."
  fi
done
echo ''

# Find out its IP address
IP_ADDRESS="$(openstack server list --name="${DESIRED_SANDCATS_NAME}" -f json | jq '.[0].Networks' | awk '{print $2}' | sed 's,",,g')"
echo "Server booted with IP address: $IP_ADDRESS"

SUCCESSFULLY_BOUND_TO_PORT="no"
# Print an admin token URL once it is fully online.
echo -n "Waiting for Sandstorm install to complete... (up to 120 seconds)"
for i in $(seq 0 120) ; do
  if nc -z -w 1 "$IP_ADDRESS" 80 ; then
    echo "Server online! Access it at: http://${DESIRED_SANDCATS_NAME}.sandcats-dev.sandstorm.io/admin/setup-token/${ADMIN_TOKEN}"
    SUCCESSFULLY_BOUND_TO_PORT="yes"
    break
  else
    echo -n "."
    sleep 1
  fi
done
echo ''

if [ "$SUCCESSFULLY_BOUND_TO_PORT" = "no" ] ; then
  echo "*** WARNING: Your server failed to start properly. Contact support."
fi
