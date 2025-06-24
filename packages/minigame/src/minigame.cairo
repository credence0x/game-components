///
/// Game Component
///
#[starknet::component]
pub mod minigame_component {
    use crate::interface::{
        IMinigame, IMinigameTokenData, IMinigameSettings, IMinigameObjectives, IMINIGAME_ID,
        IMINIGAME_OBJECTIVES_ID, IMINIGAME_SETTINGS_ID,
    };
    use crate::models::settings::GameSetting;
    use crate::libs::{game, objectives, settings};
    use starknet::{ContractAddress, get_contract_address};
    use starknet::storage::{StoragePointerReadAccess, StoragePointerWriteAccess};

    use openzeppelin_introspection::src5::SRC5Component;
    use openzeppelin_introspection::src5::SRC5Component::InternalTrait as SRC5InternalTrait;
    use openzeppelin_introspection::src5::SRC5Component::SRC5Impl;

    #[storage]
    pub struct Storage {
        namespace: ByteArray,
        token_address: ContractAddress,
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
            context: Option<ByteArray>,
            client_url: Option<ByteArray>,
            renderer_address: Option<ContractAddress>,
            to: ContractAddress,
            soulbound: bool,
        ) -> u64 {
            match settings_id {
                Option::Some(_) => {
                    let src5_component = get_dep_component_mut!(ref self, SRC5);
                    assert!(
                        src5_component.supports_interface(IMINIGAME_SETTINGS_ID),
                        "Minigame: Settings interface not supported",
                    );
                },
                Option::None => {},
            };
            match objective_ids {
                Option::Some(_) => {
                    let src5_component = get_dep_component_mut!(ref self, SRC5);
                    assert!(
                        src5_component.supports_interface(IMINIGAME_OBJECTIVES_ID),
                        "Minigame: Objectives interface not supported",
                    );
                },
                Option::None => {},
            };
            // mint game token
            let token_address = self.token_address.read();
            game::mint(
                token_address,
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

        fn namespace(self: @ComponentState<TContractState>) -> ByteArray {
            self.namespace.read()
        }

        fn token_address(self: @ComponentState<TContractState>) -> ContractAddress {
            self.token_address.read()
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
            namespace: ByteArray,
            token_address: ContractAddress,
        ) {
            // Register base SRC5 interface
            self.register_game_interface();

            // Store the namespace, token address, and feature flags
            self.namespace.write(namespace.clone());
            self.token_address.write(token_address.clone());

            // Now register the game (this will work because SRC5 interfaces are registered)
            game::register_game(
                token_address,
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
        }

        fn register_game_interface(ref self: ComponentState<TContractState>) {
            let mut src5_component = get_dep_component_mut!(ref self, SRC5);
            src5_component.register_interface(IMINIGAME_ID);
        }

        fn pre_action(self: @ComponentState<TContractState>, token_id: u64) {
            let token_address = self.token_address.read();
            game::pre_action(token_address, token_id);
        }

        fn post_action(self: @ComponentState<TContractState>, token_id: u64) {
            let token_address = self.token_address.read();
            game::post_action(token_address, token_id);
        }

        fn get_player_name(self: @ComponentState<TContractState>, token_id: u64) -> felt252 {
            let token_address = self.token_address.read();
            game::get_player_name(token_address, token_id)
        }

        fn assert_token_ownership(self: @ComponentState<TContractState>, token_id: u64) {
            let token_address = self.token_address.read();
            game::assert_token_ownership(token_address, token_id);
        }

        fn assert_game_token_playable(self: @ComponentState<TContractState>, token_id: u64) {
            let token_address = self.token_address.read();
            game::assert_game_token_playable(token_address, token_id);
        }
    }

    #[generate_trait]
    pub impl InternalObjectivesImpl<
        TContractState,
        +HasComponent<TContractState>,
        +IMinigameObjectives<TContractState>,
        impl SRC5: SRC5Component::HasComponent<TContractState>,
        +Drop<TContractState>,
    > of InternalObjectivesTrait<TContractState> {
        fn initialize_objectives(ref self: ComponentState<TContractState>) {
            self.register_objectives_interface();
        }

        fn get_objective_ids(self: @ComponentState<TContractState>, token_id: u64) -> Span<u32> {
            let token_address = self.token_address.read();
            objectives::get_objective_ids(token_address, token_id)
        }

        fn register_objectives_interface(ref self: ComponentState<TContractState>) {
            let mut src5_component = get_dep_component_mut!(ref self, SRC5);
            src5_component.register_interface(IMINIGAME_OBJECTIVES_ID);
        }

        fn create_objective(
            self: @ComponentState<TContractState>,
            objective_id: u32,
            name: ByteArray,
            value: ByteArray,
        ) {
            let token_address = self.token_address.read();
            objectives::create_objective(
                token_address, get_contract_address(), objective_id, name, value,
            );
        }
    }

    #[generate_trait]
    pub impl InternalSettingsImpl<
        TContractState,
        +HasComponent<TContractState>,
        +IMinigameSettings<TContractState>,
        impl SRC5: SRC5Component::HasComponent<TContractState>,
        +Drop<TContractState>,
    > of InternalSettingsTrait<TContractState> {
        fn initialize_settings(ref self: ComponentState<TContractState>) {
            self.register_settings_interface();
        }

        fn get_settings_id(self: @ComponentState<TContractState>, token_id: u64) -> u32 {
            let token_address = self.token_address.read();
            settings::get_settings_id(token_address, token_id)
        }

        fn register_settings_interface(ref self: ComponentState<TContractState>) {
            let mut src5_component = get_dep_component_mut!(ref self, SRC5);
            src5_component.register_interface(IMINIGAME_SETTINGS_ID);
        }

        fn create_settings(
            self: @ComponentState<TContractState>,
            settings_id: u32,
            name: ByteArray,
            description: ByteArray,
            settings: Span<GameSetting>,
        ) {
            let token_address = self.token_address.read();
            settings::create_settings(
                token_address, get_contract_address(), settings_id, name, description, settings,
            );
        }
    }
}
