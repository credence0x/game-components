///
/// Game Component
///
#[starknet::component]
pub mod minigame_component {
    use crate::interface::{IMinigame, IMinigameScore, IMinigameDetails, IMinigameSettings, IMinigameObjectives, WorldImpl, IMINIGAME_ID};
    use crate::libs::{game, objectives, settings};
    use starknet::{ContractAddress, get_contract_address};
    use starknet::storage::{StoragePointerReadAccess, StoragePointerWriteAccess};
    use dojo::contract::components::world_provider::{IWorldProvider};

    use openzeppelin_introspection::src5::SRC5Component;
    use openzeppelin_introspection::src5::SRC5Component::InternalTrait as SRC5InternalTrait;
    use openzeppelin_introspection::src5::SRC5Component::SRC5Impl;

    #[storage]
    pub struct Storage {
        namespace: ByteArray,
        denshokan_address: ContractAddress,
    }

    #[embeddable_as(MinigameImpl)]
    impl Minigame<
        TContractState,
        +HasComponent<TContractState>,
        +IWorldProvider<TContractState>,
        +IMinigameScore<TContractState>,
        +IMinigameDetails<TContractState>,
        +IMinigameSettings<TContractState>,
        +IMinigameObjectives<TContractState>,
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
            // verify settings exist
            match settings_id {
                Option::Some(settings_id) => { self.assert_setting_exists(settings_id); },
                Option::None => {},
            };

            // mint game token
            let denshokan_address = self.denshokan_address.read();
            game::mint(
                denshokan_address,
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

        fn denshokan_address(self: @ComponentState<TContractState>) -> ContractAddress {
            self.denshokan_address.read()
        }
    }
    #[generate_trait]
    pub impl InternalImpl<
        TContractState,
        +HasComponent<TContractState>,
        +IWorldProvider<TContractState>,
        +IMinigameSettings<TContractState>,
        +IMinigameObjectives<TContractState>,
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
            renderer_address: Option<ContractAddress>,
            namespace: ByteArray,
            denshokan_address: ContractAddress,
        ) {
            // Register SRC5 interfaces FIRST so the contract can be identified as implementing
            // IGameToken
            self.register_src5_interfaces();

            // Store the namespace and denshokan address
            self.namespace.write(namespace.clone());
            self.denshokan_address.write(denshokan_address.clone());

            // Now register the game (this will work because SRC5 interfaces are registered)
            game::register_game(
                denshokan_address,
                creator_address,
                name,
                description,
                developer,
                publisher,
                genre,
                image,
                color,
                renderer_address,
            );
        }

        fn register_src5_interfaces(ref self: ComponentState<TContractState>) {
            let mut src5_component = get_dep_component_mut!(ref self, SRC5);
            src5_component.register_interface(IMINIGAME_ID);
        }

        fn assert_setting_exists(self: @ComponentState<TContractState>, settings_id: u32) {
            settings::assert_setting_exists(self.get_contract(), settings_id);
        }

        fn assert_objective_exists(self: @ComponentState<TContractState>, objective_id: u32) {
            objectives::assert_objective_exists(self.get_contract(), objective_id);
        }

        fn pre_action(self: @ComponentState<TContractState>, token_id: u64) {
            let denshokan_address = self.denshokan_address.read();
            game::pre_action(denshokan_address, token_id);
        }

        fn post_action(self: @ComponentState<TContractState>, token_id: u64, game_over: bool) {
            let denshokan_address = self.denshokan_address.read();
            game::post_action(denshokan_address, token_id, game_over);
        }

        fn get_objective_ids(self: @ComponentState<TContractState>, token_id: u64) -> Span<u32> {
            let denshokan_address = self.denshokan_address.read();
            objectives::get_objective_ids(denshokan_address, token_id)
        }

        fn get_settings_id(self: @ComponentState<TContractState>, token_id: u64) -> u32 {
            let denshokan_address = self.denshokan_address.read();
            settings::get_settings_id(denshokan_address, token_id)
        }

        fn create_objective(self: @ComponentState<TContractState>, objective_id: u32, data: ByteArray) {
            let denshokan_address = self.denshokan_address.read();
            objectives::create_objective(denshokan_address, get_contract_address(), objective_id, data);
        }

        fn create_settings(self: @ComponentState<TContractState>, settings_id: u32, data: ByteArray) {
            let denshokan_address = self.denshokan_address.read();
            settings::create_settings(denshokan_address, get_contract_address(), settings_id, data);
        }

        fn assert_token_ownership(self: @ComponentState<TContractState>, token_id: u64) {
            let denshokan_address = self.denshokan_address.read();
            game::assert_token_ownership(denshokan_address, token_id);
        }

        fn assert_game_token_playable(self: @ComponentState<TContractState>, token_id: u64) {
            let denshokan_address = self.denshokan_address.read();
            game::assert_game_token_playable(denshokan_address, token_id);
        }
    }
}
