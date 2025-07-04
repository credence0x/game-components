use game_components_minigame::interface::{
    IMinigameDispatcher, IMinigameDispatcherTrait, IMINIGAME_ID,
};
use game_components_minigame::interface::{
    IMinigameTokenDataDispatcher, IMinigameTokenDataDispatcherTrait,
};
use game_components_token::interface::{IMinigameTokenDispatcher, IMinigameTokenDispatcherTrait};
use openzeppelin_introspection::interface::{ISRC5Dispatcher, ISRC5DispatcherTrait};
use starknet::{contract_address_const, get_caller_address};
use core::num::traits::Zero;
use snforge_std::{
    declare, ContractClassTrait, DeclareResultTrait, start_cheat_caller_address,
    stop_cheat_caller_address,
};

// Interface for testing internal functions
#[starknet::interface]
trait IMockMinigame<TContractState> {
    // Expose internal functions for testing
    fn pre_action(ref self: TContractState, token_id: u64);
    fn post_action(ref self: TContractState, token_id: u64);
    fn get_player_name(self: @TContractState, token_id: u64) -> ByteArray;
}

// Test MN-U-01: Initialize with all addresses
#[test]
fn test_initialize_with_all_addresses() {
    let token_address = contract_address_const::<0x123>();
    let settings_address = contract_address_const::<0x456>();
    let objectives_address = contract_address_const::<0x789>();

    // Deploy the MockMinigameContract
    let contract = declare("MockMinigameContract").unwrap().contract_class();
    let mut calldata = array![];
    calldata.append(token_address.into());
    calldata.append(settings_address.into());
    calldata.append(objectives_address.into());

    let (contract_address, _) = contract.deploy(@calldata).unwrap();
    let dispatcher = IMinigameDispatcher { contract_address };

    // Verify addresses are stored correctly
    assert!(dispatcher.token_address() == token_address, "Token address mismatch");
    assert!(dispatcher.settings_address() == settings_address, "Settings address mismatch");
    assert!(dispatcher.objectives_address() == objectives_address, "Objectives address mismatch");

    // Verify SRC5 interface registration
    let src5_dispatcher = ISRC5Dispatcher { contract_address };
    assert!(src5_dispatcher.supports_interface(IMINIGAME_ID), "Should support IMinigame interface");
}

// Test MN-U-02: Initialize with optional addresses = 0
#[test]
fn test_initialize_with_optional_zero() {
    let token_address = contract_address_const::<0xABC>();
    let settings_address = contract_address_const::<0x0>(); // Zero address
    let objectives_address = contract_address_const::<0x0>(); // Zero address

    // Deploy the MockMinigameContract
    let contract = declare("MockMinigameContract").unwrap().contract_class();
    let mut calldata = array![];
    calldata.append(token_address.into());
    calldata.append(settings_address.into());
    calldata.append(objectives_address.into());

    let (contract_address, _) = contract.deploy(@calldata).unwrap();
    let dispatcher = IMinigameDispatcher { contract_address };

    // Verify addresses
    assert!(dispatcher.token_address() == token_address, "Token address mismatch");
    assert!(dispatcher.settings_address().is_zero(), "Settings address should be zero");
    assert!(dispatcher.objectives_address().is_zero(), "Objectives address should be zero");
}

// Test MN-U-03: Get token_address
#[test]
fn test_get_token_address() {
    let token_address = contract_address_const::<0x111>();

    // Deploy the MockMinigameContract
    let contract = declare("MockMinigameContract").unwrap().contract_class();
    let mut calldata = array![];
    calldata.append(token_address.into());
    calldata.append(contract_address_const::<0x0>().into());
    calldata.append(contract_address_const::<0x0>().into());

    let (contract_address, _) = contract.deploy(@calldata).unwrap();
    let dispatcher = IMinigameDispatcher { contract_address };

    // Verify token_address returns correct value
    assert!(dispatcher.token_address() == token_address, "Token address mismatch");
}

