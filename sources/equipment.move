module main::equipment{

    use aptos_framework::account::{Self, SignerCapability};
    use aptos_framework::object::{Self, Object};
    use aptos_std::smart_table::{Self, SmartTable};

    // use aptos_framework::timestamp;
    use aptos_token_objects::collection;
    use aptos_token_objects::token::{Self, Token};
    use aptos_token_objects::property_map;

    use aptos_framework::fungible_asset::{Self, Metadata};
    use aptos_framework::primary_fungible_store;

    use std::error;
    use std::option;
    use std::signer;
    // use std::signer::address_of;
    use std::string::{Self, String};
    use aptos_std::string_utils::{to_string};

    use main::gem::{Self, GemToken};

    // use std::debug::print;
    // use std::vector;

    const ENOT_ADMIN: u64 = 1;
    const ENOT_OWNER: u64 = 2;
    const ECHAR_ID_NOT_FOUND: u64 = 3;
    const EINVALID_TABLE_LENGTH: u64 = 4;
    const EINVALID_PROPERTY_VALUE: u64 = 5;
    const EINVALID_BALANCE: u64 = 6;
    const EINSUFFICIENT_BALANCE: u64 = 65540;
    

    struct AdminData has key {
        admin_address: address
    }


    struct Equipment has key {
        name: String,
        description: String,
        uri: String,
        equipment_id: u64,
        equipment_part_id: u64,
        affinity_id: u64,
        grade:u64,
        level: u64,
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


        let table_length = aptos_std::smart_table::length(&equipment_info_table);

        // smart_table::add(&mut equipment_info_table, table_length, equipment_stats);
        let equipment_info = EquipmentInfo{
            table: equipment_info_table
        };
        move_to(account, equipment_info);

        let settings = AdminData{
            admin_address: signer::address_of(account)
        };

        move_to(account, settings);
    }

    public entry fun edit_admin(caller: &signer, new_admin_addr: address) acquires AdminData {
        let caller_address = signer::address_of(caller);
        assert_is_admin(caller_address);
        let settings_data = borrow_global_mut<AdminData>(@main);
        settings_data.admin_address = new_admin_addr;
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

    public entry fun mint_equipment(user: &signer, equipment_id: u64) acquires CollectionCapability, EquipmentInfo {
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
    ): Object<Equipment> acquires CollectionCapability {

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
            hp
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

        let new_equipment = Equipment {
            name: token_name,
            description: token_description,
            uri: token_uri,
            equipment_id,
            equipment_part_id,
            affinity_id,
            grade,
            level,
            hp: hp,
            atk: atk,
            def: def,
            atk_spd: atk_spd,
            mv_spd: mv_spd,
            growth_hp,
            growth_atk,
            growth_def,
            growth_atk_spd,
            growth_mv_spd,
            mutator_ref,
            burn_ref,
            property_mutator_ref
        };

        move_to(&token_signer, new_equipment);
        let created_token = object::object_from_constructor_ref<Token>(&constructor_ref);
        object::transfer(&get_token_signer() , created_token, signer::address_of(user));
        object::address_to_object(signer::address_of(&token_signer))
    }

    entry fun upgrade_equipment(from: &signer, equipment_object: Object<Equipment>, gem_object: Object<GemToken>, amount: u64) acquires Equipment {
        assert!(object::is_owner(equipment_object, signer::address_of(from)), ENOT_OWNER);
        gem::burn_gem(from, gem_object, amount);
        let equipment_token_address = object::object_address(&equipment_object);
        let equipment = borrow_global_mut<Equipment>(equipment_token_address);
        // Gets `property_mutator_ref` to update the attack point in the property map.
        let property_mutator_ref = &equipment.property_mutator_ref;
        // Updates the attack point in the property map.
        let current_atk = property_map::read_u64(&equipment_object, &string::utf8(b"ATK"));
        property_map::update_typed(property_mutator_ref, &string::utf8(b"ATK"), current_atk + (5 * amount));

    }
    
    // ANCHOR Aptos Utility Functions

    public(friend) entry fun add_equipment_entry(
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
        ) acquires EquipmentInfo, AdminData {

        assert_is_admin(signer::address_of(account));

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

    fun assert_is_admin(addr: address) acquires AdminData {
        let settings_data = borrow_global<AdminData>(@main);
        assert!(addr == settings_data.admin_address, ENOT_ADMIN);
        // assert!(addr == main::admin::get_admin_address(), ENOT_ADMIN);
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
    public fun test_equipment_addition_to_table(creator: &signer) acquires EquipmentInfo, AdminData {
        init_module(creator);
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
    #[expected_failure(abort_code = ENOT_ADMIN)]
    public fun test_add_equipment_by_others(creator: &signer, user1: &signer) acquires EquipmentInfo, AdminData {
        init_module(creator);
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
    public fun test_edit_admin(creator: &signer, user1: &signer) acquires EquipmentInfo, AdminData {
        init_module(creator);
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
        edit_admin(creator, signer::address_of(user1));
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
    public fun test_edit_admin_2(creator: &signer, user1: &signer) acquires EquipmentInfo, AdminData {
        init_module(creator);
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
        edit_admin(creator, signer::address_of(user1));
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
    public fun test_mint(creator: &signer, user1: &signer) acquires CollectionCapability, EquipmentInfo, AdminData {
   
        init_module(creator);

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

    #[test(creator = @main, user1 = @0x456)]
    public fun test_upgrade_equipment(creator: &signer, user1: &signer) acquires CollectionCapability, Equipment {
   
        init_module(creator);
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

        assert!(gem::gem_balance(user1_addr, gem_token) == 10, 0);

        upgrade_equipment(user1, char1, gem_token , 6);

        assert!(gem::gem_balance(user1_addr, gem_token) == 4, EINVALID_BALANCE);

        assert!(property_map::read_u64(&char1, &string::utf8(b"ATK"))==40, EINVALID_PROPERTY_VALUE);

    }

        #[test(creator = @main, user1 = @0x456)]
    public fun test_upgrade_equipment_multiple(creator: &signer, user1: &signer) acquires CollectionCapability, Equipment {
   
        init_module(creator);
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
            10, 5, 5, 5, 5);

        let user1_addr = signer::address_of(user1);
        gem::mint_gem(user1, 20);


        let gem_token = object::address_to_object<GemToken>(gem::gem_token_address());
        let gem_balance = gem::gem_balance(user1_addr, gem_token);

        assert!(gem::gem_balance(user1_addr, gem_token) == 20, 0);

        upgrade_equipment(user1, char1, gem_token , 6);

        assert!(gem::gem_balance(user1_addr, gem_token) == 14, EINVALID_BALANCE);

        assert!(property_map::read_u64(&char1, &string::utf8(b"ATK"))==40, EINVALID_PROPERTY_VALUE);

        upgrade_equipment(user1, char1, gem_token , 5);
        assert!(property_map::read_u64(&char1, &string::utf8(b"ATK"))==65, EINVALID_PROPERTY_VALUE);


    }


    #[test(creator = @main, user1 = @0x456, user2 = @0x789)]
    #[expected_failure(abort_code=ENOT_OWNER)]
    public fun test_upgrade_equipment_wrong_ownership(creator: &signer, user1: &signer, user2: &signer) acquires CollectionCapability, Equipment {
   
        init_module(creator);
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
        gem::mint_gem(user1, 10);

        let gem_token = object::address_to_object<GemToken>(gem::gem_token_address());
        let gem_balance = gem::gem_balance(user1_addr, gem_token);

        upgrade_equipment(user2, char1, gem_token , 1);

    }
}