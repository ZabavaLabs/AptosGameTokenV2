/// This module implements the the shard tokens (fungible token). When the module initializes,
/// it creates the collection and two fungible tokens such as Corn and Meat.
module main::eigen_shard {
    use aptos_framework::fungible_asset::{Self, Metadata};
    use aptos_framework::object::{Self, Object};
    use aptos_framework::aptos_coin::AptosCoin;
    use aptos_framework::coin;
    use aptos_framework::primary_fungible_store;
    use aptos_token_objects::collection;
    use aptos_token_objects::property_map;
    use aptos_token_objects::token;
    use std::error;
    use std::option;
    use std::signer;
    use std::string::{Self, String};

    // friend main::character;
    friend main::equipment;
    friend main::omni_cache;

    use main::admin;

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

    const EINVALID_BALANCE: u64 = 7;


    // The caller is not the admin
    const ENOT_ADMIN: u64 = 8;
    // The minimum mintable amount requirement is not met.
    const ENOT_MINIMUM_MINT_AMOUNT: u64 = 9;

    const ENOT_EVEN: u64 = 10;

    const EINVALID_DATA: u64 = 11;


    /// The shard collection name
    const EIGEN_SHARD_COLLECTION_NAME: vector<u8> = b"Undying City Eigen Shard Collection";
    /// The shard collection description
    const EIGEN_SHARD_COLLECTION_DESCRIPTION: vector<u8> = b"This collection stores the Eigen Shard token." ;
    /// The shard collection URI
    const EIGEN_SHARD_COLLECTION_URI: vector<u8> = b"https://shard.collection.uri";

   /// The shard token name
    const EIGEN_SHARD_TOKEN_NAME: vector<u8> = b"Eigen Shard";
    const EIGEN_SHARD_TOKEN_DESCRIPTION: vector<u8> = b"The Eigen Shard embodies the essence of construction and empowerment in the digital frontier." ;
    const EIGEN_SHARD_ASSET_NAME: vector<u8> = b"Eigen Shard";
    const EIGEN_SHARD_ASSET_SYMBOL: vector<u8> = b"ES";
    //Point to project website or app
    const PROJECT_URI: vector<u8> = b"https://undying_city.zabavalabs.com";
    //Point to Image
    const PROJECT_ICON_URI: vector<u8> = b"https://zabavalabs.com";
    const URI: vector<u8> = b"https://github.com/ZabavaLabs/AptosGameTokenV2";


    #[resource_group_member(group = aptos_framework::object::ObjectGroup)]
    // Shard Token
    struct EigenShardCapability has key {
        mutator_ref: token::MutatorRef,
        /// Used to mutate properties
        property_mutator_ref: property_map::MutatorRef,
        /// Used to mint fungible assets.
        fungible_asset_mint_ref: fungible_asset::MintRef,
        /// Used to burn fungible assets.
        fungible_asset_burn_ref: fungible_asset::BurnRef,
    }

    #[resource_group_member(group = aptos_framework::object::ObjectGroup)]
    struct ShardCollectionCapability has key {
        collection_mutator_ref: collection::MutatorRef
    }

    struct EigenShardData has key {
        company_revenue_address: address,
        buy_back_address: address,
        minimum_shard_mint_amount: u64,
        apt_cost_per_shard: u64

    }

    /// Initializes the module, creating the shard collection.
    fun init_module(caller: &signer) {
        // Create a collection for shard tokens.
        create_shard_collection(caller);

        create_shard_token_as_fungible_token(
            caller,
            string::utf8(EIGEN_SHARD_TOKEN_DESCRIPTION),
            string::utf8(EIGEN_SHARD_TOKEN_NAME),
            string::utf8(URI),
            string::utf8(EIGEN_SHARD_ASSET_NAME),
            string::utf8(EIGEN_SHARD_ASSET_SYMBOL),
            string::utf8(PROJECT_ICON_URI),
            string::utf8(PROJECT_URI),
        );

        let settings = EigenShardData{
            company_revenue_address: signer::address_of(caller),
            buy_back_address: signer::address_of(caller),
            minimum_shard_mint_amount: 10,
            apt_cost_per_shard: 1_000_000
        };

        move_to(caller, settings);
    }

    public entry fun set_company_revenue_address(caller: &signer, new_addr: address) acquires EigenShardData {
        let caller_address = signer::address_of(caller);
        admin::assert_is_admin(caller_address);
        let settings_data = borrow_global_mut<EigenShardData>(@main);
        settings_data.company_revenue_address = new_addr;
    }
    
