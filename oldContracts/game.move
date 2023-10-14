module main::game{

    use aptos_framework::account::{Self, SignerCapability};
    use aptos_framework::timestamp;
    use aptos_std::string_utils::{to_string};
    use aptos_token_objects::collection;
    use aptos_token_objects::token;
    use std::option;
    use std::signer;
    use std::signer::address_of;
    use std::string::{Self, String};
    use std::vector;
    use aptos_framework::object::{Self};

    struct Character has key {
        name: String,
        weapon_id: u64,
        hp:u64,
        def:u64,
        str:u64,
        atk_speed:u64,
        movement_speed:u64,
        mutator_ref: token::MutatorRef,
        burn_ref: token::BurnRef
    }

    // Tokens require a signer to create, so this is the signer for the collection
    struct CollectionCapability has key, drop {
        capability: SignerCapability,
        burn_signer_capability: SignerCapability,
    }

    const APP_SIGNER_CAPABILITY_SEED: vector<u8> = b"APP_SIGNER_CAPABILITY";
    const BURN_SIGNER_CAPABILITY_SEED: vector<u8> = b"BURN_SIGNER_CAPABILITY";
    const UC_CHARACTER_COLLECTION_NAME: vector<u8> = b"UC Character Collection Name";
    const UC_CHARACTER_COLLECTION_DESCRIPTION: vector<u8> = b"UC Character Collection Description";
    const UC_CHARACTER_COLLECTION_URI: vector<u8> = b"https://aptos.dev/img/nyan.jpeg";

    fun init_module(account: &signer) {
        let (token_resource, token_signer_cap) = account::create_resource_account(
            account,
            APP_SIGNER_CAPABILITY_SEED,
        );
        let (_, burn_signer_capability) = account::create_resource_account(
            account,
            BURN_SIGNER_CAPABILITY_SEED,
        );
        move_to(account, CollectionCapability {
            capability: token_signer_cap,
            burn_signer_capability,
        });

        create_character_collection(&token_resource);
        
    }

    fun get_token_signer(): signer acquires CollectionCapability {
        account::create_signer_with_capability(&borrow_global<CollectionCapability>(@main).capability)
    }

    fun create_character_collection(creator: &signer) {
        let description = string::utf8(UC_CHARACTER_COLLECTION_DESCRIPTION);
        let name = string::utf8(UC_CHARACTER_COLLECTION_NAME);
        let uri = string::utf8(UC_CHARACTER_COLLECTION_URI);

        collection::create_unlimited_collection(
            creator,
            description,
            name,
            option::none(),
            uri,
        );
    }

    public entry fun create_character(user: &signer, newname: String,
         newweapon:u64,newhp:u64, newdef :u64,newstr:u64,
         newatk_speed:u64, newmovement_speed:u64) acquires CollectionCapability {
        let uri = string::utf8(UC_CHARACTER_COLLECTION_URI);
        let description = string::utf8(UC_CHARACTER_COLLECTION_DESCRIPTION);
        let token_name = to_string(&address_of(user));

        let constructor_ref = token::create_named_token(
            &get_token_signer(),
            string::utf8(UC_CHARACTER_COLLECTION_NAME),
            description,
            token_name,
            option::none(),
            uri,
        );

        let token_signer = object::generate_signer(&constructor_ref);
        let mutator_ref = token::generate_mutator_ref(&constructor_ref);
        let burn_ref = token::generate_burn_ref(&constructor_ref);

        let new_char = Character {
            name: newname,
            weapon_id: newweapon,
            hp:newhp,
            def:newdef,
            str:newstr,
            atk_speed:newatk_speed,
            movement_speed:newmovement_speed,
            mutator_ref,
            burn_ref,
        };

        move_to(&token_signer, new_char);
    }

    inline fun get_character_internal(creator_addr: &address): (&Character) acquires Character {
        let collection = string::utf8(UC_CHARACTER_COLLECTION_NAME);
        let token_name = to_string(creator_addr);
        let creator = &get_token_signer();
        let token_address = token::create_token_address(
            &signer::address_of(creator),
            &collection,
            &token_name,
        );
        (borrow_global<Character>(token_address))
    }

    inline fun get_character_internal_mut(creator_addr: &address): (&mut Character) acquires Character {
        let collection = string::utf8(UC_CHARACTER_COLLECTION_NAME);
        let token_name = to_string(creator_addr);
        let creator = &get_token_signer();
        let token_address = token::create_token_address(
            &signer::address_of(creator),
            &collection,
            &token_name,
        );
        (borrow_global_mut<Character>(token_address))
    }
    

    // public entry fun burn_character_internal(creator_addr: &address) acquires Character,CollectionCapability{
        
    //     let collection = string::utf8(UC_CHARACTER_COLLECTION_NAME);
    //     let token_name = to_string(creator_addr);
    //     let creator = &get_token_signer();
    //     let token_address = token::create_token_address(
    //         &signer::address_of(creator),
    //         &collection,
    //         &token_name,
    //     );
    //     let char = (borrow_global_mut<Character>(token_address));

    //     token::burn(&char.burn_ref);
    // }

    #[view]
    public fun get_name(user_addr: address): String acquires Character, CollectionCapability {
        let char = get_character_internal_mut(&user_addr);

        char.name
    }

    public entry fun set_name(user_addr: address, name: String) acquires Character, CollectionCapability {
        let char = get_character_internal_mut(&user_addr);
        char.name = name;
        char.name;
    }

    #[view]
    public fun get_hp(user_addr: address): u64 acquires Character, CollectionCapability {
        let char = get_character_internal_mut(&user_addr);
        char.hp
    }

    public entry fun set_hp(user_addr: address, newhp: u64) acquires Character, CollectionCapability {
        let char = get_character_internal_mut(&user_addr);
        char.hp = newhp;
        char.hp;
    }

    #[view]
    public fun get_weapon(user_addr: address): u64 acquires Character, CollectionCapability {
        let char = get_character_internal_mut(&user_addr);
        char.weapon_id
    }

    public entry fun set_weapon(user_addr: address, newweapon: u64) acquires Character, CollectionCapability {
        let char = get_character_internal_mut(&user_addr);
        char.weapon_id = newweapon;
        char.weapon_id;
    }
    #[view]
    public fun get_def(user_addr: address): u64 acquires Character, CollectionCapability {
        let char = get_character_internal_mut(&user_addr);
        char.def
    }

    public entry fun set_def(user_addr: address, newdef: u64) acquires Character, CollectionCapability {
        let char = get_character_internal_mut(&user_addr);
        char.def = newdef;
        char.def;
    }
    #[view]
    public fun get_str(user_addr: address): u64 acquires Character, CollectionCapability {
        let char = get_character_internal_mut(&user_addr);
        char.str
    }

    public entry fun set_str(user_addr: address, newstr: u64) acquires Character, CollectionCapability {
        let char = get_character_internal_mut(&user_addr);
        char.str = newstr;
        char.str;
    }
    #[view]
    public fun get_atkspd(user_addr: address): u64 acquires Character, CollectionCapability {
        let char = get_character_internal_mut(&user_addr);
        char.atk_speed
    }

    public entry fun set_atkspd(user_addr: address, newatkspd: u64) acquires Character, CollectionCapability {
        let char = get_character_internal_mut(&user_addr);
        char.atk_speed = newatkspd;
        char.atk_speed;
    }
    #[view]
    public fun get_movementspd(user_addr: address): u64 acquires Character, CollectionCapability {
        let char = get_character_internal_mut(&user_addr);
        char.movement_speed
    }

    public entry fun set_movementspd(user_addr: address, newmovement_speed: u64) acquires Character, CollectionCapability {
        let char = get_character_internal_mut(&user_addr);
        char.movement_speed = newmovement_speed;
        char.movement_speed;
    }

    #[view]
    public fun get_character(user_addr: address): (String, u64, u64, u64, u64) acquires Character, CollectionCapability {
        let collection = string::utf8(UC_CHARACTER_COLLECTION_NAME);
        let token_name = to_string(&user_addr);
        let token_address = token::create_token_address(
            &user_addr,
            &collection,
            &token_name,
        );
        let has_char = exists<Character>(token_address);

        if (!has_char) {
            return (string::utf8(b""), 0, 0, 0, 0)
        };
        let char = get_character_internal(&user_addr);
        (char.name, char.weapon_id, char.hp, char.def, char.str)
    }
}