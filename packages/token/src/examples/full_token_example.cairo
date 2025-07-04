//! Example implementations showing how to use the token mixin interface
//! 
//! This demonstrates two approaches:
//! 1. Full Token Contract - implements the complete IMinigameTokenABI using component composition
//! 2. Simple Token Contract - implements individual components separately

/// Full Token Contract using Mixin Interface
/// This contract implements the complete token functionality using the mixin interface
#[starknet::contract]
pub mod FullTokenContract {
    use starknet::{ContractAddress, get_caller_address};
    
    // Import the mixin interface and components
    use game_components_token::mixin::{IMinigameTokenABI, TokenMixinInitParams};
    use game_components_token::mixin::{
        TokenComponent, MultiGameComponent, TokenObjectivesComponent,
        ERC721Component, SRC5Component,
        IMINIGAME_TOKEN_ID, IMINIGAME_TOKEN_MULTIGAME_ID, IMINIGAME_TOKEN_OBJECTIVES_ID,
        IMINIGAME_TOKEN_SETTINGS_ID, IMINIGAME_TOKEN_MINTER_ID, IMINIGAME_TOKEN_SOULBOUND_ID
    };

    // Component declarations
    component!(path: TokenComponent, storage: token, event: TokenEvent);
    component!(path: MultiGameComponent, storage: multi_game, event: MultiGameEvent);
    component!(path: TokenObjectivesComponent, storage: token_objectives, event: TokenObjectivesEvent);
    component!(path: SRC5Component, storage: src5, event: SRC5Event);
    component!(path: ERC721Component, storage: erc721, event: ERC721Event);

    // Individual component implementations
    #[abi(embed_v0)]
    impl TokenImpl = TokenComponent::TokenImpl<ContractState>;
    #[abi(embed_v0)]
    impl MultiGameImpl = MultiGameComponent::MultiGameImpl<ContractState>;
    #[abi(embed_v0)]
    impl TokenObjectivesImpl = TokenObjectivesComponent::TokenObjectivesImpl<ContractState>;
    #[abi(embed_v0)]
    impl SRC5Impl = SRC5Component::SRC5Impl<ContractState>;
    #[abi(embed_v0)]
    impl ERC721Impl = ERC721Component::ERC721Impl<ContractState>;
    #[abi(embed_v0)]
    impl ERC721MetadataImpl = ERC721Component::ERC721MetadataImpl<ContractState>;

    // Internal implementations
    impl TokenInternalImpl = TokenComponent::InternalImpl<ContractState>;
    impl MultiGameInternalImpl = MultiGameComponent::InternalImpl<ContractState>;
    impl TokenObjectivesInternalImpl = TokenObjectivesComponent::InternalImpl<ContractState>;
    impl SRC5InternalImpl = SRC5Component::InternalImpl<ContractState>;
    impl ERC721InternalImpl = ERC721Component::InternalImpl<ContractState>;

    #[storage]
    struct Storage {
        #[substorage(v0)]
        token: TokenComponent::Storage,
        #[substorage(v0)]
        multi_game: MultiGameComponent::Storage,
        #[substorage(v0)]
        token_objectives: TokenObjectivesComponent::Storage,
        #[substorage(v0)]
        src5: SRC5Component::Storage,
        #[substorage(v0)]
        erc721: ERC721Component::Storage,
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        #[flat]
        TokenEvent: TokenComponent::Event,
        #[flat]
        MultiGameEvent: MultiGameComponent::Event,
        #[flat]
        TokenObjectivesEvent: TokenObjectivesComponent::Event,
        #[flat]
        SRC5Event: SRC5Component::Event,
        #[flat]
        ERC721Event: ERC721Component::Event,
    }

    #[constructor]
    fn constructor(
        ref self: ContractState,
        name: ByteArray,
        symbol: ByteArray,
        base_uri: ByteArray,
        game_address: Option<ContractAddress>,
    ) {
        // Initialize ERC721
        self.erc721.initializer(name, symbol, base_uri);

        // Register all interfaces
        self.src5.register_interface(IMINIGAME_TOKEN_ID);
        self.src5.register_interface(IMINIGAME_TOKEN_MULTIGAME_ID);
        self.src5.register_interface(IMINIGAME_TOKEN_OBJECTIVES_ID);
        self.src5.register_interface(IMINIGAME_TOKEN_SETTINGS_ID);
        self.src5.register_interface(IMINIGAME_TOKEN_MINTER_ID);
        self.src5.register_interface(IMINIGAME_TOKEN_SOULBOUND_ID);

        // Initialize components
        if let Option::Some(addr) = game_address {
            self.token.initializer(Option::Some(addr));
        }
        self.multi_game.initializer();
        self.token_objectives.initializer();
    }