// Test MN-U-04: Get settings_address
#[test]
fn test_get_settings_address() {
    let settings_address = contract_address_const::<0x222>();

    // Deploy the MockMinigameContract
    let contract = declare("MockMinigameContract").unwrap().contract_class();
    let mut calldata = array![];
    calldata.append(contract_address_const::<0x111>().into());
    calldata.append(settings_address.into());
    calldata.append(contract_address_const::<0x0>().into());

    let (contract_address, _) = contract.deploy(@calldata).unwrap();
    let dispatcher = IMinigameDispatcher { contract_address };

    // Verify settings_address returns correct value
    assert!(dispatcher.settings_address() == settings_address, "Settings address mismatch");
}

// Test MN-U-05: Get objectives_address
#[test]
fn test_get_objectives_address() {
    let objectives_address = contract_address_const::<0x333>();

    // Deploy the MockMinigameContract
    let contract = declare("MockMinigameContract").unwrap().contract_class();
    let mut calldata = array![];
    calldata.append(contract_address_const::<0x111>().into());
    calldata.append(contract_address_const::<0x0>().into());
    calldata.append(objectives_address.into());

    let (contract_address, _) = contract.deploy(@calldata).unwrap();
    let dispatcher = IMinigameDispatcher { contract_address };

    // Verify objectives_address returns correct value
    assert!(dispatcher.objectives_address() == objectives_address, "Objectives address mismatch");
}

// Test MN-U-06: pre_action with owned token
#[test]
fn test_pre_action_with_owned_token() {
    // Deploy mock token contract
    let token_contract = declare("MockMinigameToken").unwrap().contract_class();
    let (token_address, _) = token_contract.deploy(@array![]).unwrap();

    // Deploy minigame contract
    let minigame_contract = declare("MockMinigameContract").unwrap().contract_class();
    let mut calldata = array![];
    calldata.append(token_address.into());
    calldata.append(contract_address_const::<0x0>().into());
    calldata.append(contract_address_const::<0x0>().into());

    let (minigame_address, _) = minigame_contract.deploy(@calldata).unwrap();
    let mock_dispatcher = IMockMinigameDispatcher { contract_address: minigame_address };

    // Mint a token to ensure it exists and is playable
    let token_dispatcher = game_components_token::interface::IMinigameTokenDispatcher {
        contract_address: token_address,
    };
    let owner_address = get_caller_address(); // Get the current test caller
    token_dispatcher
        .mint(
            Option::None,
            Option::None,
            Option::None,
            Option::None,
            Option::None,
            Option::None,
            Option::None,
            Option::None,
            Option::None,
            owner_address,
            false,
        );

    // No need to cheat caller address since we minted to the current caller

    // Should succeed with owned token
    mock_dispatcher.pre_action(1);
}

// Test MN-U-07: pre_action with valid playable token (no ownership check in pre_action)
#[test]
fn test_pre_action_with_unowned_but_playable_token() {
    // Deploy mock token contract
    let token_contract = declare("MockMinigameToken").unwrap().contract_class();
    let (token_address, _) = token_contract.deploy(@array![]).unwrap();

    // Deploy minigame contract
    let minigame_contract = declare("MockMinigameContract").unwrap().contract_class();
    let mut calldata = array![];
    calldata.append(token_address.into());
    calldata.append(contract_address_const::<0x0>().into());
    calldata.append(contract_address_const::<0x0>().into());

    let (minigame_address, _) = minigame_contract.deploy(@calldata).unwrap();
    let mock_dispatcher = IMockMinigameDispatcher { contract_address: minigame_address };

    // Mint a token to a different owner
    let token_dispatcher = game_components_token::interface::IMinigameTokenDispatcher {
        contract_address: token_address,
    };
    let other_owner = contract_address_const::<0x888>();
    token_dispatcher
        .mint(
            Option::None,
            Option::None,
            Option::None,
            Option::None,
            Option::None,
            Option::None,
            Option::None,
            Option::None,
            Option::None,
            other_owner,
            false,
        );

    // pre_action only checks playability, not ownership - should succeed
    let different_caller = contract_address_const::<0x777>();
    start_cheat_caller_address(minigame_address, different_caller);
    mock_dispatcher.pre_action(1);
    stop_cheat_caller_address(minigame_address);
}

