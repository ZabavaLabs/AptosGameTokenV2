 #[test_only]
module main::omni_cache_test{
    // use aptos_framework::account::{Self, SignerCapability};
    use aptos_framework::object;
    // use aptos_std::smart_table::{Self, SmartTable};
    // use aptos_std::simple_map::{Self, SimpleMap};

    use aptos_framework::timestamp;
    use aptos_framework::block;
    use aptos_framework::account;



    // use aptos_token_objects::collection;
    // use aptos_token_objects::token::{Self, Token};
    // use aptos_token_objects::property_map;

    // use std::error;
    // use std::option;
    use std::signer;
   
    use std::string::{Self};
    // use aptos_std::string_utils::{to_string};


    use main::gem::{Self, GemToken};
    use main::omni_cache;
    use main::admin;
    use main::pseudorandom::{Self};
    use main::equipment;

    const EINVALID_TABLE_LENGTH: u64 = 1;
    const EWHITELIST_AMOUNT: u64 = 2;
    const EINVALID_SPECIAL_EVENT_DETAIL: u64 = 3;


    const EEVENT_ID_NOT_FOUND: u64 = 4;


    const EINSUFFICIENT_BALANCE: u64 = 65540;


    #[test(creator = @main)]
    public fun initialize_omni_cache_for_test_2(creator: &signer) {
        admin::initialize(creator);
        omni_cache::initialize(creator);
    }

    #[test(creator = @main, user1 = @0x456, user2 = @0x678, user3= @0x789, aptos_framework = @aptos_framework)]
    public fun test_event_addition_to_table(creator: &signer, user1: &signer, user2:&signer, user3:&signer, aptos_framework: &signer) {
        admin::initialize(creator);
        omni_cache::initialize(creator);
        timestamp::set_time_has_started_for_testing(aptos_framework);
        let timestamp: u64 = timestamp::now_microseconds();

        let event_name = string::utf8(b"First Mint Event");
        let user1_addr = signer::address_of(user1);
        let user2_addr = signer::address_of(user2);
        let user3_addr = signer::address_of(user3);
        let creator_addr = signer::address_of(creator);
        
        
        omni_cache::modify_special_event_struct(creator, event_name, timestamp, timestamp + 100_000_000);
        omni_cache::upsert_whitelist_address(creator, signer::address_of(user1),5);

        assert!(omni_cache::get_special_event_struct_amount(user1_addr)==5, EWHITELIST_AMOUNT);
        omni_cache::upsert_whitelist_address(creator, signer::address_of(user1),10);
        assert!(omni_cache::get_special_event_struct_amount(user1_addr)==10, EWHITELIST_AMOUNT);
       
        let event_name_2 = string::utf8(b"Second Mint Event");
        let new_start_time = timestamp + 200_000_000;
        let new_end_time = timestamp + 300_000_000;

        omni_cache::reset_event_and_add_addresses(creator, event_name_2, 
            new_start_time, new_end_time, 
            vector[user1_addr, user2_addr, user3_addr], vector[1,2,3]);
        assert!(omni_cache::get_special_event_struct_amount(user1_addr)==1, EWHITELIST_AMOUNT);
        assert!(omni_cache::get_special_event_struct_amount(user2_addr)==2, EWHITELIST_AMOUNT);
        assert!(omni_cache::get_special_event_struct_amount(user3_addr)==3, EWHITELIST_AMOUNT);
        assert!(omni_cache::get_special_event_struct_amount(creator_addr)==0, EWHITELIST_AMOUNT);
        let (returned_event_name, returned_start_time, returned_end_time) = omni_cache::get_special_event_struct_details();
        assert!(returned_event_name ==event_name_2, EINVALID_SPECIAL_EVENT_DETAIL);
        assert!(returned_start_time ==new_start_time, EINVALID_SPECIAL_EVENT_DETAIL);
        assert!(returned_end_time ==new_end_time, EINVALID_SPECIAL_EVENT_DETAIL);

        // ISSUES WITH TABLE STUFF
        // omni_cache::add_special_event(creator,string::utf8(b"Event 1"), timestamp, timestamp + 100_000_000);
        // omni_cache::upsert_whitelist_address(creator, 0, signer::address_of(user1), 10);    

        // assert!(omni_cache::get_special_events_table_length()==1, EINVALID_TABLE_LENGTH);
        // assert!(omni_cache::whitelist_map_contains(0, signer::address_of(user1))==true,999);
        // assert!(omni_cache::get_whitelist_address_amount(0, signer::address_of(user1))==10, EWHITELIST_AMOUNT);
       
        // omni_cache::add_special_event(creator,string::utf8(b"Event 2"), 120, 1000);
        // omni_cache::upsert_whitelist_address(creator,1, signer::address_of(user1), 20);
        // assert!(omni_cache::get_special_events_table_length()==2, EINVALID_TABLE_LENGTH);
        // assert!(omni_cache::get_whitelist_address_amount(1, signer::address_of(user1))==20, EWHITELIST_AMOUNT);

    }

