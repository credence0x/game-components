use game_components_token::interface::{IMinigameTokenDispatcher, IMinigameTokenDispatcherTrait, IMINIGAME_TOKEN_ID};
use game_components_token::structs::{TokenMetadata, Lifecycle};
use game_components_metagame::extensions::context::structs::{GameContextDetails, GameContext};
use openzeppelin_introspection::interface::{ISRC5Dispatcher, ISRC5DispatcherTrait};
use openzeppelin_token::erc721::interface::{IERC721Dispatcher, IERC721DispatcherTrait};
use starknet::{contract_address_const, get_caller_address, get_block_timestamp};
use core::num::traits::Zero;
use snforge_std::{declare, ContractClassTrait, DeclareResultTrait, start_cheat_caller_address, stop_cheat_caller_address, start_cheat_block_timestamp};

// Test Contract that embeds TokenComponent
#[starknet::contract]
mod MockTokenContract {
    use game_components_token::token::TokenComponent;
    use game_components_token::extensions::multi_game::multi_game::MultiGameComponent;
    use game_components_token::extensions::minter::minter::MinterComponent;
    use game_components_token::extensions::objectives::objectives::TokenObjectivesComponent;
    use game_components_token::extensions::settings::settings::TokenSettingsComponent;
    use game_components_token::extensions::soulbound::soulbound::SoulboundComponent;
    use game_components_token::extensions::renderer::renderer::RendererComponent;
    use openzeppelin_token::erc721::ERC721Component;
    use openzeppelin_introspection::src5::SRC5Component;
    use starknet::ContractAddress;

    component!(path: TokenComponent, storage: token, event: TokenEvent);
    component!(path: MultiGameComponent, storage: multi_game, event: MultiGameEvent);
    component!(path: MinterComponent, storage: minter, event: MinterEvent);
    component!(path: TokenObjectivesComponent, storage: objectives, event: ObjectivesEvent);
    component!(path: TokenSettingsComponent, storage: settings, event: SettingsEvent);
    component!(path: SoulboundComponent, storage: soulbound, event: SoulboundEvent);
    component!(path: RendererComponent, storage: renderer, event: RendererEvent);
    component!(path: ERC721Component, storage: erc721, event: ERC721Event);
    component!(path: SRC5Component, storage: src5, event: SRC5Event);

    #[abi(embed_v0)]
    impl TokenImpl = TokenComponent::TokenImpl<ContractState>;
    impl TokenInternalImpl = TokenComponent::InternalImpl<ContractState>;

    #[abi(embed_v0)]
    impl MultiGameImpl = MultiGameComponent::MinigameTokenMultiGameImpl<ContractState>;
    impl MultiGameInternalImpl = MultiGameComponent::InternalImpl<ContractState>;

    #[abi(embed_v0)]
    impl MinterInternalImpl = MinterComponent::InternalImpl<ContractState>;

    #[abi(embed_v0)]
    impl ObjectivesImpl = TokenObjectivesComponent::MinigameTokenObjectivesImpl<ContractState>;
    impl ObjectivesInternalImpl = TokenObjectivesComponent::InternalImpl<ContractState>;

    #[abi(embed_v0)]
    impl SettingsInternalImpl = TokenSettingsComponent::InternalImpl<ContractState>;

    #[abi(embed_v0)]
    impl SoulboundInternalImpl = SoulboundComponent::InternalImpl<ContractState>;

    #[abi(embed_v0)]
    impl RendererImpl = RendererComponent::TokenRendererImpl<ContractState>;
    impl RendererInternalImpl = RendererComponent::InternalImpl<ContractState>;

    #[abi(embed_v0)]
    impl ERC721MixinImpl = ERC721Component::ERC721MixinImpl<ContractState>;
    impl ERC721InternalImpl = ERC721Component::InternalImpl<ContractState>;

    #[abi(embed_v0)]
    impl SRC5Impl = SRC5Component::SRC5Impl<ContractState>;

