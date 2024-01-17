module main::omni_cache{

    use aptos_std::smart_table::{Self, SmartTable};
    use aptos_std::simple_map::{Self, SimpleMap};

    // use std::error;
    // use std::option;
    use std::signer;
   
    use std::string::{Self, String};
    // use aptos_std::string_utils::{to_string};

    // use main::gem::{Self, GemToken};

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

    struct SpecialEventsInfoEntry has key, store, copy, drop {
        name: String,
        start_time: u64,
        end_time: u64,
        whitelist_map: SimpleMap<address, u64>
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

        let special_events_info_entry = SpecialEventsInfoEntry{
            name: string::utf8(b"First Mint Event"),
            start_time: 0,
            end_time: 0,
            whitelist_map: simple_map::new<address,u64>()
        };
        move_to(account,special_events_info_entry);
    }
    
    public entry fun add_special_event(account:&signer, name: String, start_time:u64, end_time:u64) acquires SpecialEvents, AdminData{
        assert_is_admin(account);

        let special_events_table = &mut borrow_global_mut<SpecialEvents>(@main).special_events_table;
        let table_length = aptos_std::smart_table::length(special_events_table);

        let whitelist_map = simple_map::new<address,u64>();

        let special_events_info_entry = SpecialEventsInfoEntry{
            name,
            start_time,
            end_time,
            whitelist_map: whitelist_map
        };

        smart_table::add(special_events_table, table_length, special_events_info_entry);
    }

    // TODO: Check end_time > start time
    // TODO: start time is greater than current timestamp

    public entry fun modify_special_event_struct(account:&signer, name: String, start_time:u64, end_time:u64) acquires AdminData, SpecialEventsInfoEntry{
        assert_is_admin(account);
        let special_events_info_entry = borrow_global_mut<SpecialEventsInfoEntry>(@main);
        special_events_info_entry.name = name;
        special_events_info_entry.start_time = start_time;
        special_events_info_entry.end_time = end_time;
    }

    public entry fun upsert_whitelist_address(account:&signer, modify_address:address, amount: u64) acquires AdminData, SpecialEventsInfoEntry{
        assert_is_admin(account);
        let special_events_info_entry = borrow_global_mut<SpecialEventsInfoEntry>(@main);
        simple_map::upsert(&mut special_events_info_entry.whitelist_map, modify_address, amount);
    }

    // ISSUES WITH TABLE STUFF
    // public entry fun add_whitelist_addresses(account:&signer, event_id: u64, address_vector:vector<address>, amount_vector: vector<u64>) acquires SpecialEvents, AdminData{
    //     assert_is_admin(account);

    //     let special_events_table = &borrow_global<SpecialEvents>(@main).special_events_table;

    //     assert!(smart_table::contains(special_events_table, event_id),EEVENT_ID_NOT_FOUND);

    //     let special_events_info_entry = get_special_events_info_entry(event_id);        

    //     let whitelist_map = special_events_info_entry.whitelist_map;
     
    //     simple_map::add_all(&mut whitelist_map, address_vector, amount_vector);
    // }

    // public entry fun upsert_whitelist_address(account:&signer, event_id: u64, new_address:address, amount: u64) acquires SpecialEvents, AdminData{
    //     assert_is_admin(account);

    //     let special_events_table = &borrow_global<SpecialEvents>(@main).special_events_table;

    //     assert!(smart_table::contains(special_events_table, event_id),EEVENT_ID_NOT_FOUND);

    //     let special_events_info_entry = get_special_events_info_entry(event_id);        

    //     simple_map::upsert(&mut special_events_info_entry.whitelist_map, new_address, amount);
    // }



    public fun assert_is_admin(account:&signer) acquires AdminData {
        let addr = signer::address_of(account);
        let settings_data = borrow_global<AdminData>(@main);
 
        assert!(addr == settings_data.admin_address, ENOT_ADMIN);
    }

    // ANCHOR View Functions

    // #[view]
    // public fun get_special_events_info_entry(event_id: u64): SpecialEventsInfoEntry acquires SpecialEvents {
    //     let special_events_table = &borrow_global<SpecialEvents>(@main).special_events_table;
    //     *smart_table::borrow(special_events_table, event_id)
    // }

    // #[view]
    // public fun get_special_events_table_length(): u64 acquires SpecialEvents {
    //     let special_events_table = &borrow_global<SpecialEvents>(@main).special_events_table;
    //     aptos_std::smart_table::length(special_events_table)
    // }

    // #[view]
    // public fun get_whitelist_address_amount(event_id:u64, query_address: address): u64 acquires SpecialEvents {
    //     let special_events_info_entry = get_special_events_info_entry(event_id);
    //     *simple_map::borrow(&special_events_info_entry.whitelist_map, &query_address)
    // }

    // #[view]
    // public fun whitelist_map_contains( event_id: u64, query_address: address): bool acquires SpecialEvents{
    //     let special_events_table = &borrow_global<SpecialEvents>(@main).special_events_table;
    //     assert!(smart_table::contains(special_events_table, event_id),EEVENT_ID_NOT_FOUND);     
    //     simple_map::contains_key(&get_special_events_info_entry(event_id).whitelist_map, &query_address)
    // }


    #[view]
    public fun get_special_event_struct_amount(query_address:address):u64 acquires SpecialEventsInfoEntry{
        let special_events_info_entry = borrow_global<SpecialEventsInfoEntry>(@main);
        let whitelist_map = special_events_info_entry.whitelist_map;
        if (simple_map::contains_key(&whitelist_map, &query_address))
        {
            *simple_map::borrow(&whitelist_map, &query_address)
        } else{
            0u64
        }
    }

    // ANCHOR Test Functions
    #[test_only]
    public fun initialize(account: &signer){
        init_module(account);
    }


}