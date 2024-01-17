 #[test_only]
module main::omni_cache_test{
    use aptos_framework::account::{Self, SignerCapability};
    use aptos_framework::object::{Self, Object};
    use aptos_std::smart_table::{Self, SmartTable};
    use aptos_std::simple_map::{Self, SimpleMap};

    use aptos_framework::timestamp;

    use aptos_token_objects::collection;
    use aptos_token_objects::token::{Self, Token};
    use aptos_token_objects::property_map;

    use std::error;
    use std::option;
    use std::signer;
   
    use std::string::{Self, String};
    use aptos_std::string_utils::{to_string};

    use main::gem::{Self, GemToken};
    use main::omni_cache::{Self, AdminData};

    const ENOT_ADMIN: u64 = 1;
    const ENOT_OWNER: u64 = 2;
    const EEVENT_ID_NOT_FOUND: u64 = 3;
    const EINVALID_TABLE_LENGTH: u64 = 4;
    const EINVALID_PROPERTY_VALUE: u64 = 5;
    const EINVALID_BALANCE: u64 = 6;
    const EMAX_LEVEL: u64 = 7;
    const EINSUFFICIENT_BALANCE: u64 = 65540;


    #[test(creator = @main)]
    public fun initialize_omni_cache_for_test_2(creator: &signer) {
        omni_cache::initialize(creator);
    }

    #[test(creator = @main, user1 = @0x456, aptos_framework = @aptos_framework)]

    public fun test_event_addition_to_table_2(creator: &signer, user1: &signer, aptos_framework: &signer) {

        omni_cache::initialize(creator);
        timestamp::set_time_has_started_for_testing(aptos_framework);
        let timestamp: u64 = timestamp::now_microseconds();

        omni_cache::add_special_event(creator,string::utf8(b"Equipment Name"), 100, 1000);

        omni_cache::upsert_whitelist_address(creator,0, signer::address_of(user1), 10);
        
        // assert!(get_equipment_table_length()==2, EINVALID_TABLE_LENGTH)
    }
}