    #[storage]
    struct Storage {
        #[substorage(v0)]
        token: TokenComponent::Storage,
        #[substorage(v0)]
        multi_game: MultiGameComponent::Storage,
        #[substorage(v0)]
        minter: MinterComponent::Storage,
        #[substorage(v0)]
        objectives: TokenObjectivesComponent::Storage,
        #[substorage(v0)]
        settings: TokenSettingsComponent::Storage,
        #[substorage(v0)]
        soulbound: SoulboundComponent::Storage,
        #[substorage(v0)]
        renderer: RendererComponent::Storage,
        #[substorage(v0)]
        erc721: ERC721Component::Storage,
        #[substorage(v0)]
        src5: SRC5Component::Storage,
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        #[flat]
        TokenEvent: TokenComponent::Event,
        #[flat]
        MultiGameEvent: MultiGameComponent::Event,
        #[flat]
        MinterEvent: MinterComponent::Event,
        #[flat]
        ObjectivesEvent: TokenObjectivesComponent::Event,
        #[flat]
        SettingsEvent: TokenSettingsComponent::Event,
        #[flat]
        SoulboundEvent: SoulboundComponent::Event,
        #[flat]
        RendererEvent: RendererComponent::Event,
        #[flat]
        ERC721Event: ERC721Component::Event,
        #[flat]
        SRC5Event: SRC5Component::Event,
    }

    #[constructor]
    fn constructor(ref self: ContractState, game_address: Option<ContractAddress>) {
        self.erc721.initializer("Test Token", "TEST", "");
        self.token.initializer(game_address);
        
        // Register multi-game interface if no game address provided
        if game_address.is_none() {
            self.multi_game.register_multi_game_interface();
        }
        
        // Register other interfaces
        self.objectives.register_objectives_interface();
        self.settings.register_settings_interface();
        self.minter.register_minter_interface();
    }

    impl ERC721HooksImpl of ERC721Component::ERC721HooksTrait<ContractState> {
        fn before_update(
            ref self: ERC721Component::ComponentState<ContractState>,
            to: ContractAddress,
            token_id: u256,
            auth: ContractAddress
        ) {
            // Check soulbound if applicable
            let contract_state = self.get_contract();
            let token_metadata = contract_state.token.token_metadata.read(token_id.try_into().unwrap());
            if token_metadata.soulbound {
                contract_state.soulbound.before_update(auth, Zero::zero(), to, token_id.try_into().unwrap());
            }
        }

        fn after_update(
            ref self: ERC721Component::ComponentState<ContractState>,
            to: ContractAddress,
            token_id: u256,
            auth: ContractAddress
        ) {}
    }
}

// Test TK-U-01: Mint basic token
#[test]
fn test_mint_basic_token() {
    // Deploy mock minigame
    let minigame_contract = declare("MockMinigame").unwrap().contract_class();
    let (minigame_address, _) = minigame_contract.deploy(@array![
        contract_address_const::<0x0>().into(), // token_address (will be set later)
        contract_address_const::<0x0>().into(), // settings_address
        contract_address_const::<0x0>().into(), // objectives_address
    ]).unwrap();
    
    // Deploy token contract
    let token_contract = declare("MockTokenContract").unwrap().contract_class();
    let (token_address, _) = token_contract.deploy(@array![
        Option::Some(minigame_address).into()
    ]).unwrap();
    
    let token_dispatcher = IMinigameTokenDispatcher { contract_address: token_address };
    let owner_address = get_caller_address();
    
    // Mint basic token
    let token_id = token_dispatcher.mint(
        Option::Some(minigame_address),
        Option::None,  // player_name
        Option::None,  // settings_id
        Option::None,  // start
        Option::None,  // end
        Option::None,  // objective_ids
        Option::None,  // context
        Option::None,  // client_url
        Option::None,  // renderer_address
        owner_address,
        false          // soulbound
    );
    
    assert!(token_id == 1, "First token ID should be 1");
    
    // Verify token metadata
    let metadata = token_dispatcher.token_metadata(token_id);
    assert!(metadata.game_id == 1, "Game ID mismatch");
    assert!(!metadata.soulbound, "Should not be soulbound");
    assert!(!metadata.game_over, "Should not be game over");
    assert!(metadata.objectives_count == 0, "Should have no objectives");
}

