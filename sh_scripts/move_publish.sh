#!/bin/sh

set -e

echo "##### Publishing module #####"

# Profile is  the account you used to execute transaction
# Run "aptos init" to create the profile, then get the profile name from the ./aptos/config.yaml
PROFILE=default
ADDR=0x$(aptos config show-profiles --profile=$PROFILE | grep 'account' | sed -n 's/.*"account": \"\(.*\)\".*/\1/p')

aptos move publish  \
    --assume-yes    \
    --profile $PROFILE  \
    --named-addresses slot_game=$ADDR