module slot_game::slot_game {
    use aptos_framework::event;
    use aptos_framework:: object;
    use aptos_framework::object::ExtendRef;
    use aptos_framework::randomness;
    use aptos_std::string_utils::{to_string};
    use std::signer::address_of;
    use std::string::{String, utf8};
    use std::vector;
    use aptos_token_objects::collection;
    use aptos_token_objects::token;
    use std::option;

    /// Insufficient balance of token
    const ENOT_ENOUGH_BALANCE: u64 = 1;
    /// Sender is not owner of module
    const EIS_NOT_OWNER: u64 = 2;
    /// Game is not exist
    const EGAME_IS_NOT_EXIST: u64 = 3;
    /// Already committed random value, please reveal now
    const EALREADY_COMMITTED: u64 = 4;
    /// Already revealed random value, please commit again for next play
    const EALREADY_REVEALED: u64 = 5;
    /// Randomness commitment not exist at given address, please commit first
    const ERANDOMNESS_COMMITMENT_NOT_EXIST: u64 = 6;


    const GAME_COLLECTION_OBJECT_SEED: vector<u8> = b"Slot Game Collection Seed";
    const GAME_COLLECTION_NAME: vector<u8> = b"Slot Game Collection";
    const GAME_COLLECTION_DESCRIPTION: vector<u8> = b"Collection of Slot Game";
    const GAME_COLLECTION_URI: vector<u8> = b"https://cdn-icons-png.flaticon.com/512/3401/3401533.png";
    
    // Slot value range is [5, 30]
    const SLOT_MAX_VALUE_EXCL: u8 = 30;
    const SLOT_MIN_VALUE_EXCL: u8 = 5;

    struct ItemsConfigCounter has key {
        counter: u64
    }

    struct ItemsConfig has key, store, copy, drop {
        config_id: u64,
        slots_0: vector<u64>,
        slots_1: vector<u64>,
        slots_2: vector<u64>,
        reward_ratio: u64
    }

    struct GameCollectionCapability has key {
        extend_ref: ExtendRef
    }

    struct GameCounter has key {
        counter: u64,
    }
    
    struct Game has key {
        id: u64,
        slots: Slots,
        items_config_id: u64,
        extend_ref: ExtendRef,
        mutator_ref: token::MutatorRef,
        burn_ref: token::BurnRef,
    }
    
    struct Slots has store, copy, drop {
        slot_1: u8,
        slot_2: u8,
        slot_3: u8
    }

    struct RandomnessCommitmentExt has key {
        revealed: bool,
        values: vector<u8>,
    }
    

    #[event]
    struct SlotGameResultEvent has drop, store {
        game_address: address,
        slot1: u8,
        slot2: u8,
        slot3: u8,
        status: String,
    }

    // This function is only called once when the module is published for the first time
    fun init_module(package_signer: &signer) {
        let items_config_counter = ItemsConfigCounter { counter: 0 };
        move_to(package_signer, items_config_counter);

        let game_counter = GameCounter { counter: 0 };
        move_to(package_signer, game_counter);

        let constructor_ref = object::create_named_object(
            package_signer,
            GAME_COLLECTION_OBJECT_SEED,
        );

        let extend_ref = object::generate_extend_ref(&constructor_ref);
        let game_collection_signer = &object::generate_signer(&constructor_ref);

        move_to(game_collection_signer, GameCollectionCapability {
            extend_ref: extend_ref,
        });

        create_game_collection(game_collection_signer);
    }

    fun create_game_collection(package_signer: &signer) {
        collection::create_unlimited_collection(
            package_signer,
            utf8(GAME_COLLECTION_DESCRIPTION),
            utf8(GAME_COLLECTION_NAME),
            option::none(),
            utf8(GAME_COLLECTION_URI),
        );
    }

    // ========================= Write functions ========================= 

