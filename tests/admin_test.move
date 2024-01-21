 #[test_only]
module main::game_test{
    // use aptos_framework::account::{Self, SignerCapability};
    // use aptos_framework::object::{Self, Object};
    // use aptos_std::smart_table::{Self, SmartTable};

  
    // use aptos_token_objects::collection;
    // use aptos_token_objects::token::{Self, Token};
    // use aptos_token_objects::property_map;

    // use std::option;
    use std::signer;
 
    // use std::string::{Self};
    // use aptos_std::string_utils::{to_string};

    use main::admin;

    const ENOT_ADMIN: u64 = 1;


    #[test(creator = @main, user1 = @0x456 )]
    public fun test_edit_admin_999(creator: &signer, user1: &signer)  {
        admin::initialize_for_test(creator);
        assert!(signer::address_of(creator)==admin::get_admin_address(),ENOT_ADMIN);
        admin::edit_admin(creator, signer::address_of(user1));
        assert!(signer::address_of(user1)==admin::get_admin_address(),ENOT_ADMIN);
    }

    // #[test(creator = @main, user1 = @0x456 )]
    // #[expected_failure(abort_code = ENOT_ADMIN)]
    // public fun test_edit_admin_2(creator: &signer, user1: &signer) acquires AdminData {
    //     init_module(creator);
    //     assert!(signer::address_of(creator)==get_admin_address(),ENOT_ADMIN);
    //     edit_admin(creator, signer::address_of(user1));
    //     assert!(signer::address_of(creator)==get_admin_address(),ENOT_ADMIN);
    // }

    // #[test(creator = @main, user1 = @0x456 )]
    // #[expected_failure(abort_code = ENOT_ADMIN)]
    // public fun test_edit_admin_2(creator: &signer, user1: &signer) acquires AdminData {
    //     init_module(creator);

    //     edit_admin(creator, signer::address_of(user1));
     
    // }
    
}