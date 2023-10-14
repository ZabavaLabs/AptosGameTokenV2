/// This module implements the the armor tokens (fungible token). When the module initializes,
/// it creates the collection and two fungible tokens such as Armor and Meat.
module dfa::equipment {
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

    /// The armor collection name
    const ARMOR_COLLECTION_NAME: vector<u8> = b"Armor Collection Name";
    /// The armor collection description
    const ARMOR_COLLECTION_DESCRIPTION: vector<u8> = b"Armor Collection Description";
    /// The armor collection URI
    const ARMOR_COLLECTION_URI: vector<u8> = b"https://armor.collection.uri";

    /// The iron token name
    const IRON_ARMOR_TOKEN_NAME: vector<u8> = b"Armor Token";
    /// The leather token name
    const LEATHER_ARMOR_TOKEN_NAME: vector<u8> = b"Meat Token";

    /// Property names
    const CONDITION_PROPERTY_NAME: vector<u8> = b"Condition";
    const RESTORATION_VALUE_PROPERTY_NAME: vector<u8> = b"Equipment Stats";
    const HEALTH_POINT_PROPERTY_NAME: vector<u8> = b"Health Point";


    #[resource_group_member(group = aptos_framework::object::ObjectGroup)]
    // Armor Token
    struct ArmorToken has key {
        /// Used to mutate properties
        property_mutator_ref: property_map::MutatorRef,
        /// Used to mint fungible assets.
        fungible_asset_mint_ref: fungible_asset::MintRef,
        /// Used to burn fungible assets.
        fungible_asset_burn_ref: fungible_asset::BurnRef,
    }

    #[resource_group_member(group = aptos_framework::object::ObjectGroup)]
    /// Restoration value of the armor. An attribute of a armor token.
    struct EquipmentStats has key {
        value: u64,
    }

    /// Initializes the module, creating the armor collection and creating two fungible tokens such as Armor, and Meat.
    fun init_module(sender: &signer) {
        // Create a collection for armor tokens.
        create_armor_collection(sender);
        // Create two armor token (i.e., Armor and Meat) as fungible tokens, meaning that there can be multiple units of them.
        create_armor_token_as_fungible_token(
            sender,
            string::utf8(b"Armor Token Description"),
            string::utf8(IRON_ARMOR_TOKEN_NAME),
            string::utf8(b"https://raw.githubusercontent.com/aptos-labs/aptos-core/main/ecosystem/typescript/sdk/examples/typescript/metadata/knight/Armor"),
            string::utf8(b"Armor"),
            string::utf8(b"ARMOR"),
            string::utf8(b"https://raw.githubusercontent.com/aptos-labs/aptos-core/main/ecosystem/typescript/sdk/examples/typescript/metadata/knight/Armor.png"),
            string::utf8(b"https://www.aptoslabs.com"),
            5,
        );
        create_armor_token_as_fungible_token(
            sender,
            string::utf8(b"Meat Token Description"),
            string::utf8(LEATHER_ARMOR_TOKEN_NAME),
            string::utf8(b"https://raw.githubusercontent.com/aptos-labs/aptos-core/main/ecosystem/typescript/sdk/examples/typescript/metadata/knight/Meat"),
            string::utf8(b"Meat"),
            string::utf8(b"MEAT"),
            string::utf8(b"https://raw.githubusercontent.com/aptos-labs/aptos-core/main/ecosystem/typescript/sdk/examples/typescript/metadata/knight/Meat.png"),
            string::utf8(b"https://www.aptoslabs.com"),
            20,
        );
    }

    #[view]
    /// Returns the restoration value of the armor token
    public fun restoration_value(token: Object<ArmorToken>): u64 acquires EquipmentStats {
        let restoration_value_in_armor = borrow_global<EquipmentStats>(object::object_address(&token));
        restoration_value_in_armor.value
    }

    #[view]
    /// Returns the balance of the armor token of the owner
    public fun armor_balance(owner_addr: address, armor: Object<ArmorToken>): u64 {
        let metadata = object::convert<ArmorToken, Metadata>(armor);
        let store = primary_fungible_store::ensure_primary_store_exists(owner_addr, metadata);
        fungible_asset::balance(store)
    }

