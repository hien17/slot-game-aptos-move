# Slot Game Smart Contract
A decentralized slot game implementation on the Aptos blockchain.
## Overview
This smart contract implements a slot game where players can:

1.  Create a new game instance
2.  Commit a random slot pull
3.  Reveal the results of their slot pull

The game uses a commit-reveal pattern to ensure fairness and prevent manipulation of results.
## Key Features

- Decentralized Randomness: Uses Aptos's randomness module for fair and verifiable results
- Token-based Games: Each game instance is represented as a token in a collection
- Two-step Gameplay: Commit-reveal pattern to ensure fairness
- Event Emission: Emits events for game outcomes for easy tracking
NOTE: It also means randomness API calls are supported only in entry function-based transactions. (For example, using randomness API in a Move script is impossible.)

## Game Rules
- Each slot has values ranging from 5 to 30
- Winning condition: All three slots show the same number
- Players must complete the commit step before revealing
- Players cannot commit twice without revealing first
- Players cannot reveal twice without committing again

## Testing
The contract includes comprehensive unit tests covering:

- Module initialization
- Game creation
- Commit-reveal mechanics
- Error cases

## Security Considerations

- Uses commit-reveal pattern to prevent result manipulation
- Prevents double-commits and double-reveals
- All critical functions check for game existence

## Terminal commands
### Use chmod to add executable permission 
```shell
chmod +x sh_scripts/script_setup.sh
```
Then run the script of setup
```shell
./sh_scripts/script_setup.sh
```
### Run unit tests
```shell
./sh_scripts/move_test.sh
```
### Publish Modules
```shell
./sh_scripts/move_publish.sh
```
### Deploy modules in a object
```shell
./sh_scripts/move_deploy_object.sh
```
### Upgrade Modules
```shell
./sh_scripts/move_upgrade.sh
```
### Run move scripts
#### Create game
```shell
./sh_scripts/move_run_script_create_game.sh
```
#### Make random slot and reveal.
```shell
./sh_scripts/move_run_script_make_random_slot_commit_and_reveal.sh
```
## Terminal commands's result
```shell
##### Running tests #####
[ PASS    ] 0x100::slot_game::test_can_not_commit_twice
[ PASS    ] 0x100::slot_game::test_can_not_commit_when_game_is_not_exist
[ PASS    ] 0x100::slot_game::test_can_not_reveal_twice
[ PASS    ] 0x100::slot_game::test_can_not_reveal_without_commit_first
[debug] 0x100::slot_game::Slots {
  slot_1: 1,
  slot_2: 9,
  slot_3: 11
}
[ PASS    ] 0x100::slot_game::test_commit_and_reveal_slot_game_happy_path
[ PASS    ] 0x100::slot_game::test_create_game
[ PASS    ] 0x100::slot_game::test_init_module_is_right
[ PASS    ] 0x100::slot_game::test_is_owner
Test result: OK. Total tests: 8; passed: 8; failed: 0
{
  "Result": "Success"
}


##### Publishing module #####
package size 7917 bytes
Transaction submitted: https://explorer.aptoslabs.com/txn/0x77e7ad6131b20056e765d0bd934ab21d8a2a6e5e047e13802ccc524e8cd765f5
{
  "Result": {
    "transaction_hash": "0x77e7ad6131b20056e765d0bd934ab21d8a2a6e5e047e13802ccc524e8cd765f5",
    "gas_used": 6103,
    "gas_unit_price": 100,
    "sender": "56313a0ccd30f4dc579898ad6371606e72ded45a9d0539ad25cb795af465b373",
    "sequence_number": 25,
    "success": true,
    "timestamp_us": 1727173810664618,
    "version": 6032873453,
    "vm_status": "Executed successfully"
  }
}

##### Deploy module in a object #####
Do you want to deploy this package at object address 0x6b0979c6d0a7bea496af7206873d5b3f9eed5046cf214a8c0064453e5f75f1d1 [yes/no] >
yes
package size 8095 bytes
Do you want to submit a transaction for a range of [714200 - 1071300] Octas at a gas unit price of 100 Octas? [yes/no] >
yes
Transaction submitted: https://explorer.aptoslabs.com/txn/0xb168d03b3b78d5fb57de5b281e445b00588d176c7f51ec9b769515a463f6a73e?network=testnet
Code was successfully deployed to object address 0x6b0979c6d0a7bea496af7206873d5b3f9eed5046cf214a8c0064453e5f75f1d1
{
  "Result": "Success"
}


##### Running move script to create game #####



##### Running move script to make random commit #####



##### Running move script to make random reveal #####



##### Running move script to make random commit & reveal #####

```