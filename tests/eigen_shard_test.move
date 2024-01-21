/// This module implements the the shard tokens (fungible token). When the module initializes,
/// it creates the collection and two fungible tokens such as Corn and Meat.
module main::eigen_shard_test {
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
    use std::string::{Self};

   

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
    const PROJECT_URI: vector<u8> = b"https://zabavalabs.com";
    //Point to Image
    const PROJECT_ICON_URI: vector<u8> = b"https://zabavalabs.com";
    const URI: vector<u8> = b"https://github.com/ZabavaLabs/AptosGameTokenV2";

    use main::eigen_shard::{Self, EigenShardCapability};
    use main::admin;


    #[test(creator = @main, user1 = @0x456, user2 = @0x789, aptos_framework = @aptos_framework)]
    public fun test_shard (creator: &signer, user1: &signer, user2: &signer, aptos_framework: &signer)  {
        assert!(signer::address_of(creator) == @main, 0);

        eigen_shard::initialize_for_test(creator);
        eigen_shard::setup_coin(creator, user1, user2, aptos_framework);
        admin::initialize_for_test(creator);

        let user1_addr = signer::address_of(user1);
        eigen_shard::mint_shard(user1, 50);

        let shard_token = object::address_to_object<EigenShardCapability>(eigen_shard::shard_token_address());

        assert!(eigen_shard::shard_balance(user1_addr, shard_token) == 50, 0);

    }
    
    #[test(creator = @main, user1 = @0x456, user2 = @0x789, aptos_framework = @aptos_framework)]
    public fun test_shard_mint (creator: &signer, user1: &signer, user2: &signer, aptos_framework: &signer)  {
        eigen_shard::initialize_for_test(creator);
        eigen_shard::setup_coin(creator, user1, user2, aptos_framework);
        admin::initialize_for_test(creator);

        let user2_addr = signer::address_of(user2);

        eigen_shard::mint_shard(user2, 50);

        let shard_token = object::address_to_object(eigen_shard::shard_token_address());
        assert!(eigen_shard::shard_balance(user2_addr, shard_token) == 50, 0);
    }


    #[test(creator = @main, user1 = @0x456, user2 = @0x789, aptos_framework = @aptos_framework)]
    public fun test_shard_sent_correctly (creator: &signer, user1: &signer, user2: &signer, aptos_framework: &signer)  {
        eigen_shard::initialize_for_test(creator);
        eigen_shard::setup_coin(creator, user1, user2, aptos_framework);
        admin::initialize_for_test(creator);
        let creator_addr = signer::address_of(creator);
        let user1_addr = signer::address_of(user1);
        let user2_addr = signer::address_of(user2);

        // mint_shard(user2, 50);
        // assert!(coin::balance<AptosCoin>(signer::address_of(user2)) == 5_00_000_000, EINVALID_BALANCE);
        // assert!(coin::balance<AptosCoin>(creator_addr) == 15_00_000_000, EINVALID_BALANCE);

        // edit_buy_back_address(creator, user1_addr);
        // mint_shard(user2, 10);
        // assert!(coin::balance<AptosCoin>(user1_addr) == 10_50_000_000, EINVALID_BALANCE);
        // assert!(coin::balance<AptosCoin>(creator_addr) == 15_50_000_000, EINVALID_BALANCE);

        // edit_company_revenue_address(creator, user2_addr);
        // mint_shard(user2, 10);
        // assert!(coin::balance<AptosCoin>(user1_addr) == 11_00_000_000, EINVALID_BALANCE);
        // assert!(coin::balance<AptosCoin>(creator_addr) == 15_50_000_000, EINVALID_BALANCE);
        // assert!(coin::balance<AptosCoin>(user2_addr) == 3_50_000_000, EINVALID_BALANCE);
        eigen_shard::mint_shard(user2, 50);
        assert!(coin::balance<AptosCoin>(signer::address_of(user2)) == 50_000_000, EINVALID_BALANCE);
        assert!(coin::balance<AptosCoin>(creator_addr) == 150_000_000, EINVALID_BALANCE);

        eigen_shard::edit_buy_back_address(creator, user1_addr);
        eigen_shard::mint_shard(user2, 10);
        assert!(coin::balance<AptosCoin>(user1_addr) == 105_000_000, EINVALID_BALANCE);
        assert!(coin::balance<AptosCoin>(creator_addr) == 155_000_000, EINVALID_BALANCE);

        eigen_shard::edit_company_revenue_address(creator, user2_addr);
        eigen_shard::mint_shard(user2, 10);
        assert!(coin::balance<AptosCoin>(user1_addr) == 110_000_000, EINVALID_BALANCE);
        assert!(coin::balance<AptosCoin>(creator_addr) == 155_000_000, EINVALID_BALANCE);
        assert!(coin::balance<AptosCoin>(user2_addr) == 35_000_000, EINVALID_BALANCE);
    }

    #[test(creator = @main, user1 = @0x456, user2 = @0x789, aptos_framework = @aptos_framework)]
    #[expected_failure(abort_code = ENOT_MINIMUM_MINT_AMOUNT, location = main::eigen_shard )]
    public fun test_shard_mint_below_min (creator: &signer, user1: &signer, user2: &signer, aptos_framework: &signer) {
        eigen_shard::initialize_for_test(creator);
        eigen_shard::setup_coin(creator, user1, user2, aptos_framework);
        admin::initialize_for_test(creator);

        let user2_addr = signer::address_of(user2);

        eigen_shard::mint_shard(user2, 8);

        let shard_token = object::address_to_object<EigenShardCapability>(eigen_shard::shard_token_address());
        assert!(eigen_shard::shard_balance(user2_addr, shard_token) == 8, 0);

    }

    #[test(creator = @main, user1 = @0x456, user2 = @0x789, aptos_framework = @aptos_framework)]
    public fun test_edit_token_name (creator: &signer, user1: &signer, user2: &signer, aptos_framework: &signer) {
        eigen_shard::initialize_for_test(creator);
        eigen_shard::setup_coin(creator, user1, user2, aptos_framework);
        admin::initialize_for_test(creator);

        let creator_addr = signer::address_of(creator);
        let user1_addr = signer::address_of(user1);
        let user2_addr = signer::address_of(user2);

        eigen_shard::mint_shard(user2, 50);

        let shard_token = object::address_to_object<EigenShardCapability>(eigen_shard::shard_token_address());
        assert!(token::name(shard_token)==string::utf8(EIGEN_SHARD_TOKEN_NAME),EINVALID_DATA);
  
        let new_name = string::utf8(b"New Token Name");
        eigen_shard::set_token_name(creator, new_name);
        assert!(token::name(shard_token)==new_name,EINVALID_DATA);

        assert!(token::uri(shard_token)==string::utf8(URI),EINVALID_DATA);
        let new_uri = string::utf8(b"www.google.com");
        eigen_shard::set_token_uri(creator, new_uri);
        
        assert!(token::uri(shard_token)==new_uri,EINVALID_DATA);
    }
}