// Test MN-U-08: pre_action with expired token
#[test]
#[should_panic(expected: ('Game is not playable',))]
fn test_pre_action_with_expired_token() {
    // This test would require a token that is expired
    // For now, we'll use a mock that returns false for is_playable

    // Deploy mock token contract
    let token_contract = declare("MockMinigameTokenUnplayable").unwrap().contract_class();
    let (token_address, _) = token_contract.deploy(@array![]).unwrap();

    // Deploy minigame contract
    let minigame_contract = declare("MockMinigameContract").unwrap().contract_class();
    let mut calldata = array![];
    calldata.append(token_address.into());
    calldata.append(contract_address_const::<0x0>().into());
    calldata.append(contract_address_const::<0x0>().into());

    let (minigame_address, _) = minigame_contract.deploy(@calldata).unwrap();
    let mock_dispatcher = IMockMinigameDispatcher { contract_address: minigame_address };

    // Mint a token first - the MockMinigameTokenUnplayable always returns false for is_playable
    let token_dispatcher = game_components_token::interface::IMinigameTokenDispatcher {
        contract_address: token_address,
    };
    let owner_address = get_caller_address();
    token_dispatcher
        .mint(
            Option::None,
            Option::None,
            Option::None,
            Option::None,
            Option::None,
            Option::None,
            Option::None,
            Option::None,
            Option::None,
            owner_address,
            false,
        );

    // Should panic because token is not playable
    mock_dispatcher.pre_action(1);
}

// Test MN-U-09: pre_action with game_over token
#[test]
#[should_panic(expected: ('Game is not playable',))]
fn test_pre_action_with_game_over_token() {
    // This would require a token with game_over = true
    // Similar setup to expired token test

    // Deploy mock token contract
    let token_contract = declare("MockMinigameTokenGameOver").unwrap().contract_class();
    let (token_address, _) = token_contract.deploy(@array![]).unwrap();

    // Deploy minigame contract
    let minigame_contract = declare("MockMinigameContract").unwrap().contract_class();
    let mut calldata = array![];
    calldata.append(token_address.into());
    calldata.append(contract_address_const::<0x0>().into());
    calldata.append(contract_address_const::<0x0>().into());

    let (minigame_address, _) = minigame_contract.deploy(@calldata).unwrap();
    let mock_dispatcher = IMockMinigameDispatcher { contract_address: minigame_address };

    // Mint a token first - the MockMinigameTokenGameOver has game_over = true
    let token_dispatcher = game_components_token::interface::IMinigameTokenDispatcher {
        contract_address: token_address,
    };
    let owner_address = get_caller_address();
    token_dispatcher
        .mint(
            Option::None,
            Option::None,
            Option::None,
            Option::None,
            Option::None,
            Option::None,
            Option::None,
            Option::None,
            Option::None,
            owner_address,
            false,
        );

    // Should panic because game is over
    mock_dispatcher.pre_action(1);
}

// Test MN-U-10: post_action triggers update
#[test]
fn test_post_action_triggers_update() {
    // Deploy mock token contract
    let token_contract = declare("MockMinigameToken").unwrap().contract_class();
    let (token_address, _) = token_contract.deploy(@array![]).unwrap();

    // Deploy minigame contract
    let minigame_contract = declare("MockMinigameContract").unwrap().contract_class();
    let mut calldata = array![];
    calldata.append(token_address.into());
    calldata.append(contract_address_const::<0x0>().into());
    calldata.append(contract_address_const::<0x0>().into());

    let (minigame_address, _) = minigame_contract.deploy(@calldata).unwrap();
    let mock_dispatcher = IMockMinigameDispatcher { contract_address: minigame_address };

    // Call post_action - should trigger update_game on token
    mock_dispatcher.post_action(1);
    // In a real test, we would verify that update_game was called
// For now, just verify no panic
}

// Test MN-U-11: get_player_name
#[test]
fn test_get_player_name() {
    // Deploy mock token contract
    let token_contract = declare("MockMinigameToken").unwrap().contract_class();
    let (token_address, _) = token_contract.deploy(@array![]).unwrap();

    // Deploy minigame contract
    let minigame_contract = declare("MockMinigameContract").unwrap().contract_class();
    let mut calldata = array![];
    calldata.append(token_address.into());
    calldata.append(contract_address_const::<0x0>().into());
    calldata.append(contract_address_const::<0x0>().into());

    let (minigame_address, _) = minigame_contract.deploy(@calldata).unwrap();
    let mock_dispatcher = IMockMinigameDispatcher { contract_address: minigame_address };

    // Get player name for token
    let name = mock_dispatcher.get_player_name(1);

    // MockMinigameToken returns empty string
    assert!(name == "", "Player name should be empty");
}

