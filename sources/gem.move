/// This module implements the the gem tokens (fungible token). When the module initializes,
/// it creates the collection and two fungible tokens such as Corn and Meat.
module main::gem {
    use aptos_framework::fungible_asset::{Self, Metadata};
    use aptos_framework::object::{Self, Object};
    use aptos_framework::primary_fungible_store;
    use aptos_token_objects::collection;
    use aptos_token_objects::property_map;
    use aptos_token_objects::token;
    use std::error;
    use std::option;
    use std::signer;
    use std::string::{Self, String};

    friend main::character;

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

    /// The gem collection name
    const GEM_COLLECTION_NAME: vector<u8> = b"Gem Collection Name";
    /// The gem collection description
    const GEM_COLLECTION_DESCRIPTION: vector<u8> = b"Gem Collection Description";
    /// The gem collection URI
    const GEM_COLLECTION_URI: vector<u8> = b"https://gem.collection.uri";


    const GEM_TOKEN_NAME: vector<u8> = b"Gem Token";

    #[resource_group_member(group = aptos_framework::object::ObjectGroup)]
    // Gem Token
    struct GemToken has key {
        /// Used to mutate properties
        property_mutator_ref: property_map::MutatorRef,
        /// Used to mint fungible assets.
        fungible_asset_mint_ref: fungible_asset::MintRef,
        /// Used to burn fungible assets.
        fungible_asset_burn_ref: fungible_asset::BurnRef,
    }


    /// Initializes the module, creating the gem collection and creating two fungible tokens such as Corn, and Meat.
    fun init_module(sender: &signer) {
        // Create a collection for gem tokens.
        create_gem_collection(sender);

        create_gem_token_as_fungible_token(
            sender,
            string::utf8(b"Gem Token Description"),
            string::utf8(GEM_TOKEN_NAME),
            string::utf8(b"https://raw.githubusercontent.com/aptos-labs/aptos-core/main/ecosystem/typescript/sdk/examples/typescript/metadata/knight/Corn"),
            string::utf8(b"Gem"),
            string::utf8(b"GEM"),
            string::utf8(b"https://raw.githubusercontent.com/aptos-labs/aptos-core/main/ecosystem/typescript/sdk/examples/typescript/metadata/knight/Corn.png"),
            string::utf8(b"https://www.aptoslabs.com"),
        );
    }

 

    #[view]
    /// Returns the balance of the gem token of the owner
    public fun gem_balance(owner_addr: address, gem: Object<GemToken>): u64 {
        let metadata = object::convert<GemToken, Metadata>(gem);
        let store = primary_fungible_store::ensure_primary_store_exists(owner_addr, metadata);
        fungible_asset::balance(store)
    }

    #[view]
    /// Returns the gem token address
    public fun gem_token_address(): address {
        gem_token_address_by_name(string::utf8(GEM_TOKEN_NAME))
    }

    #[view]
    /// Returns the gem token address by name
    public fun gem_token_address_by_name(gem_token_name: String): address {
        token::create_token_address(&@main, &string::utf8(GEM_COLLECTION_NAME), &gem_token_name)
    }

    /// Mints the given amount of the gem token to the given receiver.
    // TODO: Exchange stablecoins for gems when minting to make users pay for gems.
    public entry fun mint_gem( caller: &signer, amount: u64) acquires GemToken {
        let gem_token = object::address_to_object<GemToken>(gem_token_address());
        mint_internal( gem_token, signer::address_of(caller), amount);
    }


    /// Transfers the given amount of the gem token from the given sender to the given receiver.
    public entry fun transfer_gem(from: &signer, to: address, amount: u64) {
        transfer_gem_object(from, object::address_to_object<GemToken>(gem_token_address()), to, amount);
    }


    public entry fun transfer_gem_object(from: &signer, gem: Object<GemToken>, to: address, amount: u64) {
        let metadata = object::convert<GemToken, Metadata>(gem);
        primary_fungible_store::transfer(from, metadata, to, amount);
    }

    public(friend) fun burn_gem(from: &signer, gem: Object<GemToken>, amount: u64) acquires GemToken {
        let metadata = object::convert<GemToken, Metadata>(gem);
        let gem_addr = object::object_address(&gem);
        let gem_token = borrow_global<GemToken>(gem_addr);
        let from_store = primary_fungible_store::ensure_primary_store_exists(signer::address_of(from), metadata);
        fungible_asset::burn_from(&gem_token.fungible_asset_burn_ref, from_store, amount);
    }

