/// This module implements the the gem tokens (fungible token). When the module initializes,
/// it creates the collection and two fungible tokens such as Corn and Meat.
module main::gem {
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
    const ENOT_ADMIN: u64 = 7;
    // The minimum mintable amount requirement is not met.
    const ENOT_MINIMUM_MINT_AMOUNT: u64 = 8;

    const ENOT_EVEN: u64 = 9;

    /// The gem collection name
    const GEM_COLLECTION_NAME: vector<u8> = b"Undying City Gem Collection";
    /// The gem collection description
    const GEM_COLLECTION_DESCRIPTION: vector<u8> = b"The in game currency for undying city.";
    /// The gem collection URI
    const GEM_COLLECTION_URI: vector<u8> = b"https://gem.collection.uri";


    const GEM_TOKEN_NAME: vector<u8> = b"Undying City Gem";


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


    struct AdminData has key {
        admin_address: address,
        company_revenue_address: address,
        buy_back_address: address,
        minimum_gem_mint_amount: u64,
        apt_cost_per_gem: u64

    }

    /// Initializes the module, creating the gem collection.
    fun init_module(caller: &signer) {
        // Create a collection for gem tokens.
        create_gem_collection(caller);

        create_gem_token_as_fungible_token(
            caller,
            string::utf8(b"Gem Token Description"),
            string::utf8(GEM_TOKEN_NAME),
            string::utf8(b"https://raw.githubusercontent.com/aptos-labs/aptos-core/main/ecosystem/typescript/sdk/examples/typescript/metadata/knight/Corn"),
            string::utf8(b"Gem"),
            string::utf8(b"GEM"),
            string::utf8(b"https://raw.githubusercontent.com/aptos-labs/aptos-core/main/ecosystem/typescript/sdk/examples/typescript/metadata/knight/Corn.png"),
            string::utf8(b"https://www.aptoslabs.com"),
        );

        let settings = AdminData{
            admin_address: signer::address_of(caller),
            company_revenue_address: signer::address_of(caller),
            buy_back_address: signer::address_of(caller),
            minimum_gem_mint_amount: 10,
            apt_cost_per_gem: 1_000_000
        };

        move_to(caller, settings);
    }

    public entry fun edit_admin(caller: &signer, new_admin_addr: address) acquires AdminData {
        let caller_address = signer::address_of(caller);
        assert_is_admin(caller_address);
        let settings_data = borrow_global_mut<AdminData>(@main);
        settings_data.admin_address = new_admin_addr;
    }

    public entry fun edit_company_revenue_address(caller: &signer, new_addr: address) acquires AdminData {
        let caller_address = signer::address_of(caller);
        assert_is_admin(caller_address);
        let settings_data = borrow_global_mut<AdminData>(@main);
        settings_data.company_revenue_address = new_addr;
    }
    