// Test IMinigameTokenData implementation
#[test]
fn test_minigame_token_data_score() {
    // Deploy minigame contract with score tracking
    let minigame_contract = declare("MockMinigameContractWithScore").unwrap().contract_class();
    let mut calldata = array![];
    calldata.append(contract_address_const::<0x111>().into());
    calldata.append(contract_address_const::<0x0>().into());
    calldata.append(contract_address_const::<0x0>().into());

    let (minigame_address, _) = minigame_contract.deploy(@calldata).unwrap();
    let token_data_dispatcher = IMinigameTokenDataDispatcher { contract_address: minigame_address };

    // Check score
    let score = token_data_dispatcher.score(1);
    assert!(score == 0, "Initial score should be 0");
}

#[test]
fn test_minigame_token_data_game_over() {
    // Deploy minigame contract
    let minigame_contract = declare("MockMinigameContractWithScore").unwrap().contract_class();
    let mut calldata = array![];
    calldata.append(contract_address_const::<0x111>().into());
    calldata.append(contract_address_const::<0x0>().into());
    calldata.append(contract_address_const::<0x0>().into());

    let (minigame_address, _) = minigame_contract.deploy(@calldata).unwrap();
    let token_data_dispatcher = IMinigameTokenDataDispatcher { contract_address: minigame_address };

    // Check game over status
    let game_over = token_data_dispatcher.game_over(1);
    assert!(!game_over, "Initial game_over should be false");
}

// Mock contract that embeds MinigameComponent for testing
#[starknet::contract]
mod MockMinigameContract {
    use game_components_minigame::interface::{IMinigame, IMinigameTokenData, IMINIGAME_ID};
    use openzeppelin_introspection::interface::ISRC5;
    use starknet::ContractAddress;
    use starknet::storage::{StoragePointerReadAccess, StoragePointerWriteAccess};

    #[storage]
    struct Storage {
        token_address: ContractAddress,
        settings_address: ContractAddress,
        objectives_address: ContractAddress,
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {}

    #[constructor]
    fn constructor(
        ref self: ContractState,
        token_address: ContractAddress,
        settings_address: ContractAddress,
        objectives_address: ContractAddress,
    ) {
        // Initialize with simplified parameters for testing
        self.token_address.write(token_address);
        self.settings_address.write(settings_address);
        self.objectives_address.write(objectives_address);
    }

    // Implement IMinigame
    #[abi(embed_v0)]
    impl MinigameImpl of IMinigame<ContractState> {
        fn token_address(self: @ContractState) -> ContractAddress {
            self.token_address.read()
        }

        fn settings_address(self: @ContractState) -> ContractAddress {
            self.settings_address.read()
        }

        fn objectives_address(self: @ContractState) -> ContractAddress {
            self.objectives_address.read()
        }
    }

    // Implement ISRC5
    #[abi(embed_v0)]
    impl SRC5Impl of ISRC5<ContractState> {
        fn supports_interface(self: @ContractState, interface_id: felt252) -> bool {
            interface_id == IMINIGAME_ID
                || interface_id == openzeppelin_introspection::interface::ISRC5_ID
        }
    }

    // Implement IMinigameTokenData (required by component)
    #[abi(embed_v0)]
    impl MinigameTokenDataImpl of IMinigameTokenData<ContractState> {
        fn score(self: @ContractState, token_id: u64) -> u32 {
            0 // Default implementation
        }

        fn game_over(self: @ContractState, token_id: u64) -> bool {
            false // Default implementation
        }
    }

    // Expose internal functions for testing
    #[abi(embed_v0)]
    impl MockMinigameImpl of super::IMockMinigame<ContractState> {
        fn pre_action(ref self: ContractState, token_id: u64) {
            // Use libs to implement pre_action
            game_components_minigame::libs::pre_action(self.token_address.read(), token_id);
        }

        fn post_action(ref self: ContractState, token_id: u64) {
            // Use libs to implement post_action
            game_components_minigame::libs::post_action(self.token_address.read(), token_id);
        }