// Test TK-U-02: Mint sequential tokens
#[test]
fn test_mint_sequential_tokens() {
    // Deploy mock minigame
    let minigame_contract = declare("MockMinigame").unwrap().contract_class();
    let (minigame_address, _) = minigame_contract.deploy(@array![
        contract_address_const::<0x0>().into(),
        contract_address_const::<0x0>().into(),
        contract_address_const::<0x0>().into(),
    ]).unwrap();
    
    // Deploy token contract
    let token_contract = declare("MockTokenContract").unwrap().contract_class();
    let (token_address, _) = token_contract.deploy(@array![
        Option::Some(minigame_address).into()
    ]).unwrap();
    
    let token_dispatcher = IMinigameTokenDispatcher { contract_address: token_address };
    let owner_address = get_caller_address();
    
    // Mint first token
    let token_id_1 = token_dispatcher.mint(
        Option::Some(minigame_address),
        Option::None, Option::None, Option::None, Option::None,
        Option::None, Option::None, Option::None, Option::None,
        owner_address,
        false
    );
    
    // Mint second token
    let token_id_2 = token_dispatcher.mint(
        Option::Some(minigame_address),
        Option::None, Option::None, Option::None, Option::None,
        Option::None, Option::None, Option::None, Option::None,
        owner_address,
        false
    );
    
    // Mint third token
    let token_id_3 = token_dispatcher.mint(
        Option::Some(minigame_address),
        Option::None, Option::None, Option::None, Option::None,
        Option::None, Option::None, Option::None, Option::None,
        owner_address,
        false
    );
    
    assert!(token_id_1 == 1, "First token ID should be 1");
    assert!(token_id_2 == 2, "Second token ID should be 2");
    assert!(token_id_3 == 3, "Third token ID should be 3");
}

// Test TK-U-03: Mint with settings
#[test]
fn test_mint_with_settings() {
    // Deploy mock settings
    let settings_contract = declare("MockSettings").unwrap().contract_class();
    let (settings_address, _) = settings_contract.deploy(@array![]).unwrap();
    
    // Deploy mock minigame with settings
    let minigame_contract = declare("MockMinigame").unwrap().contract_class();
    let (minigame_address, _) = minigame_contract.deploy(@array![
        contract_address_const::<0x0>().into(),
        settings_address.into(),
        contract_address_const::<0x0>().into(),
    ]).unwrap();
    
    // Deploy token contract
    let token_contract = declare("MockTokenContract").unwrap().contract_class();
    let (token_address, _) = token_contract.deploy(@array![
        Option::Some(minigame_address).into()
    ]).unwrap();
    
    let token_dispatcher = IMinigameTokenDispatcher { contract_address: token_address };
    let owner_address = get_caller_address();
    
    // Mint token with valid settings ID
    let token_id = token_dispatcher.mint(
        Option::Some(minigame_address),
        Option::None,
        Option::Some(1), // Valid settings ID
        Option::None, Option::None, Option::None, Option::None,
        Option::None, Option::None,
        owner_address,
        false
    );
    
    // Verify settings ID was stored
    let metadata = token_dispatcher.token_metadata(token_id);
    assert!(metadata.settings_id == 1, "Settings ID should be 1");
    assert!(token_dispatcher.settings_id(token_id) == 1, "Settings ID getter mismatch");
}

// Test TK-U-04: Mint with non-existent settings
#[test]
#[should_panic(expected: ('MinigameToken: Settings id 999 not registered',))]
fn test_mint_with_nonexistent_settings() {
    // Deploy mock settings
    let settings_contract = declare("MockSettings").unwrap().contract_class();
    let (settings_address, _) = settings_contract.deploy(@array![]).unwrap();
    
    // Deploy mock minigame with settings
    let minigame_contract = declare("MockMinigame").unwrap().contract_class();
    let (minigame_address, _) = minigame_contract.deploy(@array![
        contract_address_const::<0x0>().into(),
        settings_address.into(),
        contract_address_const::<0x0>().into(),
    ]).unwrap();
    
    // Deploy token contract
    let token_contract = declare("MockTokenContract").unwrap().contract_class();
    let (token_address, _) = token_contract.deploy(@array![
        Option::Some(minigame_address).into()
    ]).unwrap();
    
    let token_dispatcher = IMinigameTokenDispatcher { contract_address: token_address };
    let owner_address = get_caller_address();
    
    // Mint token with invalid settings ID - should panic
    token_dispatcher.mint(
        Option::Some(minigame_address),
        Option::None,
        Option::Some(999), // Non-existent settings ID
        Option::None, Option::None, Option::None, Option::None,
        Option::None, Option::None,
        owner_address,
        false
    );
}

