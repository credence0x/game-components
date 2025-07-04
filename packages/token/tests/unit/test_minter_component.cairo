use game_components_token::extensions::minter::interface::{IMINIGAME_TOKEN_MINTER_ID};
use openzeppelin_introspection::interface::{ISRC5Dispatcher, ISRC5DispatcherTrait};
use starknet::{contract_address_const, get_caller_address};
use snforge_std::{declare, ContractClassTrait, DeclareResultTrait};

// Test contract that embeds MinterComponent
#[starknet::contract]
mod MockMinterContract {
    use game_components_token::extensions::minter::minter::MinterComponent;
    use openzeppelin_introspection::src5::SRC5Component;
    use starknet::ContractAddress;

    component!(path: MinterComponent, storage: minter, event: MinterEvent);
    component!(path: SRC5Component, storage: src5, event: SRC5Event);

    impl MinterInternalImpl = MinterComponent::InternalImpl<ContractState>;

    #[abi(embed_v0)]
    impl SRC5Impl = SRC5Component::SRC5Impl<ContractState>;

    #[storage]
    struct Storage {
        #[substorage(v0)]
        minter: MinterComponent::Storage,
        #[substorage(v0)]
        src5: SRC5Component::Storage,
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        #[flat]
        MinterEvent: MinterComponent::Event,
        #[flat]
        SRC5Event: SRC5Component::Event,
    }

    #[constructor]
    fn constructor(ref self: ContractState) {
        self.minter.register_minter_interface();
    }

    // Expose internal functions for testing
    #[abi(embed_v0)]
    fn add_minter(ref self: ContractState, minter_address: ContractAddress) -> u32 {
        self.minter.add_minter(minter_address)
    }

    #[abi(embed_v0)]
    fn get_minter_count(self: @ContractState) -> u32 {
        self.minter.minter_count.read()
    }

    #[abi(embed_v0)]
    fn get_minter_id(self: @ContractState, minter_address: ContractAddress) -> u32 {
        self.minter.minter_ids.read(minter_address)
    }
}

// Test MNT-U-01: Add first minter
#[test]
fn test_add_first_minter() {
    let contract = declare("MockMinterContract").unwrap().contract_class();
    let (contract_address, _) = contract.deploy(@array![]).unwrap();

    let minter_contract = IMinterContract { contract_address };
    let minter_address = contract_address_const::<0x123>();

    // Add first minter
    let minter_id = minter_contract.add_minter(minter_address);

    assert!(minter_id == 1, "First minter should have ID 1");
    assert!(minter_contract.get_minter_count() == 1, "Minter count should be 1");
    assert!(minter_contract.get_minter_id(minter_address) == 1, "Minter ID lookup should return 1");
}

// Test MNT-U-02: Add second unique minter
#[test]
fn test_add_second_unique_minter() {
    let contract = declare("MockMinterContract").unwrap().contract_class();
    let (contract_address, _) = contract.deploy(@array![]).unwrap();

    let minter_contract = IMinterContract { contract_address };
    let minter1 = contract_address_const::<0x123>();
    let minter2 = contract_address_const::<0x456>();

    // Add first minter
    let id1 = minter_contract.add_minter(minter1);
    assert!(id1 == 1, "First minter should have ID 1");

    // Add second minter
    let id2 = minter_contract.add_minter(minter2);
    assert!(id2 == 2, "Second minter should have ID 2");
    assert!(minter_contract.get_minter_count() == 2, "Minter count should be 2");
}

// Test MNT-U-03: Add duplicate minter
#[test]
fn test_add_duplicate_minter() {
    let contract = declare("MockMinterContract").unwrap().contract_class();
    let (contract_address, _) = contract.deploy(@array![]).unwrap();

    let minter_contract = IMinterContract { contract_address };
    let minter_address = contract_address_const::<0x789>();

    // Add minter first time
    let id1 = minter_contract.add_minter(minter_address);
    assert!(id1 == 1, "First add should return ID 1");

    // Add same minter again
    let id2 = minter_contract.add_minter(minter_address);
    assert!(id2 == 1, "Duplicate add should return same ID");
    assert!(minter_contract.get_minter_count() == 1, "Minter count should still be 1");
}

