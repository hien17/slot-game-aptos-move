#!/bin/sh

set -e

echo "##### Upgrade module #####"

ADDR=0xd148b845637fd4b0551f8ea7edba841e376346b2fc7b9ea05c39480773ed73fc

aptos move upgrade-object   \
    --address-name slot_game    \
    --object-address $ADDR