    public entry fun create_game(
        user: &signer, 
        _amount: u64, 
        items_id: u64
    ) acquires GameCounter, GameCollectionCapability {
        let game_counter = get_game_counter();
        // game(token in collection)'s name is the id
        let name_game_token = to_string<u64>(&game_counter);

        let (slot1, slot2, slot3) = (0, 0, 0); // default slots

        // If all of them are equal with each other, reward was sent to user

        // Create an Game object and send it to user
        let constructor_ref = token::create_named_token(
            &get_game_collection_signer(), // collection's signer
            utf8(GAME_COLLECTION_NAME), // collection's name
            utf8(GAME_COLLECTION_DESCRIPTION), // token's description
            name_game_token, // token's name is the id
            option::none(),
            utf8(GAME_COLLECTION_URI), // token's uri
        );

        let game_signer_ref = object::generate_signer(&constructor_ref);
        // let game_token_address = address_of(&game_signer_ref);

        let extend_ref = object::generate_extend_ref(&constructor_ref);
        let mutator_ref = token::generate_mutator_ref(&constructor_ref);
        let burn_ref = token::generate_burn_ref(&constructor_ref);
        let transfer_ref = object::generate_transfer_ref(&constructor_ref);

        let slots = Slots {
            slot_1: slot1,
            slot_2: slot2,
            slot_3: slot3 
        };

        // Initialize and set Game struct values
        let game = Game {
            id: game_counter,
            slots: slots,
            items_config_id: items_id,
            extend_ref: extend_ref,
            mutator_ref: mutator_ref,
            burn_ref: burn_ref,
        };

        move_to(&game_signer_ref, game);
        increment_game_counter_by_one();

        object::transfer_with_ref(object::generate_linear_transfer_ref(&transfer_ref), address_of(user));
    }

    

    // This prevents undergasing attack from committing it first
    // This function is only called from a transaction to prevent test and abort attack
    #[randomness]
    entry fun make_random_slot_commit(game_id: u64) acquires Game, RandomnessCommitmentExt {
        assert_game_exist(game_id);
        let game_address = get_game_address(game_id);

        let exist_randomness_commitment_ext = exists<RandomnessCommitmentExt>(game_address);

        let (random_slot_1_value, random_slot_2_value, random_slot_3_value) = get_random();

        if (exist_randomness_commitment_ext) {
            let random_commitment_ext = borrow_global_mut<RandomnessCommitmentExt>(game_address);
            // Randomness should already be revealed now so it can be committed again
            // Throw error if it's already committed but not revealed
            assert!(random_commitment_ext.revealed, EALREADY_COMMITTED);
            // Commit a new random value now, flip the revealed flag to false
            random_commitment_ext.revealed = false;
            vector::push_back(&mut random_commitment_ext.values, random_slot_1_value);
            vector::push_back(&mut random_commitment_ext.values, random_slot_2_value);
            vector::push_back(&mut random_commitment_ext.values, random_slot_3_value);
        }
        else {
            let values = vector::empty<u8>();
            vector::push_back(&mut values, random_slot_1_value);
            vector::push_back(&mut values, random_slot_2_value);
            vector::push_back(&mut values, random_slot_3_value);
            let game_signer_ref = get_game_signer(game_address);
            move_to(&game_signer_ref, RandomnessCommitmentExt{
                revealed: false,
                values: values,
            });
        }
    }

    fun get_random(): (u8, u8, u8) {
        let random_slot_1_value = randomness::u8_range(0, 31);
        let random_slot_2_value = randomness::u8_range(0, 31);
        let random_slot_3_value = randomness::u8_range(0, 31);
        (random_slot_1_value, random_slot_2_value, random_slot_3_value)
    }