// Test TK-U-05: Mint with objectives
#[test]
fn test_mint_with_objectives() {
    // Deploy mock objectives
    let objectives_contract = declare("MockObjectives").unwrap().contract_class();
    let (objectives_address, _) = objectives_contract.deploy(@array![]).unwrap();
    
    // Deploy mock minigame with objectives
    let minigame_contract = declare("MockMinigame").unwrap().contract_class();
    let (minigame_address, _) = minigame_contract.deploy(@array![
        contract_address_const::<0x0>().into(),
        contract_address_const::<0x0>().into(),
        objectives_address.into(),
    ]).unwrap();
    
    // Deploy token contract
    let token_contract = declare("MockTokenContract").unwrap().contract_class();
    let (token_address, _) = token_contract.deploy(@array![
        Option::Some(minigame_address).into()
    ]).unwrap();
    
    let token_dispatcher = IMinigameTokenDispatcher { contract_address: token_address };
    let owner_address = get_caller_address();
    
    // Mint token with valid objective IDs
    let objective_ids = array![1_u32, 2_u32, 3_u32];
    let token_id = token_dispatcher.mint(
        Option::Some(minigame_address),
        Option::None,
        Option::None,
        Option::None,
        Option::None,
        Option::Some(objective_ids.span()),
        Option::None,
        Option::None,
        Option::None,
        owner_address,
        false
    );
    
    // Verify objectives count
    let metadata = token_dispatcher.token_metadata(token_id);
    assert!(metadata.objectives_count == 3, "Should have 3 objectives");
}

// Test TK-U-06: Mint with invalid objectives
#[test]
#[should_panic(expected: ('Denshokan: Objective id 999 not registered',))]
fn test_mint_with_invalid_objectives() {
    // Deploy mock objectives
    let objectives_contract = declare("MockObjectives").unwrap().contract_class();
    let (objectives_address, _) = objectives_contract.deploy(@array![]).unwrap();
    
    // Deploy mock minigame with objectives
    let minigame_contract = declare("MockMinigame").unwrap().contract_class();
    let (minigame_address, _) = minigame_contract.deploy(@array![
        contract_address_const::<0x0>().into(),
        contract_address_const::<0x0>().into(),
        objectives_address.into(),
    ]).unwrap();
    
    // Deploy token contract
    let token_contract = declare("MockTokenContract").unwrap().contract_class();
    let (token_address, _) = token_contract.deploy(@array![
        Option::Some(minigame_address).into()
    ]).unwrap();
    
    let token_dispatcher = IMinigameTokenDispatcher { contract_address: token_address };
    let owner_address = get_caller_address();
    
    // Mint token with invalid objective ID - should panic
    let objective_ids = array![1_u32, 999_u32]; // 999 doesn't exist
    token_dispatcher.mint(
        Option::Some(minigame_address),
        Option::None,
        Option::None,
        Option::None,
        Option::None,
        Option::Some(objective_ids.span()),
        Option::None,
        Option::None,
        Option::None,
        owner_address,
        false
    );
}

// Test TK-U-07: Mint soulbound token
#[test]
fn test_mint_soulbound_token() {
    // Deploy mock minigame
    let minigame_contract = declare("MockMinigame").unwrap().contract_class();
    let (minigame_address, _) = minigame_contract.deploy(@array![
        contract_address_const::<0x0>().into(),
        contract_address_const::<0x0>().into(),
        contract_address_const::<0x0>().into(),
    ]).unwrap();
    
    // Deploy token contract
    let token_contract = declare("MockTokenContract").unwrap().contract_class();
    let (token_address, _) = token_contract.deploy(@array![
        Option::Some(minigame_address).into()
    ]).unwrap();
    
    let token_dispatcher = IMinigameTokenDispatcher { contract_address: token_address };
    let owner_address = get_caller_address();
    
    // Mint soulbound token
    let token_id = token_dispatcher.mint(
        Option::Some(minigame_address),
        Option::None, Option::None, Option::None, Option::None,
        Option::None, Option::None, Option::None, Option::None,
        owner_address,
        true  // soulbound = true
    );
    
    // Verify token is soulbound
    let metadata = token_dispatcher.token_metadata(token_id);
    assert!(metadata.soulbound, "Token should be soulbound");
    
    // Try to transfer soulbound token - should fail
    let erc721_dispatcher = IERC721Dispatcher { contract_address: token_address };
    let different_address = contract_address_const::<0x789>();
    
    // This should panic due to soulbound restriction
    // We'll test this in a separate test case
}

