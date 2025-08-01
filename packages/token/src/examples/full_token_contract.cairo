// Example: Optimized Token Contract using the new component system
// This demonstrates how to configure and use the modular components

use core::num::traits::Zero;
use starknet::{ContractAddress, syscalls::call_contract_syscall};
use starknet::storage::{StoragePointerReadAccess};

// Core imports
use openzeppelin_token::erc721::{ERC721Component, interface::IERC721Metadata};
use openzeppelin_introspection::src5::SRC5Component;

// Game components imports
use crate::core::core_token::CoreTokenComponent;
use crate::structs::TokenMetadata;
use crate::extensions::minter::minter::MinterComponent;
use crate::extensions::objectives::objectives::ObjectivesComponent;
use crate::extensions::context::context::ContextComponent;
use crate::extensions::renderer::renderer::RendererComponent;
use crate::extensions::settings::settings::SettingsComponent;

use crate::examples::minigame_registry_contract::{
    IMinigameRegistryDispatcher, IMinigameRegistryDispatcherTrait,
};

use crate::interface::{ITokenEventRelayerDispatcher, ITokenEventRelayerDispatcherTrait};

use game_components_minigame::structs::GameDetail;
use game_components_utils::renderer::create_custom_metadata;


#[starknet::contract]
pub mod FullTokenContract {
    use super::*;

    // ================================================================================================
    // COMPONENT DECLARATIONS
    // ================================================================================================

    // Core components (always included)
    component!(path: ERC721Component, storage: erc721, event: ERC721Event);
    component!(path: SRC5Component, storage: src5, event: SRC5Event);
    component!(path: CoreTokenComponent, storage: core_token, event: CoreTokenEvent);

    // Optional components (only included if enabled)
    component!(path: MinterComponent, storage: minter, event: MinterEvent);
    component!(path: ObjectivesComponent, storage: objectives, event: ObjectivesEvent);
    component!(path: SettingsComponent, storage: settings, event: SettingsEvent);
    component!(path: ContextComponent, storage: context, event: ContextEvent);
    component!(path: RendererComponent, storage: renderer, event: RendererEvent);

    // ================================================================================================
    // STORAGE
    // ================================================================================================

    #[storage]
    struct Storage {
        // Core storage (always included)
        #[substorage(v0)]
        erc721: ERC721Component::Storage,
        #[substorage(v0)]
        src5: SRC5Component::Storage,
        #[substorage(v0)]
        core_token: CoreTokenComponent::Storage,
        // Optional storage (only included if features are enabled)
        #[substorage(v0)]
        minter: MinterComponent::Storage,
        #[substorage(v0)]
        objectives: ObjectivesComponent::Storage,
        #[substorage(v0)]
        settings: SettingsComponent::Storage,
        #[substorage(v0)]
        context: ContextComponent::Storage,
        #[substorage(v0)]
        renderer: RendererComponent::Storage,
    }

