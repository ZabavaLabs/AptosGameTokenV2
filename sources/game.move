module main::game{

    use aptos_framework::account::{Self, SignerCapability};
    use aptos_framework::object::{Self};
    // use aptos_framework::timestamp;
    use aptos_token_objects::collection;
    use aptos_token_objects::token::{Self, Token};
    use aptos_token_objects::property_map;

    use std::option;
    use std::signer;
    // use std::signer::address_of;
    use std::string::{Self, String};
    use aptos_std::string_utils::{to_string};

    // use std::debug::print;
    // use std::vector;

    struct Character has key {
        name: String,
        hp:u64,
        def:u64,
        atk:u64,
        atk_spd:u64,
        mv_spd:u64,
        mutator_ref: token::MutatorRef,
        burn_ref: token::BurnRef
    }

    // Tokens require a signer to create, so this is the signer for the collection
    struct CollectionCapability has key, drop {
        capability: SignerCapability,
        burn_signer_capability: SignerCapability,
    }

    const APP_SIGNER_CAPABILITY_SEED: vector<u8> = b"APP_SIGNER_CAPABILITY";
    const BURN_SIGNER_CAPABILITY_SEED: vector<u8> = b"BURN_SIGNER_CAPABILITY";
    const UC_CHARACTER_COLLECTION_NAME: vector<u8> = b"UC Character Collection Name";
    const UC_CHARACTER_COLLECTION_DESCRIPTION: vector<u8> = b"UC Character Collection Description";
    const UC_CHARACTER_COLLECTION_URI: vector<u8> = b"https://aptos.dev/img/nyan.jpeg";

    fun init_module(account: &signer) {
        let (token_resource, token_signer_cap) = account::create_resource_account(
            account,
            APP_SIGNER_CAPABILITY_SEED,
        );
        let (_, burn_signer_capability) = account::create_resource_account(
            account,
            BURN_SIGNER_CAPABILITY_SEED,
        );
        move_to(account, CollectionCapability {
            capability: token_signer_cap,
            burn_signer_capability,
        });

        create_character_collection(&token_resource);
        
    }

    fun get_token_signer(): signer acquires CollectionCapability {
        account::create_signer_with_capability(&borrow_global<CollectionCapability>(@main).capability)
    }

    fun create_character_collection(creator: &signer) {
        let description = string::utf8(UC_CHARACTER_COLLECTION_DESCRIPTION);
        let name = string::utf8(UC_CHARACTER_COLLECTION_NAME);
        let uri = string::utf8(UC_CHARACTER_COLLECTION_URI);

        collection::create_unlimited_collection(
            creator,
            description,
            name,
            option::none(),
            uri,
        );
    }

    public entry fun mint_character(user: &signer, token_name: String,
         hp: u64, def: u64, atk: u64,
         atk_spd: u64, mv_spd: u64) acquires CollectionCapability {
        let uri = string::utf8(UC_CHARACTER_COLLECTION_URI);
        let description = string::utf8(UC_CHARACTER_COLLECTION_DESCRIPTION);
        // let token_name = to_string(&address_of(user));

        let constructor_ref = token::create_named_token(
            &get_token_signer(),
            string::utf8(UC_CHARACTER_COLLECTION_NAME),
            description,
            token_name,
            option::none(),
            uri,
        );

        let token_signer = object::generate_signer(&constructor_ref);
        let mutator_ref = token::generate_mutator_ref(&constructor_ref);
        let burn_ref = token::generate_burn_ref(&constructor_ref);
        let property_mutator_ref = property_map::generate_mutator_ref(&constructor_ref);

        // Initializes the value with the given value in armor. Not needed to store it globally for now.
        // move_to(&object_signer, EquipmentStats { value: restoration_value });

        // Initialize the property map.
        let properties = property_map::prepare_input(vector[], vector[], vector[]);
        property_map::init(&constructor_ref, properties);
        property_map::add_typed(
            &property_mutator_ref,
            string::utf8(b"ATK"),
            atk
        );
        property_map::add_typed(
            &property_mutator_ref,
            string::utf8(b"DEF"),
            def
        );
        property_map::add_typed(
            &property_mutator_ref,
            string::utf8(b"HP"),
            hp
        );
        property_map::add_typed(
            &property_mutator_ref,
            string::utf8(b"ATK_SPD"),
            atk_spd
        );
        property_map::add_typed(
            &property_mutator_ref,
            string::utf8(b"MV_SPD"),
            mv_spd
        );

        let new_char = Character {
            name: token_name,
            hp: hp,
            def: def,
            atk: atk,
            atk_spd: atk_spd,
            mv_spd: mv_spd,
            mutator_ref,
            burn_ref,
        };

        move_to(&token_signer, new_char);
        let created_token = object::object_from_constructor_ref<Token>(&constructor_ref);
        object::transfer(&get_token_signer() , created_token, signer::address_of(user));
    }

    public entry fun mint_character_unlimited(user: &signer, token_name: String,
         hp: u64, def: u64, atk: u64,
         atk_spd: u64, mv_spd: u64) acquires CollectionCapability {
        let uri = string::utf8(UC_CHARACTER_COLLECTION_URI);
        let description = string::utf8(UC_CHARACTER_COLLECTION_DESCRIPTION);
        // let token_name = to_string(&address_of(user));

        let constructor_ref = token::create_from_account(
            &get_token_signer(),
            string::utf8(UC_CHARACTER_COLLECTION_NAME),
            description,
            token_name,
            option::none(),
            uri,
        );

        let token_signer = object::generate_signer(&constructor_ref);
        let mutator_ref = token::generate_mutator_ref(&constructor_ref);
        let burn_ref = token::generate_burn_ref(&constructor_ref);
        let property_mutator_ref = property_map::generate_mutator_ref(&constructor_ref);

        // Initializes the value with the given value in armor. Not needed to store it globally for now.
        // move_to(&object_signer, EquipmentStats { value: restoration_value });

        // Initialize the property map.
        let properties = property_map::prepare_input(vector[], vector[], vector[]);
        property_map::init(&constructor_ref, properties);
        property_map::add_typed(
            &property_mutator_ref,
            string::utf8(b"ATK"),
            atk
        );
        property_map::add_typed(
            &property_mutator_ref,
            string::utf8(b"DEF"),
            def
        );
        property_map::add_typed(
            &property_mutator_ref,
            string::utf8(b"HP"),
            hp
        );
        property_map::add_typed(
            &property_mutator_ref,
            string::utf8(b"ATK_SPD"),
            atk_spd
        );
        property_map::add_typed(
            &property_mutator_ref,
            string::utf8(b"MV_SPD"),
            mv_spd
        );

        let new_char = Character {
            name: token_name,
            hp: hp,
            def: def,
            atk: atk,
            atk_spd: atk_spd,
            mv_spd: mv_spd,
            mutator_ref,
            burn_ref,
        };

        move_to(&token_signer, new_char);
        let created_token = object::object_from_constructor_ref<Token>(&constructor_ref);
        object::transfer(&get_token_signer() , created_token, signer::address_of(user));
    }

    fun get_character_address(creator_addr: &address): (address) acquires CollectionCapability {
        let collection = string::utf8(UC_CHARACTER_COLLECTION_NAME);
        let token_name = to_string(creator_addr);
        let creator = &get_token_signer();
        let token_address = token::create_token_address(
            &signer::address_of(creator),
            &collection,
            &token_name,
        );

        token_address
    }


    inline fun get_character_internal(creator_addr: &address): (&Character) acquires Character {
        let collection = string::utf8(UC_CHARACTER_COLLECTION_NAME);
        let token_name = to_string(creator_addr);
        let creator = &get_token_signer();
        let token_address = token::create_token_address(
            &signer::address_of(creator),
            &collection,
            &token_name,
        );
        (borrow_global<Character>(token_address))
    }

    inline fun get_character_internal_mut(creator_addr: &address): (&mut Character) acquires Character {
        let collection = string::utf8(UC_CHARACTER_COLLECTION_NAME);
        let token_name = to_string(creator_addr);
        let creator = &get_token_signer();
        let token_address = token::create_token_address(
            &signer::address_of(creator),
            &collection,
            &token_name,
        );
        (borrow_global_mut<Character>(token_address))
    }
    

    // public entry fun burn_character_internal(creator_addr: &address) acquires Character,CollectionCapability{
        
    //     let collection = string::utf8(UC_CHARACTER_COLLECTION_NAME);
    //     let token_name = to_string(creator_addr);
    //     let creator = &get_token_signer();
    //     let token_address = token::create_token_address(
    //         &signer::address_of(creator),
    //         &collection,
    //         &token_name,
    //     );
    //     let char = (borrow_global_mut<Character>(token_address));

    //     token::burn(&char.burn_ref);
    // }

    #[view]
    public fun get_name(user_addr: address): String acquires Character, CollectionCapability {
        let char = get_character_internal_mut(&user_addr);

        char.name
    }

    public entry fun set_name(user_addr: address, name: String) acquires Character, CollectionCapability {
        let char = get_character_internal_mut(&user_addr);
        char.name = name;
        char.name;
    }

    #[view]
    public fun get_hp(user_addr: address): u64 acquires Character, CollectionCapability {
        let char = get_character_internal_mut(&user_addr);
        char.hp
    }

    public entry fun set_hp(user_addr: address, hp: u64) acquires Character, CollectionCapability {
        let char = get_character_internal_mut(&user_addr);
        char.hp = hp;
        char.hp;
    }

    #[view]
    public fun get_def(user_addr: address): u64 acquires Character, CollectionCapability {
        let char = get_character_internal_mut(&user_addr);
        char.def
    }

    public entry fun set_def(user_addr: address, def: u64) acquires Character, CollectionCapability {
        let char = get_character_internal_mut(&user_addr);
        char.def = def;
        char.def;
    }
    #[view]
    public fun get_atk(user_addr: address): u64 acquires Character, CollectionCapability {
        let char = get_character_internal_mut(&user_addr);
        char.atk
    }

    public entry fun set_str(user_addr: address, atk: u64) acquires Character, CollectionCapability {
        let char = get_character_internal_mut(&user_addr);
        char.atk = atk;
        char.atk;
    }
    #[view]
    public fun get_atk_spd(user_addr: address): u64 acquires Character, CollectionCapability {
        let char = get_character_internal_mut(&user_addr);
        char.atk_spd
    }

    public entry fun set_atk_spd(user_addr: address, atk_spd: u64) acquires Character, CollectionCapability {
        let char = get_character_internal_mut(&user_addr);
        char.atk_spd = atk_spd;
        char.atk_spd;
    }
    #[view]
    public fun get_mv_spd(user_addr: address): u64 acquires Character, CollectionCapability {
        let char = get_character_internal_mut(&user_addr);
        char.mv_spd
    }

    public entry fun set_mv_spd(user_addr: address, mv_spd: u64) acquires Character, CollectionCapability {
        let char = get_character_internal_mut(&user_addr);
        char.mv_spd = mv_spd;
        char.mv_spd;
    }

    #[view]
    public fun get_character(user_addr: address): (String, u64, u64, u64, u64, u64) acquires Character, CollectionCapability {
        let collection = string::utf8(UC_CHARACTER_COLLECTION_NAME);
        let token_name = to_string(&user_addr);
        let token_address = token::create_token_address(
            &user_addr,
            &collection,
            &token_name,
        );
        let has_char = exists<Character>(token_address);

        if (!has_char) {
            return (string::utf8(b""), 0, 0, 0, 0, 0)
        };
        let char = get_character_internal(&user_addr);
        (char.name, char.hp, char.def, char.atk, char.atk_spd, char.mv_spd)
    }

    // Returns true if this address owns an Aptogotchi
    #[view]
    public fun has_character(owner_addr: address): (bool) acquires CollectionCapability {
        let token_address = get_character_address(&owner_addr);
        let has_character = exists<Character>(token_address);

        has_character
    }

     #[test_only]
    public fun init_module_for_test(creator: &signer) {
        init_module(creator);
    }

    #[test(creator = @main, user1 = @0x456, _user2 = @0x789)]
    public fun test_mint(creator: &signer, user1: &signer, _user2: &signer) acquires CollectionCapability {
   
        init_module(creator);

        // -------------------------------------------
        // Creator mints and sends 100 irons to User1.
        // -------------------------------------------
        // let user1_addr = signer::address_of(user1);
        // let user2_addr = signer::address_of(user2);

        mint_character_unlimited(user1, string::utf8(b"Jane") , 100, 12, 5, 10, 20);
        mint_character_unlimited(user1, string::utf8(b"Jane") , 101, 12, 5, 10, 20);

        // let owns_character = has_character(signer::address_of(user1));
        // assert!(owns_character, 1);

        // let iron_armor_token = object::address_to_object<ArmorToken>(
        //     equipment_token_address(
        //         string::utf8(ARMOR_COLLECTION_NAME), 
        //         string::utf8(IRON_ARMOR_TOKEN_NAME)
        //     )
        // );
        // Assert that the user1 has 100 irons.
        // assert!(armor_balance(user1_addr, iron_armor_token) == 100, 0);
        // assert!(armor_balance(user2_addr, iron_armor_token) == 200, 0);

        // -------------------------------------------
        // Creator mints and sends 200 leathers to User2.
        // -------------------------------------------
        // let user2_addr = signer::address_of(user2);
        // mint_equipment(creator, user2_addr, string::utf8(ARMOR_COLLECTION_NAME), string::utf8(LEATHER_ARMOR_TOKEN_NAME), 100);
        // let leather_token = object::address_to_object<ArmorToken>(equipment_token_address(
        //     string::utf8(ARMOR_COLLECTION_NAME), 
        //     string::utf8(LEATHER_ARMOR_TOKEN_NAME)
        // ));
        // Assert that the user2 has 200 leathers.
        // assert!(armor_balance(user2_addr, leather_token) == 100, 0);

        // ------------------------------
        // User1 sends 10 irons to User2.
        // ------------------------------
        // transfer_equipment(user2, user1_addr, string::utf8(ARMOR_COLLECTION_NAME), string::utf8(LEATHER_ARMOR_TOKEN_NAME) , 10);
        // Assert that the user1 has 90 irons.
        // assert!(armor_balance(user2_addr, leather_token) == 90, 0);
        // Assert that the user2 has 10 irons.
        // assert!(armor_balance(user1_addr, leather_token) == 10, 0);

        // burn_armor(user2, leather_token, 90);
        // assert!(armor_balance(user2_addr, leather_token) == 0, 0);

    }

}