    #[test(creator = @main, user1 = @0x456, user2 = @0x678, user3= @0x789, aptos_framework = @aptos_framework)]
    #[expected_failure(abort_code = 65537, location = main::pseudorandom)]
    public fun test_unlock_cache_no_equipment_added(creator: &signer, user1: &signer, user2:&signer, user3:&signer, aptos_framework: &signer) {
        admin::initialize(creator);
        pseudorandom::init(creator);
        gem::setup_coin(creator, user1, user2, aptos_framework);
        gem::init_module_for_test(creator);
        equipment::init_module_for_test(creator);
        omni_cache::initialize(creator);

        account::create_account_for_test(@aptos_framework);
        timestamp::set_time_has_started_for_testing(aptos_framework);
        block::initialize_for_test(aptos_framework, 5);
        
        let _: u64 = timestamp::now_microseconds();
        let _ = string::utf8(b"First Mint Event");
        let _ = signer::address_of(user1);
        let _ = signer::address_of(user2);
        let _ = signer::address_of(user3);
        let _ = signer::address_of(creator);
        
        timestamp::update_global_time_for_test(1000);


        gem::mint_gem(creator,10);
        let gem_token = object::address_to_object<GemToken>(gem::gem_token_address());
        
        omni_cache::unlock_cache(creator, gem_token);
   
    }

    #[test(creator = @main, user1 = @0x456, user2 = @0x678, user3= @0x789, aptos_framework = @aptos_framework)]
    public fun test_unlock_cache(creator: &signer, user1: &signer, user2:&signer, user3:&signer, aptos_framework: &signer) {
        admin::initialize(creator);
        pseudorandom::init(creator);
        gem::setup_coin(creator, user1, user2, aptos_framework);
        gem::init_module_for_test(creator);
        equipment::init_module_for_test(creator);
        omni_cache::initialize(creator);

        account::create_account_for_test(@aptos_framework);
        timestamp::set_time_has_started_for_testing(aptos_framework);
        block::initialize_for_test(aptos_framework, 5);
        
        let _: u64 = timestamp::now_microseconds();
        let user1_addr = signer::address_of(user1);
        let _ = signer::address_of(user2);
        let _ = signer::address_of(user3);
        let _ = signer::address_of(creator);
        
        timestamp::update_global_time_for_test(1000);


        gem::mint_gem(user1,30);
        let gem_token = object::address_to_object<GemToken>(gem::gem_token_address());
        
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
        string::utf8(b"Equipment 2"), 
        string::utf8(b"Equipment Description 2"),
        string::utf8(b"Equipment uri 2"),
        equipment_part_id,
        affinity_id,
        grade,
        120, 10, 11, 12, 50,
        10, 5, 5, 5, 5);

        equipment::add_equipment_entry(creator, 
        string::utf8(b"Equipment 3"), 
        string::utf8(b"Equipment Description 3"),
        string::utf8(b"Equipment uri 3"),
        equipment_part_id,
        affinity_id,
        grade,
        130, 10, 11, 12, 50,
        10, 5, 5, 5, 5);

        omni_cache::add_equipment_to_cache(creator, 0, 0);
        omni_cache::add_equipment_to_cache(creator, 0, 1);
        omni_cache::add_equipment_to_cache(creator, 0, 2);

        omni_cache::unlock_cache(user1, gem_token);
        omni_cache::unlock_cache(user1, gem_token);
        omni_cache::unlock_cache(user1, gem_token);