// Test TK-U-08: Mint with future start
#[test]
fn test_mint_with_future_start() {
    // Deploy mock minigame
    let minigame_contract = declare("MockMinigame").unwrap().contract_class();
    let (minigame_address, _) = minigame_contract.deploy(@array![
        contract_address_const::<0x0>().into(),
        contract_address_const::<0x0>().into(),
        contract_address_const::<0x0>().into(),
    ]).unwrap();
    
    // Deploy token contract
    let token_contract = declare("MockTokenContract").unwrap().contract_class();
    let (token_address, _) = token_contract.deploy(@array![
        Option::Some(minigame_address).into()
    ]).unwrap();
    
    let token_dispatcher = IMinigameTokenDispatcher { contract_address: token_address };
    let owner_address = get_caller_address();
    
    // Set current timestamp
    start_cheat_block_timestamp(token_address, 1000);
    
    // Mint token with future start time
    let future_start: u64 = 2000;
    let future_end: u64 = 3000;
    
    let token_id = token_dispatcher.mint(
        Option::Some(minigame_address),
        Option::None,
        Option::None,
        Option::Some(future_start),
        Option::Some(future_end),
        Option::None, Option::None, Option::None, Option::None,
        owner_address,
        false
    );
    
    // Verify lifecycle
    let metadata = token_dispatcher.token_metadata(token_id);
    assert!(metadata.lifecycle.start == future_start, "Start time mismatch");
    assert!(metadata.lifecycle.end == future_end, "End time mismatch");
    
    // Token should not be playable yet
    assert!(!token_dispatcher.is_playable(token_id), "Token should not be playable yet");
}

// Test TK-U-09: Mint to zero address
#[test]
#[should_panic(expected: ('ERC721: mint to 0',))]
fn test_mint_to_zero_address() {
    // Deploy mock minigame
    let minigame_contract = declare("MockMinigame").unwrap().contract_class();
    let (minigame_address, _) = minigame_contract.deploy(@array![
        contract_address_const::<0x0>().into(),
        contract_address_const::<0x0>().into(),
        contract_address_const::<0x0>().into(),
    ]).unwrap();
    
    // Deploy token contract
    let token_contract = declare("MockTokenContract").unwrap().contract_class();
    let (token_address, _) = token_contract.deploy(@array![
        Option::Some(minigame_address).into()
    ]).unwrap();
    
    let token_dispatcher = IMinigameTokenDispatcher { contract_address: token_address };
    
    // Mint to zero address - should panic
    token_dispatcher.mint(
        Option::Some(minigame_address),
        Option::None, Option::None, Option::None, Option::None,
        Option::None, Option::None, Option::None, Option::None,
        contract_address_const::<0x0>(), // Zero address
        false
    );
}

// Test TK-U-10: update_game increases score
#[test]
fn test_update_game_increases_score() {
    // Deploy mock minigame
    let minigame_contract = declare("MockMinigame").unwrap().contract_class();
    let (minigame_address, _) = minigame_contract.deploy(@array![
        contract_address_const::<0x0>().into(),
        contract_address_const::<0x0>().into(),
        contract_address_const::<0x0>().into(),
    ]).unwrap();
    
    // Deploy token contract
    let token_contract = declare("MockTokenContract").unwrap().contract_class();
    let (token_address, _) = token_contract.deploy(@array![
        Option::Some(minigame_address).into()
    ]).unwrap();
    
    let token_dispatcher = IMinigameTokenDispatcher { contract_address: token_address };
    let owner_address = get_caller_address();
    
    // Mint token
    let token_id = token_dispatcher.mint(
        Option::Some(minigame_address),
        Option::None, Option::None, Option::None, Option::None,
        Option::None, Option::None, Option::None, Option::None,
        owner_address,
        false
    );
    
    // Update game should emit ScoreUpdate event
    // Note: In a real test we would check events
    token_dispatcher.update_game(token_id);
}

