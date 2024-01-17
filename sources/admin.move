module main::admin{

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

    const APP_SIGNER_CAPABILITY_SEED: vector<u8> = b"APP_SIGNER_CAPABILITY";
    const BURN_SIGNER_CAPABILITY_SEED: vector<u8> = b"BURN_SIGNER_CAPABILITY";
    const UC_CHARACTER_COLLECTION_NAME: vector<u8> = b"UC Character Collection Name";
    const UC_CHARACTER_COLLECTION_DESCRIPTION: vector<u8> = b"UC Character Collection Description";
    const UC_CHARACTER_COLLECTION_URI: vector<u8> = b"https://aptos.dev/img/nyan.jpeg";
    const CHARACTER_1_NAME: vector<u8> = b"Lyra Frostwhisper";
    const CHARACTER_2_NAME: vector<u8> = b"Orion Starcaster";

    

    fun init_module(account: &signer) {
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


    public fun assert_is_admin(addr: address) acquires AdminData {
        let settings_data = borrow_global<AdminData>(@main);
        assert!(addr == settings_data.admin_address, ENOT_ADMIN);
    }

    #[view]
    public fun get_admin_address(): address acquires AdminData {
        let admin_address = &borrow_global<AdminData>(@main).admin_address;
        *admin_address
    }


    #[test_only]
    public fun initialize(account: &signer){
        init_module(account);
    }

   



}