    // Used together with make_random_move_commit to reveal the random value.
    // If user doesn't reveal cause it doesn't like the result, it cannot enter the next round of game
    // In our case user cannot make another move without revealing the previous move
    // This function is only called from a transaction to prevent test and abort attack.
    public entry fun make_random_slot_reveal(game_id: u64) acquires Game, RandomnessCommitmentExt {
        assert_game_exist(game_id);
        let game_address = get_game_address(game_id);
        let game = borrow_global_mut<Game>(game_address);
        assert_randomness_commitment_exist_and_not_revealed(game_id);

        let random_commitment_ext = borrow_global_mut<RandomnessCommitmentExt>(game_address);

        // Store data
        game.slots = Slots {
            slot_1: *vector::borrow<u8>(&random_commitment_ext.values, 0),
            slot_2: *vector::borrow<u8>(&random_commitment_ext.values, 1),
            slot_3: *vector::borrow<u8>(&random_commitment_ext.values, 2),
        };

        if (
            vector::borrow<u8>(&random_commitment_ext.values, 0) == vector::borrow<u8>(&random_commitment_ext.values, 1)
            && vector::borrow<u8>(&random_commitment_ext.values, 1) == vector::borrow<u8>(&random_commitment_ext.values, 2)
        )
        {
            // Reward user


            // Emit event for winning the game
            event::emit<SlotGameResultEvent>(
                SlotGameResultEvent {
                    game_address: game_address,
                    slot1: *vector::borrow<u8>(&random_commitment_ext.values, 0),
                    slot2: *vector::borrow<u8>(&random_commitment_ext.values, 1),
                    slot3: *vector::borrow<u8>(&random_commitment_ext.values, 2),
                    status: utf8(b"Win"),
                }
            );
        };
        // Emit event for losing the game
            event::emit<SlotGameResultEvent>(
                SlotGameResultEvent {
                    game_address: game_address,
                    slot1: *vector::borrow<u8>(&random_commitment_ext.values, 0),
                    slot2: *vector::borrow<u8>(&random_commitment_ext.values, 1),
                    slot3: *vector::borrow<u8>(&random_commitment_ext.values, 2),
                    status: utf8(b"Lose"),
                }
            );
        random_commitment_ext.revealed = true;
    }

    // ========================= Get functions ========================= 
    
    #[view]
    public fun get_owner(): (address) {
        @slot_game
    }

    #[view]
    public fun get_items_config_counter(): (u64) acquires ItemsConfigCounter {
        let items_config_counter = borrow_global<ItemsConfigCounter>(@slot_game);
        items_config_counter.counter
    }

    #[view]
    public fun get_game_counter(): (u64) acquires GameCounter {
        let game_counter = borrow_global<GameCounter>(@slot_game);
        game_counter.counter
    }

    #[view]
    public fun get_game_address(game_id: u64): (address) {
        let collection_creator = get_game_collection_address();
        token::create_token_address(
            &collection_creator,
            &utf8(GAME_COLLECTION_NAME),
            &to_string<u64>(&game_id)
        )
    }

    public fun get_game_signer(game_address: address): (signer) acquires Game {
        object::generate_signer_for_extending(&borrow_global<Game>(game_address).extend_ref)
    }

    public fun increment_game_counter_by_one() acquires GameCounter {
        let game_counter = borrow_global_mut<GameCounter>(@slot_game);
        game_counter.counter = game_counter.counter + 1;
    }

    #[view]
    public fun get_game_collection_address(): (address) {
        object::create_object_address(
            &@slot_game,
            GAME_COLLECTION_OBJECT_SEED,
        )
    }

    public fun get_game_collection_signer(): (signer) acquires GameCollectionCapability {
        let collection_address = get_game_collection_address();
        object::generate_signer_for_extending(&borrow_global<GameCollectionCapability>(collection_address).extend_ref)
    }

    // Returns all fields for this game (if found)
    #[view]
    public fun get_game(game_id: u64): (u64, Slots, u64) acquires Game {
        let game = borrow_global<Game>(get_game_address(game_id));
        ( game.id, game.slots, game.items_config_id )
    }