    public entry fun set_buy_back_address(caller: &signer, new_addr: address) acquires EigenShardData {
        let caller_address = signer::address_of(caller);
        admin::assert_is_admin(caller_address);
        let settings_data = borrow_global_mut<EigenShardData>(@main);
        settings_data.buy_back_address = new_addr;
    }
 
    public entry fun set_token_name(caller: &signer, new_name: String) acquires EigenShardCapability{
        let caller_address = signer::address_of(caller);
        admin::assert_is_admin(caller_address);
        let shard_token_capability = borrow_global<EigenShardCapability>(shard_token_address());
        token::set_name(&shard_token_capability.mutator_ref, new_name);
    }

    public entry fun set_token_uri(caller: &signer, new_uri: String) acquires EigenShardCapability{
        let caller_address = signer::address_of(caller);
        admin::assert_is_admin(caller_address);
        let shard_token_capability = borrow_global<EigenShardCapability>(shard_token_address());
        token::set_uri(&shard_token_capability.mutator_ref, new_uri);
    }

    public entry fun set_collection_uri(caller: &signer, new_uri: String) acquires ShardCollectionCapability{
        let caller_address = signer::address_of(caller);
        admin::assert_is_admin(caller_address);
        let collection_capability = borrow_global<ShardCollectionCapability>(shard_collection_address());
        collection::set_uri(&collection_capability.collection_mutator_ref, new_uri);
    }

    public entry fun set_collection_description(caller: &signer, new_description: String) acquires ShardCollectionCapability{
        let caller_address = signer::address_of(caller);
        admin::assert_is_admin(caller_address);
        let collection_capability = borrow_global<ShardCollectionCapability>(shard_collection_address());
        collection::set_description(&collection_capability.collection_mutator_ref, new_description);
    }



    /// Mints the given amount of the shard token to the given receiver.
    // TODO: Exchange stablecoins for shards when minting to make users pay for shards.
    public entry fun mint_shard( caller: &signer, amount: u64) acquires EigenShardCapability, EigenShardData {
        let admin_data = borrow_global<EigenShardData>(@main);
        assert!(amount >= admin_data.minimum_shard_mint_amount, ENOT_MINIMUM_MINT_AMOUNT);
        assert!(amount % 2 == 0, ENOT_EVEN);

        coin::transfer<AptosCoin>(caller, admin_data.company_revenue_address, amount/2 * admin_data.apt_cost_per_shard);
        coin::transfer<AptosCoin>(caller, admin_data.buy_back_address, amount/2 * admin_data.apt_cost_per_shard);

        let shard_token = object::address_to_object<EigenShardCapability>(shard_token_address());
        mint_internal( shard_token, signer::address_of(caller), amount);
    }


    /// Transfers the given amount of the shard token from the given sender to the given receiver.
    public entry fun transfer_shard(from: &signer, to: address, amount: u64) {
        transfer_shard_object(from, object::address_to_object<EigenShardCapability>(shard_token_address()), to, amount);
    }


    inline fun transfer_shard_object(from: &signer, shard: Object<EigenShardCapability>, to: address, amount: u64) {
        let metadata = object::convert<EigenShardCapability, Metadata>(shard);
        primary_fungible_store::transfer(from, metadata, to, amount);
    }

    public(friend) fun burn_shard(from: &signer, shard: Object<EigenShardCapability>, amount: u64) acquires EigenShardCapability {
        let metadata = object::convert<EigenShardCapability, Metadata>(shard);
        let shard_addr = object::object_address(&shard);
        let shard_token = borrow_global<EigenShardCapability>(shard_addr);
        let from_store = primary_fungible_store::ensure_primary_store_exists(signer::address_of(from), metadata);
        fungible_asset::burn_from(&shard_token.fungible_asset_burn_ref, from_store, amount);
    }

     fun create_shard_collection(creator: &signer) {
        // Constructs the strings from the bytes.
        let description = string::utf8(EIGEN_SHARD_COLLECTION_DESCRIPTION);
        let name = string::utf8(EIGEN_SHARD_COLLECTION_NAME);
        let uri = string::utf8(EIGEN_SHARD_COLLECTION_URI);

        // Creates the collection with unlimited supply and without establishing any royalty configuration.
        let collection_constructor_ref = collection::create_unlimited_collection(
            creator,
            description,
            name,
            option::none(),
            uri,
        );

        let object_signer = object::generate_signer(&collection_constructor_ref);

        let collection_mutator_ref = collection::generate_mutator_ref(&collection_constructor_ref);

        let collection_capability = ShardCollectionCapability{
            collection_mutator_ref
        };
        move_to(&object_signer, collection_capability);
    }