    // ================================================================================================
    // EVENTS
    // ================================================================================================

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        #[flat]
        ERC721Event: ERC721Component::Event,
        #[flat]
        SRC5Event: SRC5Component::Event,
        #[flat]
        CoreTokenEvent: CoreTokenComponent::Event,
        #[flat]
        MinterEvent: MinterComponent::Event,
        #[flat]
        ObjectivesEvent: ObjectivesComponent::Event,
        #[flat]
        SettingsEvent: SettingsComponent::Event,
        #[flat]
        ContextEvent: ContextComponent::Event,
        #[flat]
        RendererEvent: RendererComponent::Event,
    }

    // ================================================================================================
    // COMPONENT IMPLEMENTATIONS
    // ================================================================================================

    // Core implementations (always included)
    #[abi(embed_v0)]
    impl ERC721Impl = ERC721Component::ERC721Impl<ContractState>;
    #[abi(embed_v0)]
    impl SRC5Impl = SRC5Component::SRC5Impl<ContractState>;
    #[abi(embed_v0)]
    impl CoreTokenImpl = CoreTokenComponent::CoreTokenImpl<ContractState>;

    // Optional implementations (conditional based on feature flags)
    #[abi(embed_v0)]
    impl MinterImpl = MinterComponent::MinterImpl<ContractState>;
    #[abi(embed_v0)]
    impl ObjectivesImpl = ObjectivesComponent::ObjectivesImpl<ContractState>;
    #[abi(embed_v0)]
    impl SettingsImpl = SettingsComponent::SettingsImpl<ContractState>;
    #[abi(embed_v0)]
    impl RendererImpl = RendererComponent::RendererImpl<ContractState>;

    // Internal implementations
    impl ERC721InternalImpl = ERC721Component::InternalImpl<ContractState>;
    impl SRC5InternalImpl = SRC5Component::InternalImpl<ContractState>;
    impl CoreTokenInternalImpl = CoreTokenComponent::InternalImpl<ContractState>;
    impl MinterInternalImpl = MinterComponent::InternalImpl<ContractState>;
    impl ObjectivesInternalImpl = ObjectivesComponent::InternalImpl<ContractState>;
    impl SettingsInternalImpl = SettingsComponent::InternalImpl<ContractState>;
    impl ContextInternalImpl = ContextComponent::InternalImpl<ContractState>;
    impl RendererInternalImpl = RendererComponent::InternalImpl<ContractState>;

    // ================================================================================================
    // OPTIONAL TRAIT IMPLEMENTATIONS
    // ================================================================================================

    // These implementations are chosen based on compile-time feature flags
    // If a feature is disabled, the NoOp implementation is used (zero runtime cost)

    impl MinterOptionalImpl = MinterComponent::MinterOptionalImpl<ContractState>;
    impl ObjectivesOptionalImpl = ObjectivesComponent::ObjectivesOptionalImpl<ContractState>;
    impl SettingsOptionalImpl = SettingsComponent::SettingsOptionalImpl<ContractState>;
    impl ContextOptionalImpl = ContextComponent::ContextOptionalImpl<ContractState>;
    impl RendererOptionalImpl = RendererComponent::RendererOptionalImpl<ContractState>;

    // Alternative: Use NoOp implementations for disabled features
    // impl MinterOptionalImpl = NoOpMinter<ContractState>;
    // impl MultiGameOptionalImpl = NoOpMultiGame<ContractState>;
    // etc.

    #[abi(embed_v0)]
    impl ERC721Metadata of IERC721Metadata<ContractState> {
        /// Returns the NFT name.
        fn name(self: @ContractState) -> ByteArray {
            self.erc721.ERC721_name.read()
        }

        /// Returns the NFT symbol.
        fn symbol(self: @ContractState) -> ByteArray {
            self.erc721.ERC721_symbol.read()
        }

        fn token_uri(self: @ContractState, token_id: u256) -> ByteArray {
            self.erc721._require_owned(token_id);

            let token_metadata: TokenMetadata = self
                .core_token
                .get_token_metadata(token_id.try_into().unwrap());

            // Try to get the token URI from the game contract if available
            if token_metadata.game_id != 0 {
                let game_registry_address = self.core_token.game_registry_address();
                let game_registry_dispatcher = IMinigameRegistryDispatcher {
                    contract_address: game_registry_address,
                };
                let game_address = game_registry_dispatcher
                    .game_address_from_id(token_metadata.game_id);

                let score_selector = selector!("score");
                let token_description_selector = selector!("token_description");
                let details_svg_selector = selector!("game_details_svg");
                let details_selector = selector!("game_details");
                let mut calldata = array![];
                calldata.append(token_id.low.into());

                let score = match call_contract_syscall(game_address, score_selector, calldata.span()) {
                    Result::Ok(result) => {
                        // Try to deserialize the result as u32
                        let mut result_span = result;
                        match Serde::<u32>::deserialize(ref result_span) {
                            Option::Some(score) => score,
                            Option::None => 0,
                        }
                    },
                    Result::Err(_) => 0,
                };

                let token_description = match call_contract_syscall(game_address, token_description_selector, calldata.span()) {
                    Result::Ok(result) => {
                        // Try to deserialize the result as ByteArray
                        let mut result_span = result;
                        match Serde::<ByteArray>::deserialize(ref result_span) {
                            Option::Some(game_details_svg) => game_details_svg,
                            Option::None => "An NFT representing ownership of an embeddable game.",
                        }
                    },
                    Result::Err(_) => "An NFT representing ownership of an embeddable game.",
                };

                let game_details_svg = match call_contract_syscall(game_address, details_svg_selector, calldata.span()) {
                    Result::Ok(result) => {
                        // Try to deserialize the result as ByteArray
                        let mut result_span = result;
                        match Serde::<ByteArray>::deserialize(ref result_span) {
                            Option::Some(game_details_svg) => game_details_svg,
                            Option::None => "https://denshokan.dev/game/1",
                        }
                    },
                    Result::Err(_) => "https://denshokan.dev/game/1",
                };

                let game_details = match call_contract_syscall(game_address, details_selector, calldata.span()) {
                    Result::Ok(result) => {
                        // Try to deserialize the result as Span<GameDetail>
                        let mut result_span = result;
                        match Serde::<Span<GameDetail>>::deserialize(ref result_span) {
                            Option::Some(game_details) => game_details,
                            Option::None => array![].span(),
                        }
                    },
                    Result::Err(_) => array![].span(),
                };
                let game_metadata = game_registry_dispatcher.game_metadata(token_metadata.game_id);
                let state = 0;
                let player_name = self
                    .core_token
                    .player_name(token_id.try_into().unwrap());

                create_custom_metadata(
                    token_id.try_into().unwrap(),
                    token_description,
                    game_metadata.name,
                    game_metadata.developer,
                    game_details_svg,
                    game_details,
                    score,
                    state,
                    player_name,
                )
            } else {
                // return the blank NFT renderer
                "https://denshokan.dev/game/1"
            }
            // ""
        }
    }


    // ================================================================================================
    // ERC721 HOOKS
    // ================================================================================================

    impl ERC721HooksImpl of ERC721Component::ERC721HooksTrait<ContractState> {
        fn before_update(
            ref self: ERC721Component::ComponentState<ContractState>,
            to: ContractAddress,
            token_id: u256,
            auth: ContractAddress,
        ) {
            // Only check soulbound restriction for transfers, not mints or burns
            // For mints, the current owner would be zero
            let current_owner = self._owner_of(token_id);
            if current_owner.into() != 0 && to.into() != 0 {
                // This is a transfer (not mint or burn)
                let contract_state = self.get_contract();
                if contract_state.is_soulbound(token_id.try_into().unwrap()) {
                    panic!("Token is soulbound and cannot be transferred");
                }
            }
        }

        fn after_update(
            ref self: ERC721Component::ComponentState<ContractState>,
            to: ContractAddress,
            token_id: u256,
            auth: ContractAddress,
        ) {
            let contract_state = self.get_contract();
            if !contract_state.event_relayer_address().is_zero() {
                let event_relayer = ITokenEventRelayerDispatcher {
                    contract_address: contract_state.event_relayer_address(),
                };
                event_relayer.emit_owners(token_id.try_into().unwrap(), to, auth);
            }
        }
    }

    // ================================================================================================
    // CONSTRUCTOR
    // ================================================================================================

    #[constructor]
    fn constructor(
        ref self: ContractState,
        name: ByteArray,
        symbol: ByteArray,
        base_uri: ByteArray,
        game_registry_address: Option<ContractAddress>,
        event_relayer_address: Option<ContractAddress>,
    ) {
        // Initialize core components
        self.erc721.initializer(name, symbol, base_uri);
        self.core_token.initializer(Option::None, Option::None, game_registry_address, event_relayer_address);

        self.minter.initializer();
        self.objectives.initializer();
        self.settings.initializer();
        self.context.initializer();
        self.renderer.initializer();
    }
}
