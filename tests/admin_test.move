 #[test_only]
module main::admin_test{
 
    use std::signer;

    use main::admin;

    const ENOT_ADMIN: u64 = 1;


    #[test(creator = @main, user1 = @0x456 )]
    public fun test_edit_admin(creator: &signer, user1: &signer)  {
        admin::initialize_for_test(creator);
        assert!(signer::address_of(creator)==admin::get_admin_address(),ENOT_ADMIN);
        admin::edit_admin(creator, signer::address_of(user1));
        assert!(signer::address_of(user1)==admin::get_admin_address(),ENOT_ADMIN);
    }

    
}