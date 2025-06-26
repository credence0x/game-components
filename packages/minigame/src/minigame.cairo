///
/// Game Component
///
#[starknet::component]
pub mod minigame_component {
    use core::num::traits::Zero;
    use crate::interface::{
        IMinigame, IMinigameTokenData, IMINIGAME_ID,
    };
    use crate::libs;
    use game_components_minigame_objectives::interface::{
        IMINIGAME_OBJECTIVES_ID
    };
    use game_components_minigame_settings::interface::{
        IMINIGAME_SETTINGS_ID
    };
    use game_components_metagame_context::structs::GameContextDetails;
    use starknet::{ContractAddress, get_contract_address};
    use starknet::storage::{StoragePointerReadAccess, StoragePointerWriteAccess};

    use openzeppelin_introspection::src5::SRC5Component;
    use openzeppelin_introspection::src5::SRC5Component::InternalTrait as SRC5InternalTrait;
    use openzeppelin_introspection::src5::SRC5Component::SRC5Impl;
    use openzeppelin_introspection::interface::{ISRC5Dispatcher, ISRC5DispatcherTrait};

    #[storage]
    pub struct Storage {
        minigame_token_address: ContractAddress,
        settings_address: ContractAddress,
        objectives_address: ContractAddress,
    }

    #[embeddable_as(MinigameImpl)]
    impl Minigame<
        TContractState,
        +HasComponent<TContractState>,
        +IMinigameTokenData<TContractState>,
        impl SRC5: SRC5Component::HasComponent<TContractState>,
        +Drop<TContractState>,
    > of IMinigame<ComponentState<TContractState>> {
        fn mint(
            ref self: ComponentState<TContractState>,
            player_name: Option<felt252>,
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
            match settings_id {
                Option::Some(_) => {
                    let settings_address = self.settings_address.read();
                    if !settings_address.is_zero() {
                        let settings_src5_dispatcher = ISRC5Dispatcher { contract_address: settings_address };
                        assert!(
                            settings_src5_dispatcher.supports_interface(IMINIGAME_SETTINGS_ID),
                            "Minigame: Settings contract does not support IMinigameSettings",
                        );
                    } else {
                    let src5_component = get_dep_component_mut!(ref self, SRC5);
                    assert!(
                        src5_component.supports_interface(IMINIGAME_SETTINGS_ID),
                            "Minigame: Caller does not support IMinigameSettings",
                        );
                    }
                },
                Option::None => {},
            };
            match objective_ids {
                Option::Some(_) => {
                    let objectives_address = self.objectives_address.read();
                    if !objectives_address.is_zero() {
                        let objectives_src5_dispatcher = ISRC5Dispatcher { contract_address: objectives_address };
                        assert!(
                            objectives_src5_dispatcher.supports_interface(IMINIGAME_OBJECTIVES_ID),
                            "Minigame: Objectives contract does not support IMinigameObjectives",
                        );
                    } else {
                        let src5_component = get_dep_component_mut!(ref self, SRC5);
                        assert!(
                            src5_component.supports_interface(IMINIGAME_OBJECTIVES_ID),
                            "Minigame: Caller does not support IMinigameObjectives",
                        );
                    }
                },
                Option::None => {},
            };
            // mint game token
            libs::mint(
                self.minigame_token_address.read(),
                get_contract_address(),
                player_name,
                settings_id,
                start,
                end,
                objective_ids,
                context,
                client_url,
                renderer_address,
                to,
                soulbound,
            )
        }

        fn minigame_token_address(self: @ComponentState<TContractState>) -> ContractAddress {
            self.minigame_token_address.read()
        }
    }

    #[generate_trait]
    pub impl InternalImpl<
        TContractState,
        +HasComponent<TContractState>,
        impl SRC5: SRC5Component::HasComponent<TContractState>,
        +Drop<TContractState>,
    > of InternalTrait<TContractState> {
        fn initializer(
            ref self: ComponentState<TContractState>,
            creator_address: ContractAddress,
            name: felt252,
            description: ByteArray,
            developer: felt252,
            publisher: felt252,
            genre: felt252,
            image: ByteArray,
            color: Option<ByteArray>,
            client_url: Option<ByteArray>,
            renderer_address: Option<ContractAddress>,
            settings_address: Option<ContractAddress>,
            objectives_address: Option<ContractAddress>,
            minigame_token_address: ContractAddress,
        ) {
            // Register base SRC5 interface
            self.register_game_interface();

            // Store the namespace, token address, and feature flags
            self.minigame_token_address.write(minigame_token_address.clone());

            // Now register the game (this will work because SRC5 interfaces are registered)
            libs::register_game(
                minigame_token_address,
                creator_address,
                name,
                description,
                developer,
                publisher,
                genre,
                image,
                color,
                client_url,
                renderer_address,
                settings_address,
                objectives_address,
            );

            // Store the settings and objectives addresses
            match settings_address {
                Option::Some(address) => self.settings_address.write(address.clone()),
                Option::None => {},
            };
            match objectives_address {
                Option::Some(address) => self.objectives_address.write(address.clone()),
                Option::None => {},
            };
        }

        fn register_game_interface(ref self: ComponentState<TContractState>) {
            let mut src5_component = get_dep_component_mut!(ref self, SRC5);
            src5_component.register_interface(IMINIGAME_ID);
        }

        fn pre_action(self: @ComponentState<TContractState>, token_id: u64) {
            libs::pre_action(self.minigame_token_address.read(), token_id);
        }

        fn post_action(self: @ComponentState<TContractState>, token_id: u64) {
            libs::post_action(self.minigame_token_address.read(), token_id);
        }

        fn get_player_name(self: @ComponentState<TContractState>, token_id: u64) -> felt252 {
            libs::get_player_name(self.minigame_token_address.read(), token_id)
        }

        fn assert_token_ownership(self: @ComponentState<TContractState>, token_id: u64) {
            libs::assert_token_ownership(self.minigame_token_address.read(), token_id);
        }

        fn assert_game_token_playable(self: @ComponentState<TContractState>, token_id: u64) {
            libs::assert_game_token_playable(self.minigame_token_address.read(), token_id);
        }
    }


}
