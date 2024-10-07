#!/bin/sh

set -e

echo "##### Running move script to create gotchi #####"

# Profile is  the account you used to execute transaction
# Run "aptos init" to create the profile, then get the profile name from the ./aptos/config.yaml
PROFILE=default
ADDR=0x$(aptos config show-profiles --profile=$PROFILE | grep 'account' | sed -n 's/.*"account": \"\(.*\)\".*/\1/p')

# Need to compile the package first
aptos move compile  \
    --named-addresses slot_game=$ADDR

# Run the script
aptos move run-script  \
    --profile $PROFILE  \
    --compiled-script-path build/slot_game/bytecode_scripts/create_game.mv