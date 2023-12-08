module main::game{

    use aptos_framework::account::{Self, SignerCapability};
    use aptos_framework::object::{Self, Object};
    use aptos_std::smart_table::{Self, SmartTable};

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

    const ENOT_CREATOR: u64 = 1;
    const ENOT_OWNER: u64 = 2;
    const ECHAR_ID_NOT_FOUND: u64 = 3;
    const EINVALID_TABLE_LENGTH: u64 = 4;
    const EINVALID_PROPERTY_VALUE: u64 = 5;
    
    struct Character has key {
        name: String,
        character_id: u64,
        hp:u64,
        atk:u64,
        def:u64,
        atk_spd:u64,
        mv_spd:u64,
        mutator_ref: token::MutatorRef,
        burn_ref: token::BurnRef,
        property_mutator_ref: property_map::MutatorRef,
    }

    struct CharacterInfoEntry has store, copy, drop {
        name: String,
        character_id: u64,
        hp:u64,
        atk:u64,
        def:u64,
        atk_spd:u64,
        mv_spd:u64,
    }

    struct CharactersInfo has key {
        table: SmartTable<u64, CharacterInfoEntry>
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
    const CHARACTER_1_NAME: vector<u8> = b"Lyra Frostwhisper";
    const CHARACTER_2_NAME: vector<u8> = b"Orion Starcaster";

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
        
        let characters_info_table = aptos_std::smart_table::new();

        let character_stats = CharacterInfoEntry{
            name: string::utf8(CHARACTER_1_NAME),
            character_id: 0,
            hp: 100,
            atk: 10,
            def: 12,
            atk_spd: 14,
            mv_spd: 50,
        };

        let table_length = aptos_std::smart_table::length(&characters_info_table);

        smart_table::add(&mut characters_info_table, table_length, character_stats);
        let characters_info = CharactersInfo{
            table: characters_info_table
        };
        move_to(account, characters_info);
        
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

    public entry fun mint_character(user: &signer, character_id: u64) acquires CollectionCapability, CharactersInfo {
        assert!(character_id_exists(character_id), ECHAR_ID_NOT_FOUND);
        let character_info_entry = get_character_info_entry(character_id);        
        create_character(user, character_id, character_info_entry.name, character_info_entry.hp, 
        character_info_entry.atk, character_info_entry.def,
        character_info_entry.atk_spd, character_info_entry.mv_spd);

    }

    fun create_character(
        user: &signer, character_id: u64, token_name: String,
         hp: u64, atk: u64, def: u64,
         atk_spd: u64, mv_spd: u64
    ): Object<Character> acquires CollectionCapability {
        let uri = string::utf8(UC_CHARACTER_COLLECTION_URI);
        let description = string::utf8(UC_CHARACTER_COLLECTION_DESCRIPTION);

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

        // Initialize the property map.
        let properties = property_map::prepare_input(vector[], vector[], vector[]);
        property_map::init(&constructor_ref, properties);
        property_map::add_typed(
            &property_mutator_ref,
            string::utf8(b"HP"),
            hp
        );
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
            character_id: character_id,
            hp: hp,
            atk: atk,
            def: def,
            atk_spd: atk_spd,
            mv_spd: mv_spd,
            mutator_ref,
            burn_ref,
            property_mutator_ref
        };

        move_to(&token_signer, new_char);
        let created_token = object::object_from_constructor_ref<Token>(&constructor_ref);
        object::transfer(&get_token_signer() , created_token, signer::address_of(user));
        object::address_to_object(signer::address_of(&token_signer))
    }

    entry fun upgrade_character(character_object: Object<Character>) acquires Character {
        let character_token_address = object::object_address(&character_object);
        let character = borrow_global_mut<Character>(character_token_address);
        // Gets `property_mutator_ref` to update the attack point in the property map.
        let property_mutator_ref = &character.property_mutator_ref;
        // Updates the attack point in the property map.
        let current_atk = character.atk;
        property_map::update_typed(property_mutator_ref, &string::utf8(b"ATK"), current_atk + 5);

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

    // ANCHOR Aptos Utility Functions

    public(friend) entry fun add_character_entry(account: &signer , name: String, 
        hp: u64, atk: u64,
        def: u64, atk_spd: u64, mv_spd: u64) acquires CharactersInfo {
        assert!(signer::address_of(account) == @main, ENOT_CREATOR);

        let characters_info_table = &mut borrow_global_mut<CharactersInfo>(@main).table;
        let table_length = aptos_std::smart_table::length(characters_info_table);
        let character_info_entry = CharacterInfoEntry{
            name: name,
            character_id: table_length,
            hp,
            atk,
            def,
            atk_spd,
            mv_spd,
        };
        smart_table::add(characters_info_table, table_length, character_info_entry);
    }

    public fun character_id_exists(character_id: u64): bool acquires CharactersInfo {
        let characters_info_table = &borrow_global<CharactersInfo>(@main).table;
        smart_table::contains(characters_info_table, character_id)
    }

    // ANCHOR Aptos View Functions

    #[view]
    public fun get_character_info_entry(character_id: u64): CharacterInfoEntry acquires CharactersInfo {
        let characters_info_table = &borrow_global<CharactersInfo>(@main).table;
        *smart_table::borrow(characters_info_table, character_id)
    }

    #[view]
    public fun get_characters_table_length(): u64 acquires CharactersInfo {
        let characters_info_table = &borrow_global<CharactersInfo>(@main).table;
        aptos_std::smart_table::length(characters_info_table)
    }

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

    // #[view]
    // public fun get_character_stats(char: Object<Character>): (String, u64, u64, u64, u64, u64) acquires Character, CollectionCapability {
    //     let collection = string::utf8(UC_CHARACTER_COLLECTION_NAME);
    //     let token_name = to_string(&user_addr);
    //     let token_address = token::create_token_address(
    //         &user_addr,
    //         &collection,
    //         &token_name,
    //     );
    //     let has_char = exists<Character>(token_address);

    //     if (!has_char) {
    //         return (string::utf8(b""), 0, 0, 0, 0, 0)
    //     };
    //     let char = get_character_internal(&user_addr);
    //     (char.name, char.hp, char.def, char.atk, char.atk_spd, char.mv_spd)
    // }

 


    // ANCHOR TESTING

   
    // TODO: Viewing Function of properties of object
    // TODO: Test if properties of minted character is the same as that stored in table.
    #[test(creator = @main)]
    public fun init_module_for_test(creator: &signer) {
        init_module(creator);
    }

    #[test(creator = @main)]
    public fun test_character_addition_to_table(creator: &signer) acquires CharactersInfo {
        init_module(creator);
        add_character_entry(creator, string::utf8(b"Char1"), 100, 10, 11, 12, 50);
        add_character_entry(creator, string::utf8(b"Char2"), 110, 10, 11, 12, 50);

        assert!(get_characters_table_length()==3, EINVALID_TABLE_LENGTH)
    }

    #[test(creator = @main, user1 = @0x456 )]
    #[expected_failure(abort_code = ENOT_CREATOR)]
    public fun test_add_character_by_others(creator: &signer, user1: &signer) acquires CharactersInfo {
        init_module(creator);
        add_character_entry(user1, string::utf8(b"Char1"), 100, 10, 11, 12, 50);

    }

    #[test(creator = @main, user1 = @0x456, _user2 = @0x789)]
    public fun test_mint(creator: &signer, user1: &signer, _user2: &signer) acquires CollectionCapability, Character, CharactersInfo {
   
        init_module(creator);
        mint_character(user1, 0);
        add_character_entry(creator, string::utf8(b"Char1"), 100, 10, 11, 12, 50);
        mint_character(user1, 1);

        let user_1_address = signer::address_of(user1);

        let char1 = create_character(user1, 0,  string::utf8(CHARACTER_1_NAME), 
            100, 10, 11, 
            12, 50);

        assert!(object::is_owner(char1, user_1_address), ENOT_OWNER);
        upgrade_character(char1);
        assert!(property_map::read_u64(&char1, &string::utf8(b"ATK"))==15, EINVALID_PROPERTY_VALUE);

        assert!(get_character_info_entry(0).hp==100, EINVALID_PROPERTY_VALUE);

    }

    #[test(creator = @main, user1 = @0x456)]
    #[expected_failure(abort_code=ECHAR_ID_NOT_FOUND)]
    public fun test_mint_unlisted_char(creator: &signer, user1: &signer) acquires CollectionCapability, CharactersInfo {
        init_module(creator);
        mint_character(user1, 1);
    }
}