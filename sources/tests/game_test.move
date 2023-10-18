//  #[test_only]
// module main::game_test{
//     use main::game::{Self, CharactersInfo, CharacterInfoEntry};
//     use aptos_framework::account::{Self, SignerCapability};
//     use aptos_framework::object::{Self, Object};
//     use aptos_std::smart_table::{Self, SmartTable};

  
//     use aptos_token_objects::collection;
//     use aptos_token_objects::token::{Self, Token};
//     use aptos_token_objects::property_map;

//     use std::option;
//     use std::signer;
 
//     use std::string::{Self, String};
//     use aptos_std::string_utils::{to_string};


//     #[test(creator = @main)]
//     public fun init_module_for_test(creator: &signer) {
//         game::init_module(creator);
//     }

//     #[test(creator = @main)]
//     public fun test_character_addition_to_table(creator: &signer)  {
//         game::init_module(creator);
//         let character_info_entry = CharacterInfoEntry{
//             name: string::utf8(b"Good"),
//             character_id: 1,
//             hp: 2,
//             atk: 3,
//             def: 4,
//             atk_spd: 5,
//             mv_spd: 6,
//         };
//         game::add_character_entry(character_info_entry);
//         game::add_character_entry(character_info_entry);
//         assert!(game::get_characters_table_length()==3,5)
//     }

//     #[test(creator = @main, user1 = @0x456, _user2 = @0x789)]
//     public fun test_mint(creator: &signer, user1: &signer, _user2: &signer) acquires CollectionCapability, Character, CharactersInfo {
   
//         game::init_module(creator);

//         game::mint_character(user1, 0);
   
//         let user_1_address = signer::address_of(user1);

//         let char1 = create_character(user1, 0,  string::utf8(CHARACTER_1_NAME), 
//             100, 10, 11, 
//             12, 50);

//         assert!(object::is_owner(char1, user_1_address), 10);
//         game::upgrade_character(char1);
//         assert!(property_map::read_u64(&char1, &string::utf8(b"ATK"))==15, 100);

//         assert!(game::get_character_info_entry(0).hp==100, 10);

//     }
// }