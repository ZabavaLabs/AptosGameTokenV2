module main::equipment_test{

    use aptos_framework::object::{Self};

    use aptos_token_objects::collection;
    use aptos_token_objects::property_map::{Self};

    // use aptos_framework::fungible_asset::{Self, Metadata};
    // use aptos_framework::primary_fungible_store;

    // use std::error;
    use std::option;
    use std::signer::{Self};
    // use std::signer::address_of;
    use std::string::{Self};
    // use aptos_std::string_utils::{to_string};

    use main::eigen_shard::{Self, EigenShardCapability};

    use main::admin::{Self, ENOT_ADMIN};
    use main::equipment::{Self};
    // use std::debug::print;
    // use std::vector;

    const ENOT_OWNER: u64 = 2;
    const ECHAR_ID_NOT_FOUND: u64 = 3;
    const EINVALID_TABLE_LENGTH: u64 = 4;
    const EINVALID_PROPERTY_VALUE: u64 = 5;
    const EINVALID_BALANCE: u64 = 6;
    const EMAX_LEVEL: u64 = 7;
    const EINSUFFICIENT_BALANCE: u64 = 65540;
    
    

    // ANCHOR TESTING

    #[test(creator = @main)]
    public fun test_equipment_addition_to_table(creator: &signer) {
        equipment::initialize_for_test(creator);
        admin::initialize_for_test(creator);
        let equipment_part_id = 1;
        let affinity_id = 1;
        let grade = 1;
        equipment::add_equipment_entry(creator, 
        string::utf8(b"Equipment Name"), 
        string::utf8(b"Equipment Description"),
        string::utf8(b"Equipment uri"),
        equipment_part_id,
        affinity_id,
        grade,
        100, 10, 11, 12, 50,
        10, 5, 5, 5, 5);

        equipment::add_equipment_entry(creator, 
        string::utf8(b"Equipment Name"), 
        string::utf8(b"Equipment Description"),
        string::utf8(b"Equipment uri"),
        equipment_part_id,
        affinity_id,
        grade,
        100, 10, 11, 12, 50,
        10, 5, 5, 5, 5);
        assert!(equipment::get_equipment_table_length()==2, EINVALID_TABLE_LENGTH)
    }

    #[test(creator = @main, user1 = @0x456 )]
    #[expected_failure(abort_code = ENOT_ADMIN, location = main::admin)]
    public fun test_add_equipment_by_others(creator: &signer, user1: &signer) {
        equipment::initialize_for_test(creator);
        admin::initialize_for_test(creator);
        let equipment_part_id = 1;
        let affinity_id = 1;
        let grade = 1;
        equipment::add_equipment_entry(user1, 
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
    public fun test_set_admin(creator: &signer, user1: &signer) {
        equipment::initialize_for_test(creator);
        admin::initialize_for_test(creator);
        let equipment_part_id = 1;
        let affinity_id = 1;
        let grade = 1;
        equipment::add_equipment_entry(creator, 
        string::utf8(b"Equipment Name"), 
        string::utf8(b"Equipment Description"),
        string::utf8(b"Equipment uri"),
        equipment_part_id,
        affinity_id,
        grade,
        100, 10, 11, 12, 50,
        10, 5, 5, 5, 5);
        admin::set_admin(creator, signer::address_of(user1));
        equipment::add_equipment_entry(user1, 
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
    public fun test_set_admin_2(creator: &signer, user1: &signer) {
        equipment::initialize_for_test(creator);
        admin::initialize_for_test(creator);

        let equipment_part_id = 1;
        let affinity_id = 1;
        let grade = 1;
        equipment::add_equipment_entry(creator, 
        string::utf8(b"Equipment Name"), 
        string::utf8(b"Equipment Description"),
        string::utf8(b"Equipment uri"),
        equipment_part_id,
        affinity_id,
        grade,
        100, 10, 11, 12, 50,
        10, 5, 5, 5, 5);
        admin::set_admin(creator, signer::address_of(user1));
        equipment::add_equipment_entry(creator, 
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
    public fun test_mint(creator: &signer, user1: &signer) {
   
        equipment::initialize_for_test(creator);
        admin::initialize_for_test(creator);

        let equipment_part_id = 1;
        let affinity_id = 1;
        let grade = 1;
        let level = 1;
        equipment::add_equipment_entry(creator, 
        string::utf8(b"Equipment Name"), 
        string::utf8(b"Equipment Description"),
        string::utf8(b"Equipment uri"),
        equipment_part_id,
        affinity_id,
        grade,
        100, 10, 11, 12, 50,
        10, 5, 5, 5, 5);

        equipment::mint_equipment_for_test(user1, 0);

        equipment::add_equipment_entry(creator, 
        string::utf8(b"Equipment Name"), 
        string::utf8(b"Equipment Description"),
        string::utf8(b"Equipment uri"),
        equipment_part_id,
        affinity_id,
        grade, 
        100, 10, 11, 12, 50,
        10, 5, 5, 5, 5);

        equipment::mint_equipment_for_test(user1, 1);

        let user_1_address = signer::address_of(user1);

        let char1 = equipment::create_equipment_for_test(user1, 0,  
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
    #[expected_failure(abort_code=ECHAR_ID_NOT_FOUND,location=main::equipment)]
    public fun test_mint_unlisted_char(creator: &signer, user1: &signer)  {
        equipment::initialize_for_test(creator);
        equipment::mint_equipment_for_test(user1, 1);
    }

    #[test(creator = @main, user1 = @0x456, user2 = @0x789, aptos_framework = @aptos_framework)]
    public fun test_upgrade_equipment(creator: &signer, user1: &signer, user2: &signer, aptos_framework: &signer) {
   
        equipment::initialize_for_test(creator);
        admin::initialize_for_test(creator);

        eigen_shard::setup_coin(creator, user1, user2, aptos_framework);
        eigen_shard::initialize_for_test(creator);
        let equipment_part_id = 1;
        let affinity_id = 1;
        let grade = 1;
        let level = 1;

        let char1 = equipment::create_equipment_for_test(user1, 0,  
            string::utf8(b"Equipment 1 Name"), 
            string::utf8(b"Equipment 1 Description"),
            string::utf8(b"Equipment uri"),
            equipment_part_id,
            affinity_id,
            grade, level,
            100, 10, 11, 12, 50,
            10, 5, 5, 5, 5);

        let user1_addr = signer::address_of(user1);
        eigen_shard::mint_shard(user1, 10);


        let shard_token = object::address_to_object<EigenShardCapability>(eigen_shard::shard_token_address());
        let shard_balance = eigen_shard::shard_balance(user1_addr, shard_token);

        assert!(shard_balance == 10, 0);

        equipment::upgrade_equipment(user1, char1, shard_token , 6);

        assert!(eigen_shard::shard_balance(user1_addr, shard_token) == 4, EINVALID_BALANCE);

        assert!(property_map::read_u64(&char1, &string::utf8(b"LEVEL"))==7, EINVALID_PROPERTY_VALUE);
        assert!(property_map::read_u64(&char1, &string::utf8(b"GROWTH_HP"))==10, EINVALID_PROPERTY_VALUE);
        assert!(property_map::read_u64(&char1, &string::utf8(b"HP"))==160, EINVALID_PROPERTY_VALUE);
        assert!(property_map::read_u64(&char1, &string::utf8(b"ATK"))==40, EINVALID_PROPERTY_VALUE);
        assert!(property_map::read_u64(&char1, &string::utf8(b"DEF"))==41, EINVALID_PROPERTY_VALUE);
        assert!(property_map::read_u64(&char1, &string::utf8(b"ATK_SPD"))==42, EINVALID_PROPERTY_VALUE);
        assert!(property_map::read_u64(&char1, &string::utf8(b"MV_SPD"))==80, EINVALID_PROPERTY_VALUE);

    }

    #[test(creator = @main, user1 = @0x456, user2 = @0x789, aptos_framework = @aptos_framework)]
    public fun test_upgrade_equipment_multiple(creator: &signer, user1: &signer, user2: &signer, aptos_framework: &signer) {
   
        equipment::initialize_for_test(creator);
        admin::initialize_for_test(creator);

        eigen_shard::setup_coin(creator, user1, user2, aptos_framework);
        eigen_shard::initialize_for_test(creator);
        let equipment_part_id = 1;
        let affinity_id = 1;
        let grade = 1;
        let level = 1;

        let char1 = equipment::create_equipment_for_test(user1, 0,  
            string::utf8(b"Equipment Name"), 
            string::utf8(b"Equipment 1 Description"),
            string::utf8(b"Equipment uri"),
            equipment_part_id,
            affinity_id,
            grade, level,
            100, 10, 11, 12, 50,
            10, 5, 6, 7, 8);

        let user1_addr = signer::address_of(user1);
        eigen_shard::mint_shard(user1, 20);


        let shard_token = object::address_to_object<EigenShardCapability>(eigen_shard::shard_token_address());

        assert!(eigen_shard::shard_balance(user1_addr, shard_token) == 20, 0);

        equipment::upgrade_equipment(user1, char1, shard_token , 1);

        assert!(eigen_shard::shard_balance(user1_addr, shard_token) == 19, EINVALID_BALANCE);

        assert!(property_map::read_u64(&char1, &string::utf8(b"LEVEL"))==2, EINVALID_PROPERTY_VALUE);
        assert!(property_map::read_u64(&char1, &string::utf8(b"HP"))==110, EINVALID_PROPERTY_VALUE);
        assert!(property_map::read_u64(&char1, &string::utf8(b"ATK"))==15, EINVALID_PROPERTY_VALUE);
        assert!(property_map::read_u64(&char1, &string::utf8(b"DEF"))==17, EINVALID_PROPERTY_VALUE);
        assert!(property_map::read_u64(&char1, &string::utf8(b"ATK_SPD"))==19, EINVALID_PROPERTY_VALUE);
        assert!(property_map::read_u64(&char1, &string::utf8(b"MV_SPD"))==58, EINVALID_PROPERTY_VALUE);

        equipment::upgrade_equipment(user1, char1, shard_token , 2);

        assert!(property_map::read_u64(&char1, &string::utf8(b"LEVEL"))==4, EINVALID_PROPERTY_VALUE);
        assert!(property_map::read_u64(&char1, &string::utf8(b"HP"))==130, EINVALID_PROPERTY_VALUE);
        assert!(property_map::read_u64(&char1, &string::utf8(b"ATK"))==25, EINVALID_PROPERTY_VALUE);
        assert!(property_map::read_u64(&char1, &string::utf8(b"DEF"))==29, EINVALID_PROPERTY_VALUE);
        assert!(property_map::read_u64(&char1, &string::utf8(b"ATK_SPD"))==33, EINVALID_PROPERTY_VALUE);
        assert!(property_map::read_u64(&char1, &string::utf8(b"MV_SPD"))==74, EINVALID_PROPERTY_VALUE);

    }


    #[test(creator = @main, user1 = @0x456, user2 = @0x789, aptos_framework = @aptos_framework)]
    #[expected_failure(abort_code=ENOT_OWNER, location=main::equipment)]
    public fun test_upgrade_equipment_wrong_ownership(creator: &signer, user1: &signer, user2: &signer, aptos_framework: &signer) {
   
        equipment::initialize_for_test(creator);
        admin::initialize_for_test(creator);

        eigen_shard::setup_coin(creator, user1, user2, aptos_framework);
        eigen_shard::initialize_for_test(creator);
        let equipment_part_id = 1;
        let affinity_id = 1;
        let grade = 1;
        let level = 1;

        let char1 = equipment::create_equipment_for_test(user1, 0,  
            string::utf8(b"Equipment Name"), 
            string::utf8(b"Equipment Description"),
            string::utf8(b"Equipment Uri"),
            equipment_part_id,
            affinity_id,
            grade, level,
            100, 10, 11, 12, 50,
            10, 5, 5, 5, 5);

        eigen_shard::mint_shard(user1, 10);

        let shard_token = object::address_to_object<EigenShardCapability>(eigen_shard::shard_token_address());

        equipment::upgrade_equipment(user2, char1, shard_token , 1);

    }

    #[test(creator = @main, user1 = @0x456, user2 = @0x789, aptos_framework = @aptos_framework)]
    public fun test_upgrade_equipment_to_max_level(creator: &signer, user1: &signer, user2: &signer, aptos_framework: &signer)  {
   
        equipment::initialize_for_test(creator);
        admin::initialize_for_test(creator);

        eigen_shard::setup_coin(creator, user1, user2, aptos_framework);
        eigen_shard::initialize_for_test(creator);
        let equipment_part_id = 1;
        let affinity_id = 1;
        let grade = 1;
        let level = 1;

        let char1 = equipment::create_equipment_for_test(user1, 0,  
            string::utf8(b"Equipment Name"), 
            string::utf8(b"Equipment Description"),
            string::utf8(b"Equipment Uri"),
            equipment_part_id,
            affinity_id,
            grade, level,
            100, 10, 11, 12, 50,
            10, 5, 5, 5, 5);

        eigen_shard::mint_shard(user1, 100);

        let shard_token = object::address_to_object<EigenShardCapability>(eigen_shard::shard_token_address());

        equipment::upgrade_equipment(user1, char1, shard_token , 49);
    }

    #[test(creator = @main, user1 = @0x456, user2 = @0x789, aptos_framework = @aptos_framework)]
    #[expected_failure(abort_code=EMAX_LEVEL, location=main::equipment)]
    public fun test_upgrade_equipment_past_max_level(creator: &signer, user1: &signer, user2: &signer, aptos_framework: &signer)  {
   
        equipment::initialize_for_test(creator);
        admin::initialize_for_test(creator);

        eigen_shard::setup_coin(creator, user1, user2, aptos_framework);
        eigen_shard::initialize_for_test(creator);
        let equipment_part_id = 1;
        let affinity_id = 1;
        let grade = 1;
        let level = 1;

        let char1 = equipment::create_equipment_for_test(user1, 0,  
            string::utf8(b"Equipment Name"), 
            string::utf8(b"Equipment Description"),
            string::utf8(b"Equipment Uri"),
            equipment_part_id,
            affinity_id,
            grade, level,
            100, 10, 11, 12, 50,
            10, 5, 5, 5, 5);

        eigen_shard::mint_shard(user1, 100);

        let shard_token = object::address_to_object<EigenShardCapability>(eigen_shard::shard_token_address());

        equipment::upgrade_equipment(user1, char1, shard_token , 50);
    }

    #[test(creator = @main, user1 = @0x456, user2 = @0x789, aptos_framework = @aptos_framework)]
    public fun test_upgrade_equipment_change_max_level(creator: &signer, user1: &signer, user2: &signer, aptos_framework: &signer)  {
   
        equipment::initialize_for_test(creator);
        admin::initialize_for_test(creator);

        eigen_shard::setup_coin(creator, user1, user2, aptos_framework);
        eigen_shard::initialize_for_test(creator);
        let equipment_part_id = 1;
        let affinity_id = 1;
        let grade = 1;
        let level = 1;

        let char1 = equipment::create_equipment_for_test(user1, 0,  
            string::utf8(b"Equipment Name"), 
            string::utf8(b"Equipment Description"),
            string::utf8(b"Equipment Uri"),
            equipment_part_id,
            affinity_id,
            grade, level,
            100, 10, 11, 12, 50,
            10, 5, 5, 5, 5);

        let user1_addr = signer::address_of(user1);
        eigen_shard::mint_shard(user1, 100);

        let shard_token = object::address_to_object<EigenShardCapability>(eigen_shard::shard_token_address());
        let _ = eigen_shard::shard_balance(user1_addr, shard_token);

        equipment::set_max_weapon_level(creator, 60);
        equipment::upgrade_equipment(user1, char1, shard_token , 55);
    }
}