    // Returns slot numbers in the commitment of a game
    #[view]
    public fun get_slots_in_commitment(game_id: u64): (vector<u8>) acquires RandomnessCommitmentExt {
        let commitment = borrow_global<RandomnessCommitmentExt>(get_game_address(game_id));
        ( commitment.values )
    }

    // ========================= Helper functions ========================= 
    
    fun assert_owner(sender: &signer) {
        let sender_address = address_of(sender);
        assert!(sender_address == @slot_game, EIS_NOT_OWNER)
    }

    fun assert_game_exist(game_id: u64) {
        let game_address = get_game_address(game_id);
        let exist_game = exists<Game>(game_address);
        assert!(exist_game, EGAME_IS_NOT_EXIST)
    }

    fun assert_randomness_commitment_exist_and_not_revealed(
        game_id: u64
    ) acquires RandomnessCommitmentExt {
        let game_address = get_game_address(game_id);

        let exist_randomness_commitment_ext = exists<RandomnessCommitmentExt>(game_address);
        assert!(exist_randomness_commitment_ext, ERANDOMNESS_COMMITMENT_NOT_EXIST);

        let random_commitment_ext = borrow_global<RandomnessCommitmentExt>(game_address);
        assert!(!random_commitment_ext.revealed, EALREADY_REVEALED)
    }

    // ========================= Uint tests ========================= 

    #[test_only]
    use std::debug;
    #[test_only]
    use aptos_framework::account::create_account_for_test;
    #[test_only]
    use aptos_std::crypto_algebra::enable_cryptography_algebra_natives;

    #[test_only]
    fun setup_test(
        fx: &signer,
        owner: &signer,
        user: &signer,
        zero: &signer,
     ) {
        enable_cryptography_algebra_natives(fx);
        randomness::initialize_for_testing(fx);
        randomness::set_seed(x"0000000000000000000000000000000000000000000000000000000000000000");

        // create a fake account (only for testing purposes) 
        create_account_for_test(address_of(owner));
        create_account_for_test(address_of(user));
        create_account_for_test(address_of(zero));

        init_module(owner);
     }

