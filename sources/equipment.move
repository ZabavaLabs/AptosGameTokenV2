module main::equipment{

    use aptos_framework::account::{Self, SignerCapability};
    use aptos_framework::object::{Self, Object};
    use aptos_std::smart_table::{Self, SmartTable};

    use aptos_token_objects::collection;
    use aptos_token_objects::token::{Self, Token};
    use aptos_token_objects::royalty::{Self, Royalty};
    use aptos_token_objects::property_map;

    // use aptos_framework::fungible_asset::{Self, Metadata};
    // use aptos_framework::primary_fungible_store;

    // use std::error;
    use std::option;
    use std::signer;
    // use std::signer::address_of;
    use std::string::{Self, String};
    // use aptos_std::string_utils::{to_string};

    use main::eigen_shard::{Self, EigenShardCapability};

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
    // friend equipment_test;

    #[resource_group_member(group = aptos_framework::object::ObjectGroup)]
    struct EquipmentData has key {
        max_equipment_level: u64
    }

    #[resource_group_member(group = aptos_framework::object::ObjectGroup)]
    struct EquipmentCapability has key {
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

    #[resource_group_member(group = aptos_framework::object::ObjectGroup)]
    struct EquipmentInfo has key {
        table: SmartTable<u64, EquipmentInfoEntry>
    }

    // Tokens require a signer to create, so this is the signer for the collection
    #[resource_group_member(group = aptos_framework::object::ObjectGroup)]
    struct ResourceCapability has key, drop {
        capability: SignerCapability,
        burn_signer_capability: SignerCapability,
    }

    #[resource_group_member(group = aptos_framework::object::ObjectGroup)]
    struct EquipmentCollectionCapability has key {
        collection_mutator_ref: collection::MutatorRef
    }


    const APP_SIGNER_CAPABILITY_SEED: vector<u8> = b"APP_SIGNER_CAPABILITY";
    const BURN_SIGNER_CAPABILITY_SEED: vector<u8> = b"BURN_SIGNER_CAPABILITY";
    const UC_EQUIPMENT_COLLECTION_NAME: vector<u8> = b"Undying City Equipment Collection";
    const UC_EQUIPMENT_COLLECTION_DESCRIPTION: vector<u8> = b"Contains all the Undying City equipment";
    
    const ROYALTY_ADDRESS: address = @main;

    // TODO: Change the equipment collection uri
    const UC_EQUIPMENT_COLLECTION_URI: vector<u8> = b"ipfs://bafybeieg74qule3esf7s4svutbkoryoo35asgqauirkglf4xokhvyffymu";
   
    fun init_module(account: &signer) {
        let (signer_resource, token_signer_cap) = account::create_resource_account(
            account,
            APP_SIGNER_CAPABILITY_SEED,
        );
        let (_, burn_signer_capability) = account::create_resource_account(
            account,
            BURN_SIGNER_CAPABILITY_SEED,
        );

        let description = string::utf8(UC_EQUIPMENT_COLLECTION_DESCRIPTION);
        let name = string::utf8(UC_EQUIPMENT_COLLECTION_NAME);
        let uri = string::utf8(UC_EQUIPMENT_COLLECTION_URI);

        let collection_signer = create_equipment_collection(&signer_resource, description, name, uri);
        
        move_to(&collection_signer, ResourceCapability {
            capability: token_signer_cap,
            burn_signer_capability,
        });

        
        let equipment_info_table = aptos_std::smart_table::new();

        let equipment_info = EquipmentInfo{
            table: equipment_info_table
        };
        move_to(&collection_signer, equipment_info);

        let gameData =  EquipmentData{
            max_equipment_level: 50
        };

        move_to(&collection_signer, gameData);
    }

    public entry fun set_max_weapon_level(caller: &signer, new_max_level: u64) acquires  EquipmentData {
        let caller_address = signer::address_of(caller);
        admin::assert_is_admin(caller_address);
        let game_data = borrow_global_mut< EquipmentData>(equipment_collection_address());
        game_data.max_equipment_level = new_max_level;
    }

    fun get_token_signer(): signer acquires ResourceCapability {
        account::create_signer_with_capability(&borrow_global<ResourceCapability>(equipment_collection_address()).capability)
    }

    fun create_equipment_collection(signer_resource: &signer, description: String, name: String, uri: String): signer {
        let expected_royalty = royalty::create(5_000, 100_000, ROYALTY_ADDRESS);
        let collection_constructor_ref = collection::create_unlimited_collection(
            signer_resource,
            description,
            name,
            option::some(expected_royalty),
            uri,
        );
        let object_signer = object::generate_signer(&collection_constructor_ref);
        let collection_mutator_ref = collection::generate_mutator_ref(&collection_constructor_ref);

        let collection_capability = EquipmentCollectionCapability{
            collection_mutator_ref
        };

        move_to(&object_signer, collection_capability);
        object_signer
    }

    public(friend) fun mint_equipment(user: &signer, equipment_id: u64) acquires ResourceCapability, EquipmentInfo {
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
    ): Object<EquipmentCapability> acquires ResourceCapability {

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
   
    public entry fun upgrade_equipment(from: &signer, equipment_object: Object<EquipmentCapability>, shard_object: Object<EigenShardCapability>, amount: u64) acquires EquipmentCapability,  EquipmentData {
        assert!(object::is_owner(equipment_object, signer::address_of(from)), ENOT_OWNER);
        eigen_shard::burn_shard(from, shard_object, amount);
        let equipment_token_address = object::object_address(&equipment_object);
        let equipment = borrow_global_mut<EquipmentCapability>(equipment_token_address);
        // Gets `property_mutator_ref` to update the attack point in the property map.
        let property_mutator_ref = &equipment.property_mutator_ref;
        // Updates the attack point in the property map.
        let current_lvl = property_map::read_u64(&equipment_object, &string::utf8(b"LEVEL"));

        // Prevents upgrading beyond a certain level.
        let game_data = borrow_global< EquipmentData>(equipment_collection_address());
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

    public entry fun set_collection_uri(caller: &signer, new_uri: String) acquires EquipmentCollectionCapability{
        let caller_address = signer::address_of(caller);
        admin::assert_is_admin(caller_address);
        let collection_capability = borrow_global<EquipmentCollectionCapability>(equipment_collection_address());
        collection::set_uri(&collection_capability.collection_mutator_ref, new_uri);
    }

    public entry fun set_collection_description(caller: &signer, new_description: String) acquires EquipmentCollectionCapability{
        let caller_address = signer::address_of(caller);
        admin::assert_is_admin(caller_address);
        let collection_capability = borrow_global<EquipmentCollectionCapability>(equipment_collection_address());
        collection::set_description(&collection_capability.collection_mutator_ref, new_description);
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

        let equipment_info_table = &mut borrow_global_mut<EquipmentInfo>(equipment_collection_address()).table;
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
        let equipment_info_table = &borrow_global<EquipmentInfo>(equipment_collection_address()).table;
        smart_table::contains(equipment_info_table, equipment_id)
    }

    // ANCHOR Aptos View Functions
    #[view]
    public fun capability_address(): address {
        account::create_resource_address(&@main, APP_SIGNER_CAPABILITY_SEED)
    }

    #[view]
    public fun equipment_collection_address(): address {
        // collection_create(&capability_address(), UC_EQUIPMENT_COLLECTION_NAME)
        collection::create_collection_address(&capability_address(), &string::utf8(UC_EQUIPMENT_COLLECTION_NAME))
    
    }

    #[view]
    public fun get_equipment_info_entry(equipment_id: u64): EquipmentInfoEntry acquires EquipmentInfo {
        let equipment_info_table = &borrow_global<EquipmentInfo>(equipment_collection_address()).table;
        *smart_table::borrow(equipment_info_table, equipment_id)
    }

    #[view]
    public fun get_equipment_table_length(): u64 acquires EquipmentInfo {
        let equipment_info_table = &borrow_global<EquipmentInfo>(equipment_collection_address()).table;
        aptos_std::smart_table::length(equipment_info_table)
    } 


    // ANCHOR TESTING

   
    // TODO: Viewing Function of properties of object
    // TODO: Test if properties of minted equipment is the same as that stored in table.
    #[test_only]
    public fun initialize_for_test(creator: &signer) {
        init_module(creator);
    }

    #[test_only]
    public fun create_equipment_for_test(
        user: &signer, 
        equipment_id: u64, token_name: String, 
        token_description: String, token_uri: String, 
        equipment_part_id: u64, affinity_id: u64,
        grade: u64, level:u64,
        hp: u64, atk: u64, def: u64,
        atk_spd: u64, mv_spd: u64,
        growth_hp: u64, growth_atk: u64, growth_def: u64,
        growth_atk_spd: u64, growth_mv_spd: u64
    ): Object<EquipmentCapability> acquires ResourceCapability{
        create_equipment(
        user, 
        equipment_id, token_name,
        token_description, token_uri, 
        equipment_part_id, affinity_id,
        grade, level,
        hp, atk, def,
        atk_spd, mv_spd,
        growth_hp, growth_atk, growth_def,
        growth_atk_spd, growth_mv_spd)
    }
 
    #[test_only]
    public fun mint_equipment_for_test(user: &signer, equipment_id: u64) acquires ResourceCapability, EquipmentInfo {
        mint_equipment(user,equipment_id);
    }

}