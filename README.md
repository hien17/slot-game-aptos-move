
NOTE: It also means randomness API calls are supported only in entry function-based transactions. (For example, using randomness API in a Move script is impossible.)

## Use chmod to add executable permission 
```shell
chmod +x sh_scripts/script_setup.sh
```
Then run the script of setup
```shell
./sh_scripts/script_setup.sh
```
## Run unit tests
```shell
./sh_scripts/move_test.sh
```
## Publish Modules
```shell
./sh_scripts/move_publish.sh
```
## Deploy modules in a object
```shell
./sh_scripts/move_deploy_object.sh
```
## Upgrade Modules
```shell
./sh_scripts/move_upgrade.sh
```
## Run move scripts
### Create game
```shell
./sh_scripts/move_run_script_create_game.sh
```
### Make random slot and reveal.
```shell
./sh_scripts/move_run_script_make_random_slot_commit_and_reveal.sh
```

```shell
##### Running tests #####
Running Move unit tests
[ PASS    ] 0x100::main::test_can_not_commit_twice
[ PASS    ] 0x100::main::test_can_not_commit_when_game_is_not_exist
[debug] 1
[debug] 9
[debug] 11
[ PASS    ] 0x100::main::test_can_not_reveal_twice
[ PASS    ] 0x100::main::test_can_not_reveal_without_commit_first
[debug] 1
[debug] 9
[debug] 11
[ PASS    ] 0x100::main::test_commit_and_reveal_slot_game_happy_path
[ PASS    ] 0x100::main::test_create_game
[ PASS    ] 0x100::main::test_init_module_is_right
[ PASS    ] 0x100::main::test_is_owner
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


##### Running move script to create gotchi #####



##### Running move script to feed gotchi #####

```