    #[test(
        fx = @aptos_framework,
        owner = @0x100, 
        user = @0x123,
        zero = @0x0)]
    public entry fun test_is_owner(
        fx: &signer,
        owner: &signer,
        user: &signer,
        zero: &signer,
    ) {
        setup_test(fx, owner, user, zero);
        assert!(get_owner() == address_of(owner), 1);
    }

    #[test(
        fx = @aptos_framework,
        owner = @0x100, 
        user = @0x123,
        zero = @0x0)]
    public entry fun test_init_module_is_right(
        fx: &signer,
        owner: &signer,
        user: &signer,
        zero: &signer,
    ) acquires ItemsConfigCounter {
        setup_test(fx, owner, user, zero);

        // Check counter of items config is equal with 0
        assert!(get_items_config_counter() == 0, 1);

        // Check if the GameCollectionCapability exists at the collection address
        let collection_address = get_game_collection_address();
        assert!(exists<GameCollectionCapability>(collection_address), 1);
    }

    #[test(
        fx = @aptos_framework,
        owner = @0x100, 
        user = @0x123,
        zero = @0x0)] 
    public entry fun test_create_game(
        fx: &signer,
        owner: &signer,
        user: &signer,
        zero: &signer,
    ) acquires GameCounter, GameCollectionCapability {
        setup_test(fx, owner, user, zero);

        let amount_to_play = 100;
        let items_id = 0;
        let game_id = 0;
        create_game(user, amount_to_play, items_id);

        // Check if the game counter has increased
        assert!(get_game_counter() == game_id + 1, 3);

        //  Check if the Game resource exists at the calculated address
        let game_address = get_game_address(game_id);
        assert!(exists<Game>(game_address), 4);
    }

    #[test(
        fx = @aptos_framework,
        owner = @0x100, 
        user = @0x123,
        zero = @0x0
    )]
    #[expected_failure(abort_code = EGAME_IS_NOT_EXIST, location = slot_game::slot_game)] 
    public entry fun test_can_not_commit_when_game_is_not_exist(
        fx: &signer,
        owner: &signer,
        user: &signer,
        zero: &signer,
    ) acquires Game, RandomnessCommitmentExt {
        setup_test(fx, owner, user, zero);

        let game_id = 0;
        make_random_slot_commit(game_id);
    }

    #[test(
        fx = @aptos_framework,
        owner = @0x100, 
        user = @0x123,
        zero = @0x0
    )]
    #[expected_failure(abort_code = EALREADY_COMMITTED, location = slot_game::slot_game)] 
    public entry fun test_can_not_commit_twice(
        fx: &signer,
        owner: &signer,
        user: &signer,
        zero: &signer,
    ) acquires GameCounter, GameCollectionCapability, Game, RandomnessCommitmentExt {
        setup_test(fx, owner, user, zero);

        let amount_to_play = 100;
        let items_id = 0;
        let game_id = 0;
        create_game(user, amount_to_play, items_id);

        make_random_slot_commit(game_id);
        make_random_slot_commit(game_id);
    }

    #[test(
        fx = @aptos_framework,
        owner = @0x100, 
        user = @0x123,
        zero = @0x0
    )]
    #[expected_failure(abort_code = ERANDOMNESS_COMMITMENT_NOT_EXIST, location = slot_game::slot_game)] 
    public entry fun test_can_not_reveal_without_commit_first(
        fx: &signer,
        owner: &signer,
        user: &signer,
        zero: &signer,
    ) acquires GameCounter, GameCollectionCapability, Game, RandomnessCommitmentExt {
        setup_test(fx, owner, user, zero);

        let amount_to_play = 100;
        let items_id = 0;
        let game_id = 0;
        create_game(user, amount_to_play, items_id);

        make_random_slot_reveal(game_id);
    }

    #[test(
        fx = @aptos_framework,
        owner = @0x100, 
        user = @0x123,
        zero = @0x0
    )]
    #[expected_failure(abort_code = EALREADY_REVEALED, location = slot_game::slot_game)] 
    public entry fun test_can_not_reveal_twice(
        fx: &signer,
        owner: &signer,
        user: &signer,
        zero: &signer,
    ) acquires GameCounter, GameCollectionCapability, Game, RandomnessCommitmentExt {
        setup_test(fx, owner, user, zero);

        let amount_to_play = 100;
        let items_id = 0;
        let game_id = 0;
        create_game(user, amount_to_play, items_id);

        make_random_slot_commit(game_id);
        make_random_slot_reveal(game_id);
        make_random_slot_reveal(game_id);
    }

    #[test(
        fx = @aptos_framework,
        owner = @0x100, 
        user = @0x123,
        zero = @0x0
    )]
    public entry fun test_commit_and_reveal_slot_game_happy_path(
        fx: &signer,
        owner: &signer,
        user: &signer,
        zero: &signer,
    ) acquires GameCounter, GameCollectionCapability, Game, RandomnessCommitmentExt {
        setup_test(fx, owner, user, zero);

        let amount_to_play = 100;
        let items_id = 0;
        let game_id = 0;
        create_game(user, amount_to_play, items_id);

        make_random_slot_commit(game_id);

        let slot_numbers_vector = vector<u8>[1, 9 , 11];
        assert!(get_slots_in_commitment(game_id) == slot_numbers_vector, 0);

        make_random_slot_reveal(game_id);

        let ( _, slots, _) = get_game(game_id);
        debug::print(&slots);
        assert!(slots.slot_1 == 1, 1);
        assert!(slots.slot_2 == 9, 2);
        assert!(slots.slot_3 == 11, 3);
    }
} 