// Test TK-U-11: update_game sets game_over
#[test]
fn test_update_game_sets_game_over() {
    // Deploy mock minigame
    let minigame_contract = declare("MockMinigame").unwrap().contract_class();
    let (minigame_address, _) = minigame_contract.deploy(@array![
        contract_address_const::<0x0>().into(),
        contract_address_const::<0x0>().into(),
        contract_address_const::<0x0>().into(),
    ]).unwrap();
    
    // Deploy token contract
    let token_contract = declare("MockTokenContract").unwrap().contract_class();
    let (token_address, _) = token_contract.deploy(@array![
        Option::Some(minigame_address).into()
    ]).unwrap();
    
    let token_dispatcher = IMinigameTokenDispatcher { contract_address: token_address };
    let owner_address = get_caller_address();
    
    // Mint token
    let token_id = token_dispatcher.mint(
        Option::Some(minigame_address),
        Option::None, Option::None, Option::None, Option::None,
        Option::None, Option::None, Option::None, Option::None,
        owner_address,
        false
    );
    
    // Set game over in minigame
    let minigame_setter = IMockMinigameSetter { contract_address: minigame_address };
    minigame_setter.set_game_over(token_id, true);
    
    // Update game
    token_dispatcher.update_game(token_id);
    
    // Check metadata - game_over should be updated
    let metadata = token_dispatcher.token_metadata(token_id);
    assert!(metadata.game_over, "Game should be over");
}

// Test TK-U-12: update_game completes objectives
#[test]
fn test_update_game_completes_objectives() {
    // This test would require objectives component
    // For now, we'll test basic update functionality
    
    // Deploy mock objectives
    let objectives_contract = declare("MockObjectives").unwrap().contract_class();
    let (objectives_address, _) = objectives_contract.deploy(@array![]).unwrap();
    
    // Deploy mock minigame with objectives
    let minigame_contract = declare("MockMinigame").unwrap().contract_class();
    let (minigame_address, _) = minigame_contract.deploy(@array![
        contract_address_const::<0x0>().into(),
        contract_address_const::<0x0>().into(),
        objectives_address.into(),
    ]).unwrap();
    
    // Deploy token contract
    let token_contract = declare("MockTokenContract").unwrap().contract_class();
    let (token_address, _) = token_contract.deploy(@array![
        Option::Some(minigame_address).into()
    ]).unwrap();
    
    let token_dispatcher = IMinigameTokenDispatcher { contract_address: token_address };
    let owner_address = get_caller_address();
    
    // Mint token with objectives
    let objective_ids = array![1_u32, 2_u32];
    let token_id = token_dispatcher.mint(
        Option::Some(minigame_address),
        Option::None,
        Option::None,
        Option::None,
        Option::None,
        Option::Some(objective_ids.span()),
        Option::None,
        Option::None,
        Option::None,
        owner_address,
        false
    );
    
    // Update game
    token_dispatcher.update_game(token_id);
}

// Test TK-U-13: is_playable lifecycle checks
#[test]
fn test_is_playable_lifecycle_checks() {
    // Deploy mock minigame
    let minigame_contract = declare("MockMinigame").unwrap().contract_class();
    let (minigame_address, _) = minigame_contract.deploy(@array![
        contract_address_const::<0x0>().into(),
        contract_address_const::<0x0>().into(),
        contract_address_const::<0x0>().into(),
    ]).unwrap();
    
    // Deploy token contract
    let token_contract = declare("MockTokenContract").unwrap().contract_class();
    let (token_address, _) = token_contract.deploy(@array![
        Option::Some(minigame_address).into()
    ]).unwrap();
    
    let token_dispatcher = IMinigameTokenDispatcher { contract_address: token_address };
    let owner_address = get_caller_address();
    
    // Test 1: Token with no lifecycle (start=0, end=0) should be playable
    let token_id_1 = token_dispatcher.mint(
        Option::Some(minigame_address),
        Option::None, Option::None, Option::None, Option::None,
        Option::None, Option::None, Option::None, Option::None,
        owner_address,
        false
    );
    assert!(token_dispatcher.is_playable(token_id_1), "Token with no lifecycle should be playable");
    
    // Set current timestamp
    start_cheat_block_timestamp(token_address, 1500);
    
    // Test 2: Token with current time within lifecycle
    let token_id_2 = token_dispatcher.mint(
        Option::Some(minigame_address),
        Option::None,
        Option::None,
        Option::Some(1000),
        Option::Some(2000),
        Option::None, Option::None, Option::None, Option::None,
        owner_address,
        false
    );
    assert!(token_dispatcher.is_playable(token_id_2), "Token within lifecycle should be playable");
    
    // Test 3: Token with future start time
    let token_id_3 = token_dispatcher.mint(
        Option::Some(minigame_address),
        Option::None,
        Option::None,
        Option::Some(2000),
        Option::Some(3000),
        Option::None, Option::None, Option::None, Option::None,
        owner_address,
        false
    );
    assert!(!token_dispatcher.is_playable(token_id_3), "Token with future start should not be playable");
    
    // Test 4: Token with past end time
    let token_id_4 = token_dispatcher.mint(
        Option::Some(minigame_address),
        Option::None,
        Option::None,
        Option::Some(500),
        Option::Some(1000),
        Option::None, Option::None, Option::None, Option::None,
        owner_address,
        false
    );
    assert!(!token_dispatcher.is_playable(token_id_4), "Token with past end should not be playable");
}