    #[view]
    /// Returns the iron token address
    public fun iron_token_address(): address {
        armor_token_address(string::utf8(IRON_ARMOR_TOKEN_NAME))
    }

    #[view]
    /// Returns the leather token address
    public fun leather_token_address(): address {
        armor_token_address(string::utf8(LEATHER_ARMOR_TOKEN_NAME))
    }

    #[view]
    /// Returns the armor token address by name
    public fun armor_token_address(armor_token_name: String): address {
        token::create_token_address(&@dfa, &string::utf8(ARMOR_COLLECTION_NAME), &armor_token_name)
    }

    /// Mints the given amount of the iron token to the given receiver.
    public entry fun mint_iron(creator: &signer, receiver: address, amount: u64) acquires ArmorToken {
        let iron_token = object::address_to_object<ArmorToken>(iron_token_address());
        mint_internal(creator, iron_token, receiver, amount);
    }

    /// Mints the given amount of the leather token to the given receiver.
    public entry fun mint_leather(creator: &signer, receiver: address, amount: u64) acquires ArmorToken {
        let leather_token = object::address_to_object<ArmorToken>(leather_token_address());
        mint_internal(creator, leather_token, receiver, amount);
    }

    /// Transfers the given amount of the iron token from the given sender to the given receiver.
    public entry fun transfer_iron(from: &signer, to: address, amount: u64) {
        transfer_armor(from, object::address_to_object<ArmorToken>(iron_token_address()), to, amount);
    }

    /// Transfers the given amount of the leather token from the given sender to the given receiver.
    public entry fun transfer_leather(from: &signer, to: address, amount: u64) {
        transfer_armor(from, object::address_to_object<ArmorToken>(leather_token_address()), to, amount);
    }

    public entry fun transfer_armor(from: &signer, armor: Object<ArmorToken>, to: address, amount: u64) {
        let metadata = object::convert<ArmorToken, Metadata>(armor);
        primary_fungible_store::transfer(from, metadata, to, amount);
    }

    public(friend) fun burn_armor(from: &signer, armor: Object<ArmorToken>, amount: u64) acquires ArmorToken {
        let metadata = object::convert<ArmorToken, Metadata>(armor);
        let armor_addr = object::object_address(&armor);
        let armor_token = borrow_global<ArmorToken>(armor_addr);
        let from_store = primary_fungible_store::ensure_primary_store_exists(signer::address_of(from), metadata);
        fungible_asset::burn_from(&armor_token.fungible_asset_burn_ref, from_store, amount);
    }

    /// Creates the armor collection.
    fun create_armor_collection(creator: &signer) {
        // Constructs the strings from the bytes.
        let description = string::utf8(ARMOR_COLLECTION_DESCRIPTION);
        let name = string::utf8(ARMOR_COLLECTION_NAME);
        let uri = string::utf8(ARMOR_COLLECTION_URI);

        // Creates the collection with unlimited supply and without establishing any royalty configuration.
        collection::create_unlimited_collection(
            creator,
            description,
            name,
            option::none(),
            uri,
        );
    }

    /// Creates the armor token as fungible token.
    fun create_armor_token_as_fungible_token(
        creator: &signer,
        description: String,
        name: String,
        uri: String,
        fungible_asset_name: String,
        fungible_asset_symbol: String,
        icon_uri: String,
        project_uri: String,
        restoration_value: u64,
    ) {
        // The collection name is used to locate the collection object and to create a new token object.
        let collection = string::utf8(ARMOR_COLLECTION_NAME);
        // Creates the armor token, and get the constructor ref of the token. The constructor ref
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
        // (e.g., EquipemtnStats) under the token object address. The refs are used to manage the token.
        let object_signer = object::generate_signer(&constructor_ref);
        let property_mutator_ref = property_map::generate_mutator_ref(&constructor_ref);

        // Initializes the value with the given value in armor.
        move_to(&object_signer, EquipmentStats { value: restoration_value });

        // Initialize the property map.
        let properties = property_map::prepare_input(vector[], vector[], vector[]);
        property_map::init(&constructor_ref, properties);
        property_map::add_typed(
            &property_mutator_ref,
            string::utf8(RESTORATION_VALUE_PROPERTY_NAME),
            restoration_value
        );

        // Creates the fungible asset.
        primary_fungible_store::create_primary_store_enabled_fungible_asset(
            &constructor_ref,
            option::none(),
            fungible_asset_name,
            fungible_asset_symbol,
            0,
            icon_uri,
            project_uri,
        );
        let fungible_asset_mint_ref = fungible_asset::generate_mint_ref(&constructor_ref);
        let fungible_asset_burn_ref = fungible_asset::generate_burn_ref(&constructor_ref);

        // Publishes the ArmorToken resource with the refs.
        let armor_token = ArmorToken {
            property_mutator_ref,
            fungible_asset_mint_ref,
            fungible_asset_burn_ref,
        };
        move_to(&object_signer, armor_token);
    }

    /// The internal mint function.
    fun mint_internal(creator: &signer, token: Object<ArmorToken>, receiver: address, amount: u64) acquires ArmorToken {
        let armor_token = authorized_borrow<ArmorToken>(creator, &token);
        let fungible_asset_mint_ref = &armor_token.fungible_asset_mint_ref;
        let fa = fungible_asset::mint(fungible_asset_mint_ref, amount);
        primary_fungible_store::deposit(receiver, fa);
    }

    inline fun authorized_borrow<T: key>(_creator: &signer, token: &Object<T>): &ArmorToken {
        let token_address = object::object_address(token);
        assert!(
            exists<ArmorToken>(token_address),
            error::not_found(ETOKEN_DOES_NOT_EXIST),
        );

        // assert!(
        //     token::creator(*token) == signer::address_of(creator),
        //     error::permission_denied(ENOT_CREATOR),
        // );
        borrow_global<ArmorToken>(token_address)
    }

    #[test_only]
    public fun init_module_for_test(creator: &signer) {
        init_module(creator);
    }

    #[test(creator = @dfa, user1 = @0x456, user2 = @0x789)]
    public fun test_armor(creator: &signer, user1: &signer, user2: &signer) acquires ArmorToken {
        // This test assumes that the creator's address is equal to @knight.
        assert!(signer::address_of(creator) == @dfa, 0);

        // ---------------------------------------------------------------------
        // Creator creates the collection, and mints iron and leather tokens in it.
        // ---------------------------------------------------------------------
        init_module(creator);

        // -------------------------------------------
        // Creator mints and sends 100 irons to User1.
        // -------------------------------------------
        let user1_addr = signer::address_of(user1);
        let user2_addr = signer::address_of(user2);

        mint_iron(user1, user1_addr, 100);
        mint_iron(user2, user2_addr, 200);

        let armor_token = object::address_to_object<ArmorToken>(iron_token_address());
        // Assert that the user1 has 100 irons.
        assert!(armor_balance(user1_addr, armor_token) == 100, 0);
        assert!(armor_balance(user2_addr, armor_token) == 200, 0);

        // -------------------------------------------
        // Creator mints and sends 200 leathers to User2.
        // -------------------------------------------
        let user2_addr = signer::address_of(user2);
        mint_leather(creator, user2_addr, 100);
        let leather_token = object::address_to_object<ArmorToken>(leather_token_address());
        // Assert that the user2 has 200 leathers.
        assert!(armor_balance(user2_addr, leather_token) == 100, 0);

        // ------------------------------
        // User1 sends 10 irons to User2.
        // ------------------------------
        transfer_leather(user2, user1_addr, 10);
        // Assert that the user1 has 90 irons.
        assert!(armor_balance(user2_addr, leather_token) == 90, 0);
        // Assert that the user2 has 10 irons.
        assert!(armor_balance(user1_addr, leather_token) == 10, 0);

    }
}