    // ERC721 Hooks implementation
    impl ERC721HooksImpl of ERC721Component::ERC721HooksTrait<ContractState> {
        fn before_update(
            ref self: ERC721Component::ComponentState<ContractState>,
            to: ContractAddress,
            token_id: u256,
            auth: ContractAddress
        ) {
            // Add any pre-transfer logic here
        }

        fn after_update(
            ref self: ERC721Component::ComponentState<ContractState>,
            to: ContractAddress,
            token_id: u256,
            auth: ContractAddress
        ) {
            // Add any post-transfer logic here
        }
    }
}

/// Simple Token Contract - Individual Components
/// This shows how to use individual components without the mixin interface
#[starknet::contract]
pub mod SimpleTokenContract {
    use starknet::{ContractAddress, get_caller_address};
    
    // Core imports
    use game_components_token::token::TokenComponent;
    use game_components_token::extensions::objectives::objectives::TokenObjectivesComponent;
    use game_components_token::interface::IMinigameToken;

    // OpenZeppelin imports
    use openzeppelin_introspection::src5::SRC5Component;
    use openzeppelin_token::erc721::ERC721Component;
    use openzeppelin_token::erc721::ERC721Component::ERC721HooksTrait;

    // Component declarations
    component!(path: TokenComponent, storage: token, event: TokenEvent);
    component!(path: TokenObjectivesComponent, storage: token_objectives, event: TokenObjectivesEvent);
    component!(path: SRC5Component, storage: src5, event: SRC5Event);
    component!(path: ERC721Component, storage: erc721, event: ERC721Event);

    // Individual component implementations
    #[abi(embed_v0)]
    impl TokenImpl = TokenComponent::TokenImpl<ContractState>;
    #[abi(embed_v0)]
    impl TokenObjectivesImpl = TokenObjectivesComponent::TokenObjectivesImpl<ContractState>;
    #[abi(embed_v0)]
    impl SRC5Impl = SRC5Component::SRC5Impl<ContractState>;
    #[abi(embed_v0)]
    impl ERC721Impl = ERC721Component::ERC721Impl<ContractState>;
    #[abi(embed_v0)]
    impl ERC721MetadataImpl = ERC721Component::ERC721MetadataImpl<ContractState>;

    // Internal implementations
    impl TokenInternalImpl = TokenComponent::InternalImpl<ContractState>;
    impl TokenObjectivesInternalImpl = TokenObjectivesComponent::InternalImpl<ContractState>;
    impl SRC5InternalImpl = SRC5Component::InternalImpl<ContractState>;
    impl ERC721InternalImpl = ERC721Component::InternalImpl<ContractState>;

    #[storage]
    struct Storage {
        #[substorage(v0)]
        token: TokenComponent::Storage,
        #[substorage(v0)]
        token_objectives: TokenObjectivesComponent::Storage,
        #[substorage(v0)]
        src5: SRC5Component::Storage,
        #[substorage(v0)]
        erc721: ERC721Component::Storage,
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        #[flat]
        TokenEvent: TokenComponent::Event,
        #[flat]
        TokenObjectivesEvent: TokenObjectivesComponent::Event,
        #[flat]
        SRC5Event: SRC5Component::Event,
        #[flat]
        ERC721Event: ERC721Component::Event,
    }

    #[constructor]
    fn constructor(
        ref self: ContractState,
        name: ByteArray,
        symbol: ByteArray,
        base_uri: ByteArray,
        game_address: Option<ContractAddress>,
    ) {
        // Initialize ERC721
        self.erc721.initializer(name, symbol, base_uri);

        // Initialize token component  
        self.token.initializer(game_address);
        
        // Initialize objectives component
        self.token_objectives.initializer();
    }

    // ERC721 Hooks implementation
    impl ERC721HooksImpl of ERC721Component::ERC721HooksTrait<ContractState> {
        fn before_update(
            ref self: ERC721Component::ComponentState<ContractState>,
            to: ContractAddress,
            token_id: u256,
            auth: ContractAddress
        ) {
            // Example: Add soulbound token validation here
            // Check if token is soulbound and prevent transfers
        }

        fn after_update(
            ref self: ERC721Component::ComponentState<ContractState>,
            to: ContractAddress,
            token_id: u256,
            auth: ContractAddress
        ) {
            // Add any post-transfer logic here
        }
    }
} 