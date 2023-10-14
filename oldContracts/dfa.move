module dfa::store{
use aptos_framework::primary_fungible_store;
use std::string::{Self, String};
use aptos_token_objects::collection;
use aptos_framework::object::{Self, Object, ExtendRef};
use aptos_framework::fungible_asset::{Self, Metadata};
use aptos_token_objects::property_map;
use aptos_token_objects::token;
// use aptos_token_objects::royalty;

use std::error;
use std::option;
use std::signer;


/// The armor collection name
const ARMOR_COLLECTION_NAME: vector<u8> = b"Armor Collection Name";
const ARMOR_COLLECTION_DESCRIPTION: vector<u8> = b"Armor Collection Description";
const ARMOR_COLLECTION_URI: vector<u8> = b"https://armorcollectionurl.com";


const DEF_PROPERTY_NAME: vector<u8> = b"DEF";
const DEF_PROPERTY_STAT: u8 = 10;

/// ERROR CODES
/// The token does not exist
const ETOKEN_DOES_NOT_EXIST: u64 = 1;
/// The provided signer is not the creator
const ENOT_CREATOR: u64 = 2;
/// Attempted to mutate an immutable field
const EFIELD_NOT_MUTABLE: u64 = 3;
/// Attempted to burn a non-burnable token
const ETOKEN_NOT_BURNABLE: u64 = 4;
/// Attempted to mutate a property map that is not mutable
const EPROPERTIES_NOT_MUTABLE: u64 = 5;
// The collection does not exist
const ECOLLECTION_DOES_NOT_EXIST: u64 = 6;

/// The armor 1 token name
const ARMOR_1_TOKEN_NAME: vector<u8> = b"Armor 1 Token";

// CollectionManager
struct CollectionManager has key {
    creator_extend_ref: ExtendRef,
}


// Equipment Token
struct ArmorToken has key {
    /// Used to mutate properties
                    property_mutator_ref: property_map::MutatorRef,
    /// Used to mint fungible assets.
    fungible_asset_mint_ref: fungible_asset::MintRef,
    /// Used to burn fungible assets.
    fungible_asset_burn_ref: fungible_asset::BurnRef,
}


/// Initializes the module, creating the food collection and creating two fungible tokens such as Corn, and Meat.
fun init_module(my_collection_signer: &signer) {
    let creator_constructor_ref = &object::create_object(@dfa);
    let creator_extend_ref = object::generate_extend_ref(creator_constructor_ref);
    move_to(my_collection_signer, CollectionManager { creator_extend_ref });
    let creator_signer = &object::generate_signer(creator_constructor_ref);

    // Create a collection for food tokens.
    create_armor_collection(creator_signer);
    // Create two armor token (i.e., Iron and Leather) as fungible tokens, meaning that there can be multiple units of them.
    create_armor_type_token_as_fugible_token(
        creator_signer,
        string::utf8(b"Iron")
    );

    create_armor_type_token_as_fugible_token(
        creator_signer,
        string::utf8(b"Leather")
    );

}


public entry fun create_armor_collection(creator: &signer) {

        let description = string::utf8(ARMOR_COLLECTION_DESCRIPTION);
        let name = string::utf8(ARMOR_COLLECTION_NAME);
        let uri = string::utf8(ARMOR_COLLECTION_URI);
        collection::create_unlimited_collection(
            creator,
            description,
            name,
            option::none(),
            uri,
        );
}

public entry fun create_armor_type_token_as_fugible_token(creator: &signer, armor_type: String) {
    
    let new_armor_type_constructor_ref = token::create_named_token(
        creator,
        string::utf8(ARMOR_COLLECTION_NAME),
        string::utf8(b"Armor Description"),
        string::utf8(b"Armor Type"),
        option::none(),
        string::utf8(b"https://myarmor.com/my-named-token.jpeg"),
    );

    let property_mutator_ref = property_map::generate_mutator_ref(&new_armor_type_constructor_ref);
    // Make this armor token fungible so there can multiple instances of it.
    primary_fungible_store::create_primary_store_enabled_fungible_asset(
        &new_armor_type_constructor_ref,
        option::none(),
        armor_type,
        string::utf8(b"ARMOR"),
        0, // Armor cannot be divided so decimals is 0,
        string::utf8(b"https://myarmor.com/my-named-token.jpeg"),
        string::utf8(b"https://myarmor.com"),
    );

    // Add properties such as durability, defence, etc. to this armor token
        let properties = property_map::prepare_input(vector[], vector[], vector[]);
        property_map::init(&new_armor_type_constructor_ref, properties);
        property_map::add_typed(
            &property_mutator_ref,
            string::utf8(DEF_PROPERTY_NAME),
            10,
        );
        
  }


    /// Mints the given amount of the corn token to the given receiver.
    public entry fun mint_armor(creator: &signer, armor_type_address: address, receiver: address, amount: u64) acquires ArmorToken {
        let armor_type_token = object::address_to_object<ArmorToken>(armor_type_address);
        let armor_token = authorized_borrow<ArmorToken>(creator, &armor_type_token);
        let fungible_asset_mint_ref = &armor_token.fungible_asset_mint_ref;
        let fa = fungible_asset::mint(fungible_asset_mint_ref, amount);
        primary_fungible_store::deposit(receiver, fa);
    }


    inline fun authorized_borrow<T: key>(creator: &signer, token: &Object<T>): &ArmorToken {
        let token_address = object::object_address(token);
        assert!(
            exists<ArmorToken>(token_address),
            error::not_found(ETOKEN_DOES_NOT_EXIST),
        );

        assert!(
            token::creator(*token) == signer::address_of(creator),
            error::permission_denied(ENOT_CREATOR),
        );
        borrow_global<ArmorToken>(token_address)
    }


//     public entry fun mint_token(receiver: address, amount: u64) {
//         let creator_extend_ref = &borrow_global<CollectionManager>(@dfa).creator_extend_ref;
//         let creator_signer = &object::generate_signer_for_extending(creator_extend_ref);
//         let fa = fungible_asset::mint(creator_signer, amount);
//         primary_fungible_store::deposit(receiver, fa);

//    }

    // View Functions Section
    #[view]
    /// Returns the balance of the food token of the owner
    public fun armor_balance(owner_addr: address, armor: Object<ArmorToken>): u64 {
        let metadata = object::convert<ArmorToken, Metadata>(armor);
        let store = primary_fungible_store::ensure_primary_store_exists(owner_addr, metadata);
        fungible_asset::balance(store)
    }


    #[view]
    /// Returns the food token address by name
    public fun armor_token_address(armor_token_name: String): address {
        token::create_token_address(&@dfa, &string::utf8(ARMOR_COLLECTION_NAME), &armor_token_name)
    }



    #[test_only]
    public fun init_module_for_test(creator: &signer) {
        init_module(creator);
    }

    #[test(creator = @dfa, user1 = @0x456)]
    public fun test_armor(creator: &signer, user1: &signer) acquires ArmorToken {
        // This test assumes that the creator's address is equal to @knight.
        assert!(signer::address_of(creator) == @dfa, 0);

        // ---------------------------------------------------------------------
        // Creator creates the collection, and mints corn and meat tokens in it.
        // ---------------------------------------------------------------------
        init_module(creator);

        // -------------------------------------------
        // Creator mints and sends 100 corns to User1.
        // -------------------------------------------
        let user1_addr = signer::address_of(user1);
        mint_armor(creator, armor_token_address(string::utf8(b"Iron")),user1_addr, 100);

        let armor_token = object::address_to_object<ArmorToken>(armor_token_address(string::utf8(b"Iron")));
        // Assert that the user1 has 100 corns.
        assert!(armor_balance(user1_addr, armor_token) == 190, 0);

    }
}