    /// Creates the shard token as fungible token.
    fun create_shard_token_as_fungible_token(
        creator: &signer,
        description: String,
        token_name: String,
        uri: String,
        fungible_asset_name: String,
        fungible_asset_symbol: String,
        icon_uri: String,
        project_uri: String,
    ) {
        // The collection name is used to locate the collection object and to create a new token object.
        let collection = string::utf8(EIGEN_SHARD_COLLECTION_NAME);
        // Creates the shard token, and get the constructor ref of the token. The constructor ref
        // is used to generate the refs of the token.
        let constructor_ref = token::create_named_token(
            creator,
            collection,
            description,
            token_name,
            option::none(),
            uri,
        );

        // Generates the object signer and the refs. The refs are used to manage the token.
        let object_signer = object::generate_signer(&constructor_ref);
        let property_mutator_ref = property_map::generate_mutator_ref(&constructor_ref);
        let mutator_ref = token::generate_mutator_ref(&constructor_ref);


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

        // Publishes the EigenShardCapability resource with the refs.
        let shard_token = EigenShardCapability {
            mutator_ref,
            property_mutator_ref,
            fungible_asset_mint_ref,
            fungible_asset_burn_ref,
        };
        move_to(&object_signer, shard_token);
    }

    /// The internal mint function.
    fun mint_internal(token: Object<EigenShardCapability>, receiver: address, amount: u64) acquires EigenShardCapability {
        let shard_token = authorized_borrow<EigenShardCapability>( &token);
        let fungible_asset_mint_ref = &shard_token.fungible_asset_mint_ref;
        let fa = fungible_asset::mint(fungible_asset_mint_ref, amount);
        primary_fungible_store::deposit(receiver, fa);
    }

    inline fun authorized_borrow<T: key>(token: &Object<T>): &EigenShardCapability {
        let token_address = object::object_address(token);
        assert!(
            exists<EigenShardCapability>(token_address),
            error::not_found(ETOKEN_DOES_NOT_EXIST),
        );

        borrow_global<EigenShardCapability>(token_address)
    }

    // ANCHOR View Functions
    #[view]
    /// Returns the balance of the shard token of the owner
    public fun shard_balance(owner_addr: address, shard: Object<EigenShardCapability>): u64 {
        let metadata = object::convert<EigenShardCapability, Metadata>(shard);
        let store = primary_fungible_store::ensure_primary_store_exists(owner_addr, metadata);
        fungible_asset::balance(store)
    }
    
    #[view]
    /// Returns the shard token address
    public fun shard_collection_address(): address {
        collection::create_collection_address(&@main, &string::utf8(EIGEN_SHARD_COLLECTION_NAME))
    }

    // #[view]
    // /// Returns the shard token address by name
    // public fun shard_collection_address_by_name(shard_collection_name: String): address {
    //     collection::create_collection_address(&@main, &string::utf8(EIGEN_SHARD_COLLECTION_NAME), &shard_token_name)
    // }

    #[view]
    /// Returns the shard token address
    public fun shard_token_address(): address {
        shard_token_address_by_name(string::utf8(EIGEN_SHARD_TOKEN_NAME))
    }

    #[view]
    /// Returns the shard token address by name
    public fun shard_token_address_by_name(shard_token_name: String): address {
        token::create_token_address(&@main, &string::utf8(EIGEN_SHARD_COLLECTION_NAME), &shard_token_name)
    }


    #[test_only]
    public fun initialize_for_test(creator: &signer) {
        init_module(creator);
    }

    #[test_only]
    public fun setup_coin(creator:&signer, user1:&signer, user2:&signer, aptos_framework: &signer){
        use aptos_framework::account::create_account_for_test;
        create_account_for_test(signer::address_of(creator));
        create_account_for_test(signer::address_of(user1));
        create_account_for_test(signer::address_of(user2));

        let (burn_cap, mint_cap) = aptos_framework::aptos_coin::initialize_for_test(aptos_framework);
        coin::register<AptosCoin>(creator);
        coin::register<AptosCoin>(user1);
        coin::register<AptosCoin>(user2);
        // coin::deposit(signer::address_of(creator), coin::mint(10_00_000_000, &mint_cap));
        // coin::deposit(signer::address_of(user1), coin::mint(10_00_000_000, &mint_cap));
        // coin::deposit(signer::address_of(user2), coin::mint(10_00_000_000, &mint_cap));

        coin::deposit(signer::address_of(creator), coin::mint(100_000_000, &mint_cap));
        coin::deposit(signer::address_of(user1), coin::mint(100_000_000, &mint_cap));
        coin::deposit(signer::address_of(user2), coin::mint(100_000_000, &mint_cap));


        coin::destroy_burn_cap(burn_cap);
        coin::destroy_mint_cap(mint_cap);

    }

}