        fn get_player_name(self: @ContractState, token_id: u64) -> ByteArray {
            // Use libs to implement get_player_name
            game_components_minigame::libs::get_player_name(self.token_address.read(), token_id)
        }
    }
}

// Mock contract with score tracking
#[starknet::contract]
mod MockMinigameContractWithScore {
    use game_components_minigame::interface::{IMinigame, IMinigameTokenData, IMINIGAME_ID};
    use openzeppelin_introspection::interface::ISRC5;
    use starknet::ContractAddress;
    use starknet::storage::{
        Map, StorageMapReadAccess, StorageMapWriteAccess, StoragePointerReadAccess,
        StoragePointerWriteAccess,
    };

    #[storage]
    struct Storage {
        token_address: ContractAddress,
        settings_address: ContractAddress,
        objectives_address: ContractAddress,
        // Score tracking
        token_scores: Map<u64, u32>,
        token_game_over: Map<u64, bool>,
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {}

    #[constructor]
    fn constructor(
        ref self: ContractState,
        token_address: ContractAddress,
        settings_address: ContractAddress,
        objectives_address: ContractAddress,
    ) {
        self.token_address.write(token_address);
        self.settings_address.write(settings_address);
        self.objectives_address.write(objectives_address);
    }

    // Implement IMinigame
    #[abi(embed_v0)]
    impl MinigameImpl of IMinigame<ContractState> {
        fn token_address(self: @ContractState) -> ContractAddress {
            self.token_address.read()
        }

        fn settings_address(self: @ContractState) -> ContractAddress {
            self.settings_address.read()
        }

        fn objectives_address(self: @ContractState) -> ContractAddress {
            self.objectives_address.read()
        }
    }

    // Implement ISRC5
    #[abi(embed_v0)]
    impl SRC5Impl of ISRC5<ContractState> {
        fn supports_interface(self: @ContractState, interface_id: felt252) -> bool {
            interface_id == IMINIGAME_ID
                || interface_id == openzeppelin_introspection::interface::ISRC5_ID
        }
    }

    // Implement IMinigameTokenData with actual tracking
    #[abi(embed_v0)]
    impl MinigameTokenDataImpl of IMinigameTokenData<ContractState> {
        fn score(self: @ContractState, token_id: u64) -> u32 {
            self.token_scores.read(token_id)
        }

        fn game_over(self: @ContractState, token_id: u64) -> bool {
            self.token_game_over.read(token_id)
        }
    }
}

// Mock token that is not playable
#[starknet::contract]
mod MockMinigameTokenUnplayable {
    use game_components_token::interface::IMinigameToken;
    use game_components_token::structs::{TokenMetadata, Lifecycle};
    use game_components_metagame::extensions::context::structs::GameContextDetails;
    use openzeppelin_token::erc721::interface::IERC721;
    use starknet::{ContractAddress, get_caller_address};

    #[storage]
    struct Storage {}

    #[abi(embed_v0)]
    impl MinigameTokenImpl of IMinigameToken<ContractState> {
        fn token_metadata(self: @ContractState, token_id: u64) -> TokenMetadata {
            TokenMetadata {
                game_id: 1,
                minted_at: 0,
                settings_id: 0,
                lifecycle: Lifecycle { start: 0, end: 0 },
                minted_by: 0,
                soulbound: false,
                game_over: false,
                completed_all_objectives: false,
                has_context: false,
                objectives_count: 0,
            }
        }

        fn is_playable(self: @ContractState, token_id: u64) -> bool {
            false // Always return false for testing
        }

        fn settings_id(self: @ContractState, token_id: u64) -> u32 {
            0
        }
        fn player_name(self: @ContractState, token_id: u64) -> ByteArray {
            ""
        }

        fn mint(
            ref self: ContractState,
            game_address: Option<ContractAddress>,
            player_name: Option<ByteArray>,
            settings_id: Option<u32>,
            start: Option<u64>,
            end: Option<u64>,
            objective_ids: Option<Span<u32>>,
            context: Option<GameContextDetails>,
            client_url: Option<ByteArray>,
            renderer_address: Option<ContractAddress>,
            to: ContractAddress,
            soulbound: bool,
        ) -> u64 {
            1
        }