     fun create_gem_collection(creator: &signer) {
        // Constructs the strings from the bytes.
        let description = string::utf8(GEM_COLLECTION_DESCRIPTION);
        let name = string::utf8(GEM_COLLECTION_NAME);
        let uri = string::utf8(GEM_COLLECTION_URI);

        // Creates the collection with unlimited supply and without establishing any royalty configuration.
        collection::create_unlimited_collection(
            creator,
            description,
            name,
            option::none(),
            uri,
        );
    }

    /// Creates the gem token as fungible token.
    fun create_gem_token_as_fungible_token(
        creator: &signer,
        description: String,
        name: String,
        uri: String,
        fungible_asset_name: String,
        fungible_asset_symbol: String,
        icon_uri: String,
        project_uri: String,
    ) {
        // The collection name is used to locate the collection object and to create a new token object.
        let collection = string::utf8(GEM_COLLECTION_NAME);
        // Creates the gem token, and get the constructor ref of the token. The constructor ref
        // is used to generate the refs of the token.
        let constructor_ref = token::create_named_token(
            creator,
            collection,
            description,
            name,
            option::none(),
            uri,
        );

        // Generates the object signer and the refs. The object signer is used to publish a resource
        // (e.g., RestorationValue) under the token object address. The refs are used to manage the token.
        let object_signer = object::generate_signer(&constructor_ref);
        let property_mutator_ref = property_map::generate_mutator_ref(&constructor_ref);

        let decimals = 0;

        // Creates the fungible asset.
        primary_fungible_store::create_primary_store_enabled_fungible_asset(
            &constructor_ref,
            option::none(),
            fungible_asset_name,
            fungible_asset_symbol,
            decimals,
            icon_uri,
            project_uri,
        );
        let fungible_asset_mint_ref = fungible_asset::generate_mint_ref(&constructor_ref);
        let fungible_asset_burn_ref = fungible_asset::generate_burn_ref(&constructor_ref);

        // Publishes the GemToken resource with the refs.
        let gem_token = GemToken {
            property_mutator_ref,
            fungible_asset_mint_ref,
            fungible_asset_burn_ref,
        };
        move_to(&object_signer, gem_token);
    }

    /// The internal mint function.
    fun mint_internal(token: Object<GemToken>, receiver: address, amount: u64) acquires GemToken {
        let gem_token = authorized_borrow<GemToken>( &token);
        let fungible_asset_mint_ref = &gem_token.fungible_asset_mint_ref;
        let fa = fungible_asset::mint(fungible_asset_mint_ref, amount);
        primary_fungible_store::deposit(receiver, fa);
    }

    inline fun authorized_borrow<T: key>(token: &Object<T>): &GemToken {
        let token_address = object::object_address(token);
        assert!(
            exists<GemToken>(token_address),
            error::not_found(ETOKEN_DOES_NOT_EXIST),
        );

        borrow_global<GemToken>(token_address)
    }

    #[test_only]
    public fun init_module_for_test(creator: &signer) {
        init_module(creator);
    }

    #[test(creator = @main, user1 = @0x456, user2 = @0x789)]
    public fun test_gem(creator: &signer, user1: &signer, user2: &signer) acquires GemToken {
        assert!(signer::address_of(creator) == @main, 0);

        init_module(creator);

        let user1_addr = signer::address_of(user1);
        mint_gem(user1, 50);

        let gem_token = object::address_to_object<GemToken>(gem_token_address());

        assert!(gem_balance(user1_addr, gem_token) == 50, 0);

    }
    
    #[test(creator = @main, user1 = @0x456, user2 = @0x789)]
    public fun test_gem_mint(creator: &signer, user1: &signer, user2: &signer) acquires GemToken {
        init_module(creator);

        let user1_addr = signer::address_of(user1);
        let user2_addr = signer::address_of(user2);

        mint_gem(user2, 50);

        let gem_token = object::address_to_object<GemToken>(gem_token_address());
        assert!(gem_balance(user2_addr, gem_token) == 50, 0);

    }
}