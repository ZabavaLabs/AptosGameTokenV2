 #[test_only]
module main::omni_cache_test{
    // use aptos_framework::account::{Self, SignerCapability};
    // use aptos_framework::object::{Self, Object};
    // use aptos_std::smart_table::{Self, SmartTable};
    // use aptos_std::simple_map::{Self, SimpleMap};

    use aptos_framework::timestamp;

    // use aptos_token_objects::collection;
    // use aptos_token_objects::token::{Self, Token};
    // use aptos_token_objects::property_map;

    // use std::error;
    // use std::option;
    use std::signer;
   
    use std::string::{Self};
    // use aptos_std::string_utils::{to_string};

    // use main::gem::{Self, GemToken};
    use main::omni_cache;

    const EINVALID_TABLE_LENGTH: u64 = 1;
    const EWHITELIST_AMOUNT: u64 = 2;
    const EINVALID_SPECIAL_EVENT_DETAIL: u64 = 3;


    const EEVENT_ID_NOT_FOUND: u64 = 4;


    const EINSUFFICIENT_BALANCE: u64 = 65540;


    #[test(creator = @main)]
    public fun initialize_omni_cache_for_test_2(creator: &signer) {
        omni_cache::initialize(creator);
    }

    #[test(creator = @main, user1 = @0x456, user2 = @0x678, user3= @0x789, aptos_framework = @aptos_framework)]
    public fun test_event_addition_to_table(creator: &signer, user1: &signer, user2:&signer, user3:&signer, aptos_framework: &signer) {

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
}