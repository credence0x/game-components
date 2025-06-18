///
/// Game Component
///
#[starknet::component]
pub mod minigame_component {
    use crate::interface::{IMinigame, IMinigameScore, IMinigameDetails, IMinigameSettings, IMinigameObjectives, WorldImpl, IMINIGAME_ID};
    use game_components_denshokan::interface::{IDenshokanDispatcher, IDenshokanDispatcherTrait};
    use starknet::{ContractAddress, get_contract_address};
    use starknet::storage::{StoragePointerReadAccess, StoragePointerWriteAccess};
    use dojo::contract::components::world_provider::{IWorldProvider};

    use openzeppelin_introspection::src5::SRC5Component;
    use openzeppelin_introspection::src5::SRC5Component::InternalTrait as SRC5InternalTrait;
    use openzeppelin_introspection::src5::SRC5Component::SRC5Impl;
    use openzeppelin_token::erc721::interface::{IERC721Dispatcher, IERC721DispatcherTrait};

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
            let denshokan_dispatcher = IDenshokanDispatcher { contract_address: denshokan_address };
            let token_id = denshokan_dispatcher
                .mint(
                    Option::Some(get_contract_address()),
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
                );

            token_id
        }

        fn namespace(self: @ComponentState<TContractState>) -> ByteArray {
            self.namespace.read()
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
            self
                .register_game(
                    creator_address,
                    name,
                    description,
                    developer,
                    publisher,
                    genre,
                    image,
                    color,
                    denshokan_address,
                );
        }

        fn register_game(
            ref self: ComponentState<TContractState>,
            creator_address: ContractAddress,
            name: felt252,
            description: ByteArray,
            developer: felt252,
            publisher: felt252,
            genre: felt252,
            image: ByteArray,
            color: Option<ByteArray>,
            denshokan_address: ContractAddress,
        ) {
            let denshokan_dispatcher = IDenshokanDispatcher { contract_address: denshokan_address };
            denshokan_dispatcher
                .register_game(
                    creator_address,
                    name,
                    description,
                    developer,
                    publisher,
                    genre,
                    image,
                    color,
                );
        }

        fn register_src5_interfaces(ref self: ComponentState<TContractState>) {
            let mut src5_component = get_dep_component_mut!(ref self, SRC5);
            src5_component.register_interface(IMINIGAME_ID);
        }

        fn assert_setting_exists(self: @ComponentState<TContractState>, settings_id: u32) {
            let setting_exists = self.get_contract().setting_exists(settings_id);
            if !setting_exists {
                panic!("Game: Setting ID {} does not exist", settings_id);
            }
        }

        fn assert_objective_exists(self: @ComponentState<TContractState>, objective_id: u32) {
            let objective_exists = self.get_contract().objective_exists(objective_id);
            if !objective_exists {
                panic!("Game: Objective ID {} does not exist", objective_id);
            }
        }

        fn pre_action(self: @ComponentState<TContractState>, token_id: u64) {
            self.assert_token_ownership(token_id);
            self.assert_game_token_playable(token_id);
        }

        fn post_action(self: @ComponentState<TContractState>, token_id: u64, game_over: bool) {
            let denshokan_address = self.denshokan_address.read();
            let denshokan_dispatcher = IDenshokanDispatcher { contract_address: denshokan_address };
            if game_over {
                denshokan_dispatcher.end_game(token_id);
            } else {
                denshokan_dispatcher.update_game(token_id);
            }
        }

        fn get_objective_ids(self: @ComponentState<TContractState>, token_id: u64) -> Span<u32> {
            let denshokan_address = self.denshokan_address.read();
            let denshokan_dispatcher = IDenshokanDispatcher { contract_address: denshokan_address };
            denshokan_dispatcher.objective_ids(token_id)
        }

        fn get_settings_id(self: @ComponentState<TContractState>, token_id: u64) -> u32 {
            let denshokan_address = self.denshokan_address.read();
            let denshokan_dispatcher = IDenshokanDispatcher { contract_address: denshokan_address };
            denshokan_dispatcher.settings_id(token_id)
        }

        fn create_objective(self: @ComponentState<TContractState>, objective_id: u32, data: ByteArray) {
            let denshokan_address = self.denshokan_address.read();
            let denshokan_dispatcher = IDenshokanDispatcher { contract_address: denshokan_address };
            denshokan_dispatcher.create_objective(get_contract_address(), objective_id, data);
        }

        fn create_settings(self: @ComponentState<TContractState>, settings_id: u32, data: ByteArray) {
            let denshokan_address = self.denshokan_address.read();
            let denshokan_dispatcher = IDenshokanDispatcher { contract_address: denshokan_address };
            denshokan_dispatcher.create_settings(get_contract_address(), settings_id, data);
        }

        fn assert_token_ownership(self: @ComponentState<TContractState>, token_id: u64) {
            let denshokan_address = self.denshokan_address.read();
            let erc721_dispatcher = IERC721Dispatcher { contract_address: denshokan_address };
            let token_owner = erc721_dispatcher.owner_of(token_id.into());
            assert!(
                token_owner == starknet::get_caller_address(),
                "Caller is not owner of token {}",
                token_id,
            );
        }

        fn assert_game_token_playable(self: @ComponentState<TContractState>, token_id: u64) {
            let denshokan_address = self.denshokan_address.read();
            let denshokan_dispatcher = IDenshokanDispatcher { contract_address: denshokan_address };
            let is_playable = denshokan_dispatcher.is_game_token_playable(token_id);
            assert!(is_playable, "Game is not playable");
        }
    }
}