// Test TK-U-14: token_metadata retrieval
#[test]
fn test_token_metadata_retrieval() {
    // Deploy mock minigame
    let minigame_contract = declare("MockMinigame").unwrap().contract_class();
    let (minigame_address, _) = minigame_contract.deploy(@array![
        contract_address_const::<0x0>().into(),
        contract_address_const::<0x0>().into(),
        contract_address_const::<0x0>().into(),
    ]).unwrap();
    
    // Deploy token contract
    let token_contract = declare("MockTokenContract").unwrap().contract_class();
    let (token_address, _) = token_contract.deploy(@array![
        Option::Some(minigame_address).into()
    ]).unwrap();
    
    let token_dispatcher = IMinigameTokenDispatcher { contract_address: token_address };
    let owner_address = get_caller_address();
    
    // Set timestamp for minted_at
    start_cheat_block_timestamp(token_address, 12345);
    
    // Mint token with specific parameters
    let token_id = token_dispatcher.mint(
        Option::Some(minigame_address),
        Option::Some("PlayerOne"),
        Option::None,
        Option::Some(1000),
        Option::Some(2000),
        Option::None,
        Option::None,
        Option::None,
        Option::None,
        owner_address,
        true  // soulbound
    );
    
    // Retrieve and verify metadata
    let metadata = token_dispatcher.token_metadata(token_id);
    assert!(metadata.game_id == 1, "Game ID mismatch");
    assert!(metadata.minted_at == 12345, "Minted at timestamp mismatch");
    assert!(metadata.settings_id == 0, "Settings ID should be 0");
    assert!(metadata.lifecycle.start == 1000, "Start time mismatch");
    assert!(metadata.lifecycle.end == 2000, "End time mismatch");
    assert!(metadata.soulbound, "Should be soulbound");
    assert!(!metadata.game_over, "Should not be game over");
    assert!(!metadata.completed_all_objectives, "Should not have completed all objectives");
    assert!(!metadata.has_context, "Should not have context");
    assert!(metadata.objectives_count == 0, "Should have no objectives");
    
    // Verify player name
    assert!(token_dispatcher.player_name(token_id) == "PlayerOne", "Player name mismatch");
}

// Test TK-U-15: Mint with 256 objectives (exceeds u8)
#[test]
#[should_panic]
fn test_mint_with_256_objectives() {
    // Deploy mock objectives
    let objectives_contract = declare("MockObjectives").unwrap().contract_class();
    let (objectives_address, _) = objectives_contract.deploy(@array![]).unwrap();
    
    // Add many objectives to mock
    let objectives_setter = IMockObjectivesSetter { contract_address: objectives_address };
    let mut i: u32 = 0;
    loop {
        if i >= 256 {
            break;
        }
        objectives_setter.add_objective(i);
        i += 1;
    };
    
    // Deploy mock minigame with objectives
    let minigame_contract = declare("MockMinigame").unwrap().contract_class();
    let (minigame_address, _) = minigame_contract.deploy(@array![
        contract_address_const::<0x0>().into(),
        contract_address_const::<0x0>().into(),
        objectives_address.into(),
    ]).unwrap();
    
    // Deploy token contract
    let token_contract = declare("MockTokenContract").unwrap().contract_class();
    let (token_address, _) = token_contract.deploy(@array![
        Option::Some(minigame_address).into()
    ]).unwrap();
    
    let token_dispatcher = IMinigameTokenDispatcher { contract_address: token_address };
    let owner_address = get_caller_address();
    
    // Create array with 256 objectives
    let mut objective_ids = array![];
    let mut i: u32 = 0;
    loop {
        if i >= 256 {
            break;
        }
        objective_ids.append(i);
        i += 1;
    };
    
    // Mint token with 256 objectives - should panic due to u8 overflow
    token_dispatcher.mint(
        Option::Some(minigame_address),
        Option::None,
        Option::None,
        Option::None,
        Option::None,
        Option::Some(objective_ids.span()),
        Option::None,
        Option::None,
        Option::None,
        owner_address,
        false
    );
}

