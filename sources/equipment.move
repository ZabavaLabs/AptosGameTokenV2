module main::equipment{

    use aptos_framework::account::{Self, SignerCapability};
    use aptos_framework::object::{Self, Object};
    use aptos_std::smart_table::{Self, SmartTable};

    use aptos_token_objects::collection;
    use aptos_token_objects::token::{Self, Token};
    use aptos_token_objects::property_map;

    // use aptos_framework::fungible_asset::{Self, Metadata};
    // use aptos_framework::primary_fungible_store;

    // use std::error;
    use std::option;
    use std::signer;
    // use std::signer::address_of;
    use std::string::{Self, String};
    // use aptos_std::string_utils::{to_string};

    use main::gem::{Self, GemToken};

    use main::admin::{Self, ENOT_ADMIN};
    use main::omni_cache;

    // use std::debug::print;
    // use std::vector;

    const ENOT_OWNER: u64 = 2;
    const ECHAR_ID_NOT_FOUND: u64 = 3;
    const EINVALID_TABLE_LENGTH: u64 = 4;
    const EINVALID_PROPERTY_VALUE: u64 = 5;
    const EINVALID_BALANCE: u64 = 6;
    const EMAX_LEVEL: u64 = 7;
    const EINSUFFICIENT_BALANCE: u64 = 65540;
    
    friend omni_cache;

    struct GameData has key {
        max_equipment_level: u64
    }

    struct EquipmentCapability has key {
        // name: String,
        // description: String,
        // uri: String,
        // equipment_id: u64,
        // equipment_part_id: u64,
        // affinity_id: u64,
        // grade:u64,
        // level: u64,
        // hp:u64,
        // atk:u64,
        // def:u64,
        // atk_spd:u64,
        // mv_spd:u64,
        // growth_hp:u64,
        // growth_atk:u64,
        // growth_def:u64,
        // growth_atk_spd:u64,
        // growth_mv_spd:u64,
        mutator_ref: token::MutatorRef,
        burn_ref: token::BurnRef,
        property_mutator_ref: property_map::MutatorRef,
    }

    struct EquipmentInfoEntry has store, copy, drop {
        name: String,
        description: String,
        uri: String,
        equipment_id: u64,
        equipment_part_id:u64,
        affinity_id: u64,
        grade: u64,
        hp:u64,
        atk:u64,
        def:u64,
        atk_spd:u64,
        mv_spd:u64,
        growth_hp:u64,
        growth_atk:u64,
        growth_def:u64,
        growth_atk_spd:u64,
        growth_mv_spd:u64,
    }

    struct EquipmentInfo has key {
        table: SmartTable<u64, EquipmentInfoEntry>
    }

    // Tokens require a signer to create, so this is the signer for the collection
    struct CollectionCapability has key, drop {
        capability: SignerCapability,
        burn_signer_capability: SignerCapability,
    }


    const APP_SIGNER_CAPABILITY_SEED: vector<u8> = b"APP_SIGNER_CAPABILITY";
    const BURN_SIGNER_CAPABILITY_SEED: vector<u8> = b"BURN_SIGNER_CAPABILITY";
    const UC_EQUIPMENT_COLLECTION_NAME: vector<u8> = b"Undying City Equipment Collection";
    const UC_EQUIPMENT_COLLECTION_DESCRIPTION: vector<u8> = b"Contains all the Undying City equipment";
    
    // TODO: Change the equipment collection uri
    const UC_EQUIPMENT_COLLECTION_URI: vector<u8> = b"https://aptos.dev/img/nyan.jpeg";
   
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

        let description = string::utf8(UC_EQUIPMENT_COLLECTION_DESCRIPTION);
        let name = string::utf8(UC_EQUIPMENT_COLLECTION_NAME);
        let uri = string::utf8(UC_EQUIPMENT_COLLECTION_URI);

        create_equipment_collection(&token_resource, description, name, uri);
        
        let equipment_info_table = aptos_std::smart_table::new();

        let equipment_info = EquipmentInfo{
            table: equipment_info_table
        };
        move_to(account, equipment_info);

        let gameData = GameData{
            max_equipment_level: 50
        };

        move_to(account, gameData);
    }

    public entry fun edit_max_weapon_level(caller: &signer, new_max_level: u64) acquires GameData {
        let caller_address = signer::address_of(caller);
        admin::assert_is_admin(caller_address);
        let game_data = borrow_global_mut<GameData>(@main);
        game_data.max_equipment_level = new_max_level;
    }

    fun get_token_signer(): signer acquires CollectionCapability {
        account::create_signer_with_capability(&borrow_global<CollectionCapability>(@main).capability)
    }

    fun create_equipment_collection(creator: &signer, description: String, name: String, uri: String) {

        collection::create_unlimited_collection(
            creator,
            description,
            name,
            option::none(),
            uri,
        );
    }

    public(friend) fun mint_equipment(user: &signer, equipment_id: u64) acquires CollectionCapability, EquipmentInfo {
        assert!(equipment_id_exists(equipment_id), ECHAR_ID_NOT_FOUND);
        let equipment_info_entry = get_equipment_info_entry(equipment_id);        
        let level = 1;
        create_equipment(user, 
        equipment_id, equipment_info_entry.name, 
        equipment_info_entry.description, equipment_info_entry.uri, 
        equipment_info_entry.affinity_id, equipment_info_entry.equipment_part_id,
        equipment_info_entry.grade, level,
        equipment_info_entry.hp, 
        equipment_info_entry.atk, equipment_info_entry.def,
        equipment_info_entry.atk_spd, equipment_info_entry.mv_spd,
        equipment_info_entry.growth_hp, 
        equipment_info_entry.growth_atk, equipment_info_entry.growth_def,
        equipment_info_entry.growth_atk_spd, equipment_info_entry.growth_mv_spd
        );
    }

    fun create_equipment(
        user: &signer, 
        equipment_id: u64, token_name: String, 
        token_description: String, token_uri: String, 
        equipment_part_id: u64, affinity_id: u64,
        grade: u64, level:u64,
        hp: u64, atk: u64, def: u64,
        atk_spd: u64, mv_spd: u64,
        growth_hp: u64, growth_atk: u64, growth_def: u64,
        growth_atk_spd: u64, growth_mv_spd: u64
    ): Object<EquipmentCapability> acquires CollectionCapability {

        let constructor_ref = token::create_from_account(
            &get_token_signer(),
            string::utf8(UC_EQUIPMENT_COLLECTION_NAME),
            token_description,
            token_name,
            option::none(),
            token_uri,
        );

        let token_signer = object::generate_signer(&constructor_ref);
        let mutator_ref = token::generate_mutator_ref(&constructor_ref);
        let burn_ref = token::generate_burn_ref(&constructor_ref);
        let property_mutator_ref = property_map::generate_mutator_ref(&constructor_ref);

        // Initialize the property map.
        // name: String,
        // description: String,
        // uri: String,
        // equipment_id: u64,
        // equipment_part_id: u64,
        // affinity_id: u64,
        // grade: u64,
        // hp:u64,
        // atk:u64,
        // def:u64,
        // atk_spd:u64,
        // mv_spd:u64,
        // growth_hp:u64,
        // growth_atk:u64,
        // growth_def:u64,
        // growth_atk_spd:u64,
        // growth_mv_spd:u64,

        let properties = property_map::prepare_input(vector[], vector[], vector[]);
        property_map::init(&constructor_ref, properties);
        property_map::add_typed(
            &property_mutator_ref,
            string::utf8(b"EQUIPMENT_ID"),
            equipment_id
        );
        property_map::add_typed(
            &property_mutator_ref,
            string::utf8(b"EQUIPMENT_PART_ID"),
            equipment_part_id
        );
        property_map::add_typed(
            &property_mutator_ref,
            string::utf8(b"AFFINITY_ID"),
            affinity_id
        );
        property_map::add_typed(
            &property_mutator_ref,
            string::utf8(b"GRADE"),
            grade
        );
        property_map::add_typed(
            &property_mutator_ref,
            string::utf8(b"LEVEL"),
            level
        );
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
        property_map::add_typed(
            &property_mutator_ref,
            string::utf8(b"GROWTH_HP"),
            growth_hp
        );
        property_map::add_typed(
            &property_mutator_ref,
            string::utf8(b"GROWTH_ATK"),
            growth_atk
        );
        property_map::add_typed(
            &property_mutator_ref,
            string::utf8(b"GROWTH_DEF"),
            growth_def
        );

        property_map::add_typed(
            &property_mutator_ref,
            string::utf8(b"GROWTH_ATK_SPD"),
            growth_atk_spd
        );
        property_map::add_typed(
            &property_mutator_ref,
            string::utf8(b"GROWTH_MV_SPD"),
            growth_mv_spd
        );

        let new_equipment = EquipmentCapability {
            mutator_ref,
            burn_ref,
            property_mutator_ref
        };

        move_to(&token_signer, new_equipment);
        let created_token = object::object_from_constructor_ref<Token>(&constructor_ref);
        object::transfer(&get_token_signer() , created_token, signer::address_of(user));
        object::address_to_object(signer::address_of(&token_signer))
    }
   
    public entry fun upgrade_equipment(from: &signer, equipment_object: Object<EquipmentCapability>, gem_object: Object<GemToken>, amount: u64) acquires EquipmentCapability, GameData {
        assert!(object::is_owner(equipment_object, signer::address_of(from)), ENOT_OWNER);
        gem::burn_gem(from, gem_object, amount);
        let equipment_token_address = object::object_address(&equipment_object);
        let equipment = borrow_global_mut<EquipmentCapability>(equipment_token_address);
        // Gets `property_mutator_ref` to update the attack point in the property map.
        let property_mutator_ref = &equipment.property_mutator_ref;
        // Updates the attack point in the property map.
        let current_lvl = property_map::read_u64(&equipment_object, &string::utf8(b"LEVEL"));

        // Prevents upgrading beyond a certain level.
        let game_data = borrow_global<GameData>(@main);
        assert!( current_lvl + amount <= game_data.max_equipment_level, EMAX_LEVEL);

        let current_hp = property_map::read_u64(&equipment_object, &string::utf8(b"HP"));
        let current_atk = property_map::read_u64(&equipment_object, &string::utf8(b"ATK"));
        let current_def = property_map::read_u64(&equipment_object, &string::utf8(b"DEF"));
        let current_atk_spd = property_map::read_u64(&equipment_object, &string::utf8(b"ATK_SPD"));
        let current_mv_spd = property_map::read_u64(&equipment_object, &string::utf8(b"MV_SPD"));

        let growth_hp = property_map::read_u64(&equipment_object, &string::utf8(b"GROWTH_HP"));
        let growth_atk = property_map::read_u64(&equipment_object, &string::utf8(b"GROWTH_ATK"));
        let growth_def = property_map::read_u64(&equipment_object, &string::utf8(b"GROWTH_DEF"));
        let growth_atk_spd = property_map::read_u64(&equipment_object, &string::utf8(b"GROWTH_ATK_SPD"));
        let growth_mv_spd = property_map::read_u64(&equipment_object, &string::utf8(b"GROWTH_MV_SPD"));

        property_map::update_typed(property_mutator_ref, &string::utf8(b"LEVEL"), current_lvl + (amount));
        property_map::update_typed(property_mutator_ref, &string::utf8(b"HP"), current_hp + (amount * growth_hp));
        property_map::update_typed(property_mutator_ref, &string::utf8(b"ATK"), current_atk + (amount * growth_atk));
        property_map::update_typed(property_mutator_ref, &string::utf8(b"DEF"), current_def + (amount * growth_def));
        property_map::update_typed(property_mutator_ref, &string::utf8(b"ATK_SPD"), current_atk_spd + (amount * growth_atk_spd));
        property_map::update_typed(property_mutator_ref, &string::utf8(b"MV_SPD"), current_mv_spd + (amount * growth_mv_spd));



    }
    
    // ANCHOR Aptos Utility Functions

    public entry fun add_equipment_entry(
        account: &signer, 
        name: String, 
        description: String, 
        uri: String,
        equipment_part_id: u64,
        affinity_id: u64, 
        grade: u64,
        hp: u64, 
        atk: u64,
        def: u64, 
        atk_spd: u64, 
        mv_spd: u64,
        growth_hp:u64,
        growth_atk:u64,
        growth_def:u64,
        growth_atk_spd:u64,
        growth_mv_spd:u64,
        ) acquires EquipmentInfo {

        admin::assert_is_admin(signer::address_of(account));

        let equipment_info_table = &mut borrow_global_mut<EquipmentInfo>(@main).table;
        let table_length = aptos_std::smart_table::length(equipment_info_table);

        let equipment_info_entry = EquipmentInfoEntry{
            name,
            description,
            uri,
            equipment_id: table_length,
            equipment_part_id,
            affinity_id,
            grade,
            hp,
            atk,
            def,
            atk_spd,
            mv_spd,
            growth_hp,
            growth_atk,
            growth_def,
            growth_atk_spd,
            growth_mv_spd,
        };
        smart_table::add(equipment_info_table, table_length, equipment_info_entry);
    }

    public fun equipment_id_exists(equipment_id: u64): bool acquires EquipmentInfo {
        let equipment_info_table = &borrow_global<EquipmentInfo>(@main).table;
        smart_table::contains(equipment_info_table, equipment_id)
    }

    // ANCHOR Aptos View Functions

    #[view]
    public fun get_equipment_info_entry(equipment_id: u64): EquipmentInfoEntry acquires EquipmentInfo {
        let equipment_info_table = &borrow_global<EquipmentInfo>(@main).table;
        *smart_table::borrow(equipment_info_table, equipment_id)
    }

    #[view]
    public fun get_equipment_table_length(): u64 acquires EquipmentInfo {
        let equipment_info_table = &borrow_global<EquipmentInfo>(@main).table;
        aptos_std::smart_table::length(equipment_info_table)
    } 


    // ANCHOR TESTING

   
    // TODO: Viewing Function of properties of object
    // TODO: Test if properties of minted equipment is the same as that stored in table.
    #[test(creator = @main)]
    public fun init_module_for_test(creator: &signer) {
        init_module(creator);
    }

    #[test(creator = @main)]
    public fun test_equipment_addition_to_table(creator: &signer) acquires EquipmentInfo {
        init_module(creator);
        admin::initialize(creator);
        let equipment_part_id = 1;
        let affinity_id = 1;
        let grade = 1;
        add_equipment_entry(creator, 
        string::utf8(b"Equipment Name"), 
        string::utf8(b"Equipment Description"),
        string::utf8(b"Equipment uri"),
        equipment_part_id,
        affinity_id,
        grade,
        100, 10, 11, 12, 50,
        10, 5, 5, 5, 5);

        add_equipment_entry(creator, 
        string::utf8(b"Equipment Name"), 
        string::utf8(b"Equipment Description"),
        string::utf8(b"Equipment uri"),
        equipment_part_id,
        affinity_id,
        grade,
        100, 10, 11, 12, 50,
        10, 5, 5, 5, 5);
        assert!(get_equipment_table_length()==2, EINVALID_TABLE_LENGTH)
    }

    #[test(creator = @main, user1 = @0x456 )]
    #[expected_failure(abort_code = ENOT_ADMIN, location = main::admin)]
    public fun test_add_equipment_by_others(creator: &signer, user1: &signer) acquires EquipmentInfo {
        init_module(creator);
        admin::initialize(creator);
        let equipment_part_id = 1;
        let affinity_id = 1;
        let grade = 1;
        add_equipment_entry(user1, 
        string::utf8(b"Equipment Name"), 
        string::utf8(b"Equipment Description"),
        string::utf8(b"Equipment uri"),
        equipment_part_id,
        affinity_id,
        grade,
        100, 10, 11, 12, 50,
        10, 5, 5, 5, 5);
    }

    #[test(creator = @main, user1 = @0x456 )]
    public fun test_edit_admin(creator: &signer, user1: &signer) acquires EquipmentInfo {
        init_module(creator);
        admin::initialize(creator);
        let equipment_part_id = 1;
        let affinity_id = 1;
        let grade = 1;
        add_equipment_entry(creator, 
        string::utf8(b"Equipment Name"), 
        string::utf8(b"Equipment Description"),
        string::utf8(b"Equipment uri"),
        equipment_part_id,
        affinity_id,
        grade,
        100, 10, 11, 12, 50,
        10, 5, 5, 5, 5);
        admin::edit_admin(creator, signer::address_of(user1));
        add_equipment_entry(user1, 
        string::utf8(b"Equipment Name"), 
        string::utf8(b"Equipment Description"),
        string::utf8(b"Equipment uri"),
        equipment_part_id,
        affinity_id,
        grade,
        100, 10, 11, 12, 50,
        10, 5, 5, 5, 5);
    }

    #[test(creator = @main, user1 = @0x456 )]
    #[expected_failure(abort_code = ENOT_ADMIN)]
    public fun test_edit_admin_2(creator: &signer, user1: &signer) acquires EquipmentInfo {
        init_module(creator);
        admin::initialize(creator);

        let equipment_part_id = 1;
        let affinity_id = 1;
        let grade = 1;
        add_equipment_entry(creator, 
        string::utf8(b"Equipment Name"), 
        string::utf8(b"Equipment Description"),
        string::utf8(b"Equipment uri"),
        equipment_part_id,
        affinity_id,
        grade,
        100, 10, 11, 12, 50,
        10, 5, 5, 5, 5);
        admin::edit_admin(creator, signer::address_of(user1));
        add_equipment_entry(creator, 
        string::utf8(b"Equipment Name"), 
        string::utf8(b"Equipment Description"),
        string::utf8(b"Equipment uri"),
        equipment_part_id,
        affinity_id,
        grade,
        100, 10, 11, 12, 50,
        10, 5, 5, 5, 5);
    }

    #[test(creator = @main, user1 = @0x456)]
    public fun test_mint(creator: &signer, user1: &signer) acquires CollectionCapability, EquipmentInfo{
   
        init_module(creator);
        admin::initialize(creator);

        let equipment_part_id = 1;
        let affinity_id = 1;
        let grade = 1;
        let level = 1;
        add_equipment_entry(creator, 
        string::utf8(b"Equipment Name"), 
        string::utf8(b"Equipment Description"),
        string::utf8(b"Equipment uri"),
        equipment_part_id,
        affinity_id,
        grade,
        100, 10, 11, 12, 50,
        10, 5, 5, 5, 5);

        mint_equipment(user1, 0);

        add_equipment_entry(creator, 
        string::utf8(b"Equipment Name"), 
        string::utf8(b"Equipment Description"),
        string::utf8(b"Equipment uri"),
        equipment_part_id,
        affinity_id,
        grade, 
        100, 10, 11, 12, 50,
        10, 5, 5, 5, 5);

        mint_equipment(user1, 1);

        let user_1_address = signer::address_of(user1);

        let char1 = create_equipment(user1, 0,  
            string::utf8(b"Equipment Name"), 
            string::utf8(b"Equipment Description"),
            string::utf8(b"Equipment uri"),
            equipment_part_id,
            affinity_id,
            grade, level,
            100, 10, 11, 12, 50,
            10, 5, 5, 5, 5);

        assert!(object::is_owner(char1, user_1_address), ENOT_OWNER);


    }

    #[test(creator = @main, user1 = @0x456)]
    #[expected_failure(abort_code=ECHAR_ID_NOT_FOUND)]
    public fun test_mint_unlisted_char(creator: &signer, user1: &signer) acquires CollectionCapability, EquipmentInfo {
        init_module(creator);
        mint_equipment(user1, 1);
    }

    #[test(creator = @main, user1 = @0x456, user2 = @0x789, aptos_framework = @aptos_framework)]
    public fun test_upgrade_equipment(creator: &signer, user1: &signer, user2: &signer, aptos_framework: &signer) acquires CollectionCapability, EquipmentCapability, GameData {
   
        init_module(creator);
        admin::initialize(creator);

        gem::setup_coin(creator, user1, user2, aptos_framework);
        gem::init_module_for_test(creator);
        let equipment_part_id = 1;
        let affinity_id = 1;
        let grade = 1;
        let level = 1;

        let char1 = create_equipment(user1, 0,  
            string::utf8(b"Equipment 1 Name"), 
            string::utf8(b"Equipment 1 Description"),
            string::utf8(b"Equipment uri"),
            equipment_part_id,
            affinity_id,
            grade, level,
            100, 10, 11, 12, 50,
            10, 5, 5, 5, 5);

        let user1_addr = signer::address_of(user1);
        gem::mint_gem(user1, 10);


        let gem_token = object::address_to_object<GemToken>(gem::gem_token_address());
        let gem_balance = gem::gem_balance(user1_addr, gem_token);

        assert!(gem_balance == 10, 0);

        upgrade_equipment(user1, char1, gem_token , 6);

        assert!(gem::gem_balance(user1_addr, gem_token) == 4, EINVALID_BALANCE);

        assert!(property_map::read_u64(&char1, &string::utf8(b"LEVEL"))==7, EINVALID_PROPERTY_VALUE);
        assert!(property_map::read_u64(&char1, &string::utf8(b"GROWTH_HP"))==10, EINVALID_PROPERTY_VALUE);
        assert!(property_map::read_u64(&char1, &string::utf8(b"HP"))==160, EINVALID_PROPERTY_VALUE);
        assert!(property_map::read_u64(&char1, &string::utf8(b"ATK"))==40, EINVALID_PROPERTY_VALUE);
        assert!(property_map::read_u64(&char1, &string::utf8(b"DEF"))==41, EINVALID_PROPERTY_VALUE);
        assert!(property_map::read_u64(&char1, &string::utf8(b"ATK_SPD"))==42, EINVALID_PROPERTY_VALUE);
        assert!(property_map::read_u64(&char1, &string::utf8(b"MV_SPD"))==80, EINVALID_PROPERTY_VALUE);

    }

    #[test(creator = @main, user1 = @0x456, user2 = @0x789, aptos_framework = @aptos_framework)]
    public fun test_upgrade_equipment_multiple(creator: &signer, user1: &signer, user2: &signer, aptos_framework: &signer) acquires CollectionCapability, EquipmentCapability, GameData {
   
        init_module(creator);
        admin::initialize(creator);

        gem::setup_coin(creator, user1, user2, aptos_framework);
        gem::init_module_for_test(creator);
        let equipment_part_id = 1;
        let affinity_id = 1;
        let grade = 1;
        let level = 1;

        let char1 = create_equipment(user1, 0,  
            string::utf8(b"Equipment Name"), 
            string::utf8(b"Equipment 1 Description"),
            string::utf8(b"Equipment uri"),
            equipment_part_id,
            affinity_id,
            grade, level,
            100, 10, 11, 12, 50,
            10, 5, 6, 7, 8);

        let user1_addr = signer::address_of(user1);
        gem::mint_gem(user1, 20);


        let gem_token = object::address_to_object<GemToken>(gem::gem_token_address());

        assert!(gem::gem_balance(user1_addr, gem_token) == 20, 0);

        upgrade_equipment(user1, char1, gem_token , 1);

        assert!(gem::gem_balance(user1_addr, gem_token) == 19, EINVALID_BALANCE);

        assert!(property_map::read_u64(&char1, &string::utf8(b"LEVEL"))==2, EINVALID_PROPERTY_VALUE);
        assert!(property_map::read_u64(&char1, &string::utf8(b"HP"))==110, EINVALID_PROPERTY_VALUE);
        assert!(property_map::read_u64(&char1, &string::utf8(b"ATK"))==15, EINVALID_PROPERTY_VALUE);
        assert!(property_map::read_u64(&char1, &string::utf8(b"DEF"))==17, EINVALID_PROPERTY_VALUE);
        assert!(property_map::read_u64(&char1, &string::utf8(b"ATK_SPD"))==19, EINVALID_PROPERTY_VALUE);
        assert!(property_map::read_u64(&char1, &string::utf8(b"MV_SPD"))==58, EINVALID_PROPERTY_VALUE);

        upgrade_equipment(user1, char1, gem_token , 2);

        assert!(property_map::read_u64(&char1, &string::utf8(b"LEVEL"))==4, EINVALID_PROPERTY_VALUE);
        assert!(property_map::read_u64(&char1, &string::utf8(b"HP"))==130, EINVALID_PROPERTY_VALUE);
        assert!(property_map::read_u64(&char1, &string::utf8(b"ATK"))==25, EINVALID_PROPERTY_VALUE);
        assert!(property_map::read_u64(&char1, &string::utf8(b"DEF"))==29, EINVALID_PROPERTY_VALUE);
        assert!(property_map::read_u64(&char1, &string::utf8(b"ATK_SPD"))==33, EINVALID_PROPERTY_VALUE);
        assert!(property_map::read_u64(&char1, &string::utf8(b"MV_SPD"))==74, EINVALID_PROPERTY_VALUE);

    }


    #[test(creator = @main, user1 = @0x456, user2 = @0x789, aptos_framework = @aptos_framework)]
    #[expected_failure(abort_code=ENOT_OWNER)]
    public fun test_upgrade_equipment_wrong_ownership(creator: &signer, user1: &signer, user2: &signer, aptos_framework: &signer) acquires CollectionCapability, EquipmentCapability, GameData {
   
        init_module(creator);
        admin::initialize(creator);

        gem::setup_coin(creator, user1, user2, aptos_framework);
        gem::init_module_for_test(creator);
        let equipment_part_id = 1;
        let affinity_id = 1;
        let grade = 1;
        let level = 1;

        let char1 = create_equipment(user1, 0,  
            string::utf8(b"Equipment Name"), 
            string::utf8(b"Equipment Description"),
            string::utf8(b"Equipment Uri"),
            equipment_part_id,
            affinity_id,
            grade, level,
            100, 10, 11, 12, 50,
            10, 5, 5, 5, 5);

        gem::mint_gem(user1, 10);

        let gem_token = object::address_to_object<GemToken>(gem::gem_token_address());

        upgrade_equipment(user2, char1, gem_token , 1);

    }

    #[test(creator = @main, user1 = @0x456, user2 = @0x789, aptos_framework = @aptos_framework)]
    public fun test_upgrade_equipment_to_max_level(creator: &signer, user1: &signer, user2: &signer, aptos_framework: &signer) acquires CollectionCapability, EquipmentCapability, GameData {
   
        init_module(creator);
        admin::initialize(creator);

        gem::setup_coin(creator, user1, user2, aptos_framework);
        gem::init_module_for_test(creator);
        let equipment_part_id = 1;
        let affinity_id = 1;
        let grade = 1;
        let level = 1;

        let char1 = create_equipment(user1, 0,  
            string::utf8(b"Equipment Name"), 
            string::utf8(b"Equipment Description"),
            string::utf8(b"Equipment Uri"),
            equipment_part_id,
            affinity_id,
            grade, level,
            100, 10, 11, 12, 50,
            10, 5, 5, 5, 5);

        gem::mint_gem(user1, 100);

        let gem_token = object::address_to_object<GemToken>(gem::gem_token_address());

        upgrade_equipment(user1, char1, gem_token , 49);
    }

    #[test(creator = @main, user1 = @0x456, user2 = @0x789, aptos_framework = @aptos_framework)]
    #[expected_failure(abort_code=EMAX_LEVEL)]
    public fun test_upgrade_equipment_past_max_level(creator: &signer, user1: &signer, user2: &signer, aptos_framework: &signer) acquires CollectionCapability, EquipmentCapability, GameData {
   
        init_module(creator);
        admin::initialize(creator);

        gem::setup_coin(creator, user1, user2, aptos_framework);
        gem::init_module_for_test(creator);
        let equipment_part_id = 1;
        let affinity_id = 1;
        let grade = 1;
        let level = 1;

        let char1 = create_equipment(user1, 0,  
            string::utf8(b"Equipment Name"), 
            string::utf8(b"Equipment Description"),
            string::utf8(b"Equipment Uri"),
            equipment_part_id,
            affinity_id,
            grade, level,
            100, 10, 11, 12, 50,
            10, 5, 5, 5, 5);

        gem::mint_gem(user1, 100);

        let gem_token = object::address_to_object<GemToken>(gem::gem_token_address());

        upgrade_equipment(user1, char1, gem_token , 50);
    }

    #[test(creator = @main, user1 = @0x456, user2 = @0x789, aptos_framework = @aptos_framework)]
    public fun test_upgrade_equipment_change_max_level(creator: &signer, user1: &signer, user2: &signer, aptos_framework: &signer) acquires CollectionCapability, EquipmentCapability, GameData {
   
        init_module(creator);
        admin::initialize(creator);

        gem::setup_coin(creator, user1, user2, aptos_framework);
        gem::init_module_for_test(creator);
        let equipment_part_id = 1;
        let affinity_id = 1;
        let grade = 1;
        let level = 1;

        let char1 = create_equipment(user1, 0,  
            string::utf8(b"Equipment Name"), 
            string::utf8(b"Equipment Description"),
            string::utf8(b"Equipment Uri"),
            equipment_part_id,
            affinity_id,
            grade, level,
            100, 10, 11, 12, 50,
            10, 5, 5, 5, 5);

        let user1_addr = signer::address_of(user1);
        gem::mint_gem(user1, 100);

        let gem_token = object::address_to_object<GemToken>(gem::gem_token_address());
        let _ = gem::gem_balance(user1_addr, gem_token);

        edit_max_weapon_level(creator, 60);
        upgrade_equipment(user1, char1, gem_token , 55);
    }
}