        fn update_game(ref self: ContractState, token_id: u64) {}
    }

    // Implement IERC721 for ownership checks
    #[abi(embed_v0)]
    impl ERC721Impl of IERC721<ContractState> {
        fn owner_of(self: @ContractState, token_id: u256) -> ContractAddress {
            get_caller_address() // Return caller as owner
        }

        fn safe_transfer_from(
            ref self: ContractState,
            from: ContractAddress,
            to: ContractAddress,
            token_id: u256,
            data: Span<felt252>,
        ) {}

        fn transfer_from(
            ref self: ContractState, from: ContractAddress, to: ContractAddress, token_id: u256,
        ) {}

        fn approve(ref self: ContractState, to: ContractAddress, token_id: u256) {}

        fn set_approval_for_all(
            ref self: ContractState, operator: ContractAddress, approved: bool,
        ) {}

        fn get_approved(self: @ContractState, token_id: u256) -> ContractAddress {
            starknet::contract_address_const::<0x0>()
        }

        fn is_approved_for_all(
            self: @ContractState, owner: ContractAddress, operator: ContractAddress,
        ) -> bool {
            false
        }

        fn balance_of(self: @ContractState, account: ContractAddress) -> u256 {
            1
        }
    }
}

// Mock token with game over
#[starknet::contract]
mod MockMinigameTokenGameOver {
    use game_components_token::interface::IMinigameToken;
    use game_components_token::structs::{TokenMetadata, Lifecycle};
    use game_components_metagame::extensions::context::structs::GameContextDetails;
    use openzeppelin_token::erc721::interface::IERC721;
    use starknet::{ContractAddress, get_caller_address};

    #[storage]
    struct Storage {}

    #[abi(embed_v0)]
    impl MinigameTokenImpl of IMinigameToken<ContractState> {
        fn token_metadata(self: @ContractState, token_id: u64) -> TokenMetadata {
            TokenMetadata {
                game_id: 1,
                minted_at: 0,
                settings_id: 0,
                lifecycle: Lifecycle { start: 0, end: 0 },
                minted_by: 0,
                soulbound: false,
                game_over: true, // Game is over
                completed_all_objectives: false,
                has_context: false,
                objectives_count: 0,
            }
        }

        fn is_playable(self: @ContractState, token_id: u64) -> bool {
            false // Game over, not playable
        }

        fn settings_id(self: @ContractState, token_id: u64) -> u32 {
            0
        }
        fn player_name(self: @ContractState, token_id: u64) -> ByteArray {
            ""
        }

        fn mint(
            ref self: ContractState,
            game_address: Option<ContractAddress>,
            player_name: Option<ByteArray>,
            settings_id: Option<u32>,
            start: Option<u64>,
            end: Option<u64>,
            objective_ids: Option<Span<u32>>,
            context: Option<GameContextDetails>,
            client_url: Option<ByteArray>,
            renderer_address: Option<ContractAddress>,
            to: ContractAddress,
            soulbound: bool,
        ) -> u64 {
            1
        }

        fn update_game(ref self: ContractState, token_id: u64) {}
    }

    // Implement IERC721 for ownership checks
    #[abi(embed_v0)]
    impl ERC721Impl of IERC721<ContractState> {
        fn owner_of(self: @ContractState, token_id: u256) -> ContractAddress {
            get_caller_address() // Return caller as owner
        }

        fn safe_transfer_from(
            ref self: ContractState,
            from: ContractAddress,
            to: ContractAddress,
            token_id: u256,
            data: Span<felt252>,
        ) {}

        fn transfer_from(
            ref self: ContractState, from: ContractAddress, to: ContractAddress, token_id: u256,
        ) {}

        fn approve(ref self: ContractState, to: ContractAddress, token_id: u256) {}

        fn set_approval_for_all(
            ref self: ContractState, operator: ContractAddress, approved: bool,
        ) {}

        fn get_approved(self: @ContractState, token_id: u256) -> ContractAddress {
            starknet::contract_address_const::<0x0>()
        }

        fn is_approved_for_all(
            self: @ContractState, owner: ContractAddress, operator: ContractAddress,
        ) -> bool {
            false
        }

        fn balance_of(self: @ContractState, account: ContractAddress) -> u256 {
            1
        }
    }
}
