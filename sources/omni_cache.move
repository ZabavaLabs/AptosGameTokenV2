module main::omni_cache{

    use aptos_framework::account::{Self, SignerCapability};
    use aptos_framework::object::{Self, Object};
    use aptos_std::smart_table::{Self, SmartTable};
    use aptos_std::simple_map::{Self, SimpleMap};


    use aptos_token_objects::collection;
    use aptos_token_objects::token::{Self, Token};
    use aptos_token_objects::property_map;
    use aptos_framework::timestamp;



    use std::error;
    use std::option;
    use std::signer;
   
    use std::string::{Self, String};
    use aptos_std::string_utils::{to_string};

    use main::gem::{Self, GemToken};

    // friend main::omni_cache_test;

    const ENOT_ADMIN: u64 = 1;
    const ENOT_OWNER: u64 = 2;
    const EEVENT_ID_NOT_FOUND: u64 = 3;
    const EINVALID_TABLE_LENGTH: u64 = 4;
    const EINVALID_PROPERTY_VALUE: u64 = 5;
    const EINVALID_BALANCE: u64 = 6;
    const EMAX_LEVEL: u64 = 7;
    const EINSUFFICIENT_BALANCE: u64 = 65540;
    

    struct AdminData has key {
        admin_address: address
    }

    struct SpecialEventsInfoEntry has store, copy, drop {
        name: String,
        start_time: u64,
        end_time: u64,
        whitelist_data: SimpleMap<address, u64>

    }

    struct SpecialEvents has key {
        special_events_table: SmartTable<u64, SpecialEventsInfoEntry>
    }

  
    fun init_module(account: &signer){
        let special_events_table = aptos_std::smart_table::new();
        let special_events = SpecialEvents{
            special_events_table: special_events_table
        };
        move_to(account, special_events);

        let admin_data = AdminData{
            admin_address: signer::address_of(account)
        };
        move_to(account, admin_data);
    }

    #[test_only]
    public fun initialize(account: &signer){
        init_module(account);
    }
    
    public entry fun add_special_event(account:&signer, name: String, start_time:u64, end_time:u64) acquires SpecialEvents, AdminData{
        assert_is_admin(account);

        let special_events_table = &mut borrow_global_mut<SpecialEvents>(@main).special_events_table;
        let table_length = aptos_std::smart_table::length(special_events_table);

        let whitelist_data = simple_map::create<address,u64>();

        let special_events_info_entry = SpecialEventsInfoEntry{
            name,
            start_time,
            end_time,
            whitelist_data
        };

        smart_table::add(special_events_table, table_length, special_events_info_entry);
    }

    public entry fun add_whitelist_addresses(account:&signer, event_id: u64, address_vector:vector<address>, amount_vector: vector<u64>) acquires SpecialEvents, AdminData{
        assert_is_admin(account);

        let special_events_table = &borrow_global<SpecialEvents>(@main).special_events_table;

        assert!(smart_table::contains(special_events_table, event_id),EEVENT_ID_NOT_FOUND);

        let special_events_info_entry = get_special_events_info_entry(event_id);        

        let whitelist_data = special_events_info_entry.whitelist_data;
     
        simple_map::add_all(&mut whitelist_data, address_vector, amount_vector);
    }

    public entry fun upsert_whitelist_address(account:&signer, event_id: u64, new_address:address, amount: u64) acquires SpecialEvents, AdminData{
        assert_is_admin(account);

        let special_events_table = &borrow_global<SpecialEvents>(@main).special_events_table;

        assert!(smart_table::contains(special_events_table, event_id),EEVENT_ID_NOT_FOUND);

        let special_events_info_entry = get_special_events_info_entry(event_id);        

        let whitelist_data = special_events_info_entry.whitelist_data;
     
        simple_map::upsert(&mut whitelist_data, new_address, amount);
    }

    public fun assert_is_admin(account:&signer) acquires AdminData {
        let addr = signer::address_of(account);
        let settings_data = borrow_global<AdminData>(@main);
 
        assert!(addr == settings_data.admin_address, ENOT_ADMIN);
    }


    #[view]
    public fun get_special_events_info_entry(event_id: u64): SpecialEventsInfoEntry acquires SpecialEvents {
        let special_events_table = &borrow_global<SpecialEvents>(@main).special_events_table;
        *smart_table::borrow(special_events_table, event_id)
    }

    #[view]
    public fun get_special_events_table_length(): u64 acquires SpecialEvents {
        let special_events_table = &borrow_global<SpecialEvents>(@main).special_events_table;
        aptos_std::smart_table::length(special_events_table)
    }

    #[test(creator = @main)]
    public fun initialize_omni_cache_for_test(creator: &signer) {
        initialize(creator);
    }

    #[test(creator = @main, user1 = @0x456, aptos_framework = @aptos_framework)]
    public fun test_event_addition_to_table(creator: &signer, user1: &signer, aptos_framework: &signer) acquires AdminData, SpecialEvents {
        initialize(creator);
        timestamp::set_time_has_started_for_testing(aptos_framework);
        let timestamp: u64 = timestamp::now_microseconds();

        add_special_event(creator,string::utf8(b"Equipment Name"), 100, 1000);

        upsert_whitelist_address(creator,0, signer::address_of(user1), 10);
        
        // assert!(get_equipment_table_length()==2, EINVALID_TABLE_LENGTH)
    }


}