    public entry fun edit_buy_back_address(caller: &signer, new_addr: address) acquires AdminData {
        let caller_address = signer::address_of(caller);
        assert_is_admin(caller_address);
        let settings_data = borrow_global_mut<AdminData>(@main);
        settings_data.buy_back_address = new_addr;
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


    fun assert_is_admin(addr: address) acquires AdminData {
        let settings_data = borrow_global<AdminData>(@main);
        assert!(addr == settings_data.admin_address, ENOT_ADMIN);
    }

    /// Mints the given amount of the gem token to the given receiver.
    // TODO: Exchange stablecoins for gems when minting to make users pay for gems.
    public entry fun mint_gem( caller: &signer, amount: u64) acquires GemToken, AdminData {
        let admin_data = borrow_global<AdminData>(@main);
        assert!(amount >= admin_data.minimum_gem_mint_amount, ENOT_MINIMUM_MINT_AMOUNT);
        assert!(amount % 2 == 0, ENOT_EVEN);

        coin::transfer<AptosCoin>(caller, admin_data.company_revenue_address, amount/2 * admin_data.apt_cost_per_gem);
        coin::transfer<AptosCoin>(caller, admin_data.buy_back_address, amount/2 * admin_data.apt_cost_per_gem);

        let gem_token = object::address_to_object<GemToken>(gem_token_address());
        mint_internal( gem_token, signer::address_of(caller), amount);
    }


    /// Transfers the given amount of the gem token from the given sender to the given receiver.
    public entry fun transfer_gem(from: &signer, to: address, amount: u64) {
        transfer_gem_object(from, object::address_to_object<GemToken>(gem_token_address()), to, amount);
    }


    inline fun transfer_gem_object(from: &signer, gem: Object<GemToken>, to: address, amount: u64) {
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

        // Generates the object signer and the refs. The refs are used to manage the token.
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
        coin::deposit(signer::address_of(creator), coin::mint(100_000_000, &mint_cap));
        coin::deposit(signer::address_of(user1), coin::mint(100_000_000, &mint_cap));
        coin::deposit(signer::address_of(user2), coin::mint(100_000_000, &mint_cap));

        coin::destroy_burn_cap(burn_cap);
        coin::destroy_mint_cap(mint_cap);

    }

    #[test(creator = @main, user1 = @0x456, user2 = @0x789, aptos_framework = @aptos_framework)]
    public fun test_gem(creator: &signer, user1: &signer, user2: &signer, aptos_framework: &signer) acquires GemToken, AdminData {
        assert!(signer::address_of(creator) == @main, 0);

        init_module(creator);
        setup_coin(creator, user1, user2, aptos_framework);

        let user1_addr = signer::address_of(user1);
        mint_gem(user1, 50);

        let gem_token = object::address_to_object<GemToken>(gem_token_address());

        assert!(gem_balance(user1_addr, gem_token) == 50, 0);

    }
    
    #[test(creator = @main, user1 = @0x456, user2 = @0x789, aptos_framework = @aptos_framework)]
    public fun test_gem_mint(creator: &signer, user1: &signer, user2: &signer, aptos_framework: &signer) acquires GemToken, AdminData {
        init_module(creator);
        setup_coin(creator, user1, user2, aptos_framework);

        let user2_addr = signer::address_of(user2);

        mint_gem(user2, 50);

        let gem_token = object::address_to_object<GemToken>(gem_token_address());
        assert!(gem_balance(user2_addr, gem_token) == 50, 0);
    }


    #[test(creator = @main, user1 = @0x456, user2 = @0x789, aptos_framework = @aptos_framework)]
    public fun test_gem_sent_correctly(creator: &signer, user1: &signer, user2: &signer, aptos_framework: &signer) acquires GemToken, AdminData {
        init_module(creator);
        setup_coin(creator, user1, user2, aptos_framework);

        let creator_addr = signer::address_of(creator);
        let user1_addr = signer::address_of(user1);
        let user2_addr = signer::address_of(user2);

        mint_gem(user2, 50);
        assert!(coin::balance<AptosCoin>(signer::address_of(user2)) == 50_000_000, EINVALID_BALANCE);
        assert!(coin::balance<AptosCoin>(creator_addr) == 150_000_000, EINVALID_BALANCE);

        edit_buy_back_address(creator, user1_addr);
        mint_gem(user2, 10);
        assert!(coin::balance<AptosCoin>(user1_addr) == 105_000_000, EINVALID_BALANCE);
        assert!(coin::balance<AptosCoin>(creator_addr) == 155_000_000, EINVALID_BALANCE);

        edit_company_revenue_address(creator, user2_addr);
        mint_gem(user2, 10);
        assert!(coin::balance<AptosCoin>(user1_addr) == 110_000_000, EINVALID_BALANCE);
        assert!(coin::balance<AptosCoin>(creator_addr) == 155_000_000, EINVALID_BALANCE);
        assert!(coin::balance<AptosCoin>(user2_addr) == 35_000_000, EINVALID_BALANCE);

    }

    #[test(creator = @main, user1 = @0x456, user2 = @0x789, aptos_framework = @aptos_framework)]
    #[expected_failure(abort_code = ENOT_MINIMUM_MINT_AMOUNT )]
    public fun test_gem_mint_below_min(creator: &signer, user1: &signer, user2: &signer, aptos_framework: &signer) acquires GemToken, AdminData {
        init_module(creator);
        setup_coin(creator, user1, user2, aptos_framework);

        let user2_addr = signer::address_of(user2);

        mint_gem(user2, 8);

        let gem_token = object::address_to_object<GemToken>(gem_token_address());
        assert!(gem_balance(user2_addr, gem_token) == 8, 0);

    }
}