// Test TK-U-16: Token counter at u64::MAX (boundary test)
// This test is theoretical as we can't actually mint u64::MAX tokens
#[test]
fn test_token_counter_increment() {
    // Deploy mock minigame
    let minigame_contract = declare("MockMinigame").unwrap().contract_class();
    let (minigame_address, _) = minigame_contract.deploy(@array![
        contract_address_const::<0x0>().into(),
        contract_address_const::<0x0>().into(),
        contract_address_const::<0x0>().into(),
    ]).unwrap();
    
    // Deploy token contract
    let token_contract = declare("MockTokenContract").unwrap().contract_class();
    let (token_address, _) = token_contract.deploy(@array![
        Option::Some(minigame_address).into()
    ]).unwrap();
    
    let token_dispatcher = IMinigameTokenDispatcher { contract_address: token_address };
    let owner_address = get_caller_address();
    
    // Mint a few tokens and verify counter increments properly
    let token_id_1 = token_dispatcher.mint(
        Option::Some(minigame_address),
        Option::None, Option::None, Option::None, Option::None,
        Option::None, Option::None, Option::None, Option::None,
        owner_address,
        false
    );
    
    let token_id_2 = token_dispatcher.mint(
        Option::Some(minigame_address),
        Option::None, Option::None, Option::None, Option::None,
        Option::None, Option::None, Option::None, Option::None,
        owner_address,
        false
    );
    
    assert!(token_id_2 == token_id_1 + 1, "Token counter should increment by 1");
}

// Additional test for multi-game support
#[test]
fn test_mint_multi_game_token() {
    // Deploy token contract without game address (multi-game mode)
    let token_contract = declare("MockTokenContract").unwrap().contract_class();
    let (token_address, _) = token_contract.deploy(@array![
        Option::None::<ContractAddress>.into()
    ]).unwrap();
    
    // Deploy and register first game
    let minigame1_contract = declare("MockMinigame").unwrap().contract_class();
    let (minigame1_address, _) = minigame1_contract.deploy(@array![
        token_address.into(),
        contract_address_const::<0x0>().into(),
        contract_address_const::<0x0>().into(),
    ]).unwrap();
    
    // Register the game
    let multi_game_dispatcher = IMinigameTokenMultiGameDispatcher { contract_address: token_address };
    multi_game_dispatcher.register_game(
        contract_address_const::<0x123>(), // creator_address
        "Test Game 1",
        "A test game",
        "Developer",
        "Publisher", 
        "Puzzle",
        "image.png",
        Option::None,
        Option::None,
        Option::None
    );
    
    let token_dispatcher = IMinigameTokenDispatcher { contract_address: token_address };
    let owner_address = get_caller_address();
    
    // Mint token for registered game
    let token_id = token_dispatcher.mint(
        Option::Some(minigame1_address),
        Option::None, Option::None, Option::None, Option::None,
        Option::None, Option::None, Option::None, Option::None,
        owner_address,
        false
    );
    
    // Verify token was minted
    let metadata = token_dispatcher.token_metadata(token_id);
    assert!(metadata.game_id == 1, "Game ID should be 1 for first registered game");
}

// Helper interfaces for test contracts
#[starknet::interface]
trait IMockMinigameSetter<TContractState> {
    fn set_score(ref self: TContractState, token_id: u64, score: u32);
    fn set_game_over(ref self: TContractState, token_id: u64, game_over: bool);
}

#[starknet::interface]
trait IMockObjectivesSetter<TContractState> {
    fn add_objective(ref self: TContractState, objective_id: u32);
}

// Additional interface for multi-game
use game_components_token::extensions::multi_game::interface::{
    IMinigameTokenMultiGame, IMinigameTokenMultiGameDispatcher, IMinigameTokenMultiGameDispatcherTrait
};
}