        assert!(gem::gem_balance(user1_addr, gem_token) == 0, 0);

    }

    #[test(creator = @main, user1 = @0x456, user2 = @0x678, user3= @0x789, aptos_framework = @aptos_framework)]
    #[expected_failure(abort_code = 8, location = main::gem)]
    public fun test_unlock_cache_insufficient_gem(creator: &signer, user1: &signer, user2:&signer, user3:&signer, aptos_framework: &signer) {
        admin::initialize(creator);
        pseudorandom::init(creator);
        gem::setup_coin(creator, user1, user2, aptos_framework);
        gem::init_module_for_test(creator);
        equipment::init_module_for_test(creator);
        omni_cache::initialize(creator);

        account::create_account_for_test(@aptos_framework);
        timestamp::set_time_has_started_for_testing(aptos_framework);
        block::initialize_for_test(aptos_framework, 5);
        
        let _: u64 = timestamp::now_microseconds();
        let _ = string::utf8(b"First Mint Event");
        let _ = signer::address_of(user1);
        let _ = signer::address_of(user2);
        let _ = signer::address_of(user3);
        let _ = signer::address_of(creator);
        
        timestamp::update_global_time_for_test(1000);


        gem::mint_gem(user1,5);
        let gem_token = object::address_to_object<GemToken>(gem::gem_token_address());
        
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

        omni_cache::add_equipment_to_cache(creator, 0, 0);
        omni_cache::unlock_cache(user1, gem_token);
    }

    #[test(creator = @main, user1 = @0x456, user2 = @0x678, user3= @0x789, aptos_framework = @aptos_framework)]
    public fun test_unlock_cache_via_event(creator: &signer, user1: &signer, user2:&signer, user3:&signer, aptos_framework: &signer) {
        admin::initialize(creator);
        pseudorandom::init(creator);
        gem::setup_coin(creator, user1, user2, aptos_framework);
        gem::init_module_for_test(creator);
        equipment::init_module_for_test(creator);
        omni_cache::initialize(creator);

        account::create_account_for_test(@aptos_framework);
        timestamp::set_time_has_started_for_testing(aptos_framework);
        block::initialize_for_test(aptos_framework, 5);
        
        let _: u64 = timestamp::now_microseconds();
        let _ = string::utf8(b"First Mint Event");
        let user1_addr = signer::address_of(user1);
        let _ = signer::address_of(user2);
        let _ = signer::address_of(user3);
        let _ = signer::address_of(creator);
        
        timestamp::update_global_time_for_test(1000);

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

        omni_cache::add_equipment_to_cache(creator, 0, 0);

        omni_cache::upsert_whitelist_address(creator, user1_addr, 2);
        omni_cache::modify_special_event_struct(creator, string::utf8(b"Mint Event"),0,10000 );
        omni_cache::unlock_cache_via_event(user1);
        omni_cache::unlock_cache_via_event(user1);


    }

    #[test(creator = @main, user1 = @0x456, user2 = @0x678, user3= @0x789, aptos_framework = @aptos_framework)]
    #[expected_failure(abort_code=6, location=main::omni_cache)]
    public fun test_unlock_extra_cache_via_event(creator: &signer, user1: &signer, user2:&signer, user3:&signer, aptos_framework: &signer) {
        admin::initialize(creator);
        pseudorandom::init(creator);
        gem::setup_coin(creator, user1, user2, aptos_framework);
        gem::init_module_for_test(creator);
        equipment::init_module_for_test(creator);
        omni_cache::initialize(creator);

        account::create_account_for_test(@aptos_framework);
        timestamp::set_time_has_started_for_testing(aptos_framework);
        block::initialize_for_test(aptos_framework, 5);
        
        let _: u64 = timestamp::now_microseconds();
        let _ = string::utf8(b"First Mint Event");
        let user1_addr = signer::address_of(user1);
        let _ = signer::address_of(user2);
        let _ = signer::address_of(user3);
        let _ = signer::address_of(creator);
        
        timestamp::update_global_time_for_test(1000);

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

        omni_cache::add_equipment_to_cache(creator, 0, 0);

        omni_cache::upsert_whitelist_address(creator, user1_addr, 2);
        omni_cache::modify_special_event_struct(creator, string::utf8(b"Mint Event"),0,10000 );
        omni_cache::unlock_cache_via_event(user1);
        omni_cache::unlock_cache_via_event(user1);
        omni_cache::unlock_cache_via_event(user1);
    }

    #[test(creator = @main, user1 = @0x456, user2 = @0x678, user3= @0x789, aptos_framework = @aptos_framework)]
    #[expected_failure(abort_code=8, location=main::omni_cache)]
    public fun test_unlock_cache_via_event_past_time(creator: &signer, user1: &signer, user2:&signer, user3:&signer, aptos_framework: &signer) {
        admin::initialize(creator);
        pseudorandom::init(creator);
        gem::setup_coin(creator, user1, user2, aptos_framework);
        gem::init_module_for_test(creator);
        equipment::init_module_for_test(creator);
        omni_cache::initialize(creator);

        account::create_account_for_test(@aptos_framework);
        timestamp::set_time_has_started_for_testing(aptos_framework);
        block::initialize_for_test(aptos_framework, 5);
        
        let _: u64 = timestamp::now_microseconds();
        let _ = string::utf8(b"First Mint Event");
        let user1_addr = signer::address_of(user1);
        let _ = signer::address_of(user2);
        let _ = signer::address_of(user3);
        let _ = signer::address_of(creator);
        
        timestamp::update_global_time_for_test(1000);

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

        omni_cache::add_equipment_to_cache(creator, 0, 0);

        omni_cache::upsert_whitelist_address(creator, user1_addr, 2);
        omni_cache::modify_special_event_struct(creator, string::utf8(b"Mint Event"),0,500 );
        omni_cache::unlock_cache_via_event(user1);

    }
}