// Test MNT-U-04: Add zero address minter
#[test]
fn test_add_zero_address_minter() {
    let contract = declare("MockMinterContract").unwrap().contract_class();
    let (contract_address, _) = contract.deploy(@array![]).unwrap();

    let minter_contract = IMinterContract { contract_address };
    let zero_address = contract_address_const::<0x0>();

    // Add zero address as minter
    let id = minter_contract.add_minter(zero_address);
    assert!(id == 1, "Zero address should get ID 1");
    assert!(minter_contract.get_minter_id(zero_address) == 1, "Zero address lookup should work");
}

// Test MNT-U-05: Add 1000 unique minters (stress test)
#[test]
fn test_add_many_unique_minters() {
    let contract = declare("MockMinterContract").unwrap().contract_class();
    let (contract_address, _) = contract.deploy(@array![]).unwrap();

    let minter_contract = IMinterContract { contract_address };

    // Add 100 minters (reduced from 1000 for test performance)
    let mut i: u32 = 1;
    loop {
        if i > 100 {
            break;
        }

        let minter_address = contract_address_const::<0x1000>() + i.into();
        let id = minter_contract.add_minter(minter_address);
        assert!(id == i, "Minter ID should increment");

        i += 1;
    };

    assert!(minter_contract.get_minter_count() == 100, "Should have 100 minters");

    // Verify some random lookups
    let addr50 = contract_address_const::<0x1000>() + 50.into();
    assert!(minter_contract.get_minter_id(addr50) == 50, "Minter 50 lookup failed");

    let addr100 = contract_address_const::<0x1000>() + 100.into();
    assert!(minter_contract.get_minter_id(addr100) == 100, "Minter 100 lookup failed");
}

// Test MNT-U-06: Minter count tracking
#[test]
fn test_minter_count_tracking() {
    let contract = declare("MockMinterContract").unwrap().contract_class();
    let (contract_address, _) = contract.deploy(@array![]).unwrap();

    let minter_contract = IMinterContract { contract_address };

    // Initial count
    assert!(minter_contract.get_minter_count() == 0, "Initial count should be 0");

    // Add minters and verify count
    minter_contract.add_minter(contract_address_const::<0x111>());
    assert!(minter_contract.get_minter_count() == 1, "Count should be 1");

    minter_contract.add_minter(contract_address_const::<0x222>());
    assert!(minter_contract.get_minter_count() == 2, "Count should be 2");

    minter_contract.add_minter(contract_address_const::<0x333>());
    assert!(minter_contract.get_minter_count() == 3, "Count should be 3");

    // Add duplicate - count shouldn't increase
    minter_contract.add_minter(contract_address_const::<0x222>());
    assert!(minter_contract.get_minter_count() == 3, "Count should still be 3 after duplicate");
}

// Test that interface is registered
#[test]
fn test_minter_interface_registered() {
    let contract = declare("MockMinterContract").unwrap().contract_class();
    let (contract_address, _) = contract.deploy(@array![]).unwrap();

    let src5_dispatcher = ISRC5Dispatcher { contract_address };
    assert!(
        src5_dispatcher.supports_interface(IMINIGAME_TOKEN_MINTER_ID),
        "Should support minter interface",
    );
}

// Helper interface for testing
#[starknet::interface]
trait IMinterContract<TContractState> {
    fn add_minter(ref self: TContractState, minter_address: ContractAddress) -> u32;
    fn get_minter_count(self: @TContractState) -> u32;
    fn get_minter_id(self: @TContractState, minter_address: ContractAddress) -> u32;
}
