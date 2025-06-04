use starknet::ContractAddress;

#[starknet::interface]
pub trait IMetagameMock<TContractState> {
    fn mint_game(
        ref self: TContractState,
        game_id: Option<u64>,
        player_name: Option<felt252>,
        settings_id: Option<u32>,
        start: Option<u64>,
        end: Option<u64>,
        to: ContractAddress,
        soulbound: bool,
    ) -> u64;
    fn create_context(ref self: TContractState, token_id: u64, context: ByteArray);
}

#[starknet::interface]
pub trait IMetagameMockInit<TContractState> {
    fn initializer(ref self: TContractState, namespace: ByteArray, denshokan_address: ContractAddress);
}

#[dojo::contract]
mod metagame_mock {
    use starknet::ContractAddress;
    use crate::models::context::GameContext;
    use crate::tests::models::metagame::MetagameContext;
    use crate::interface::{IMetagameContext, IMetagameContextURI};
    use crate::metagame::metagame_component;

    use openzeppelin_introspection::src5::SRC5Component;
    use starknet::storage::{StoragePointerReadAccess, StoragePointerWriteAccess};

    use crate::tests::libs::metagame_store::{Store, StoreTrait};
    use game_components_utils::json::create_context_json;
    use denshokan::interfaces::denshokan::{IDenshokanDispatcher, IDenshokanDispatcherTrait};

    component!(path: metagame_component, storage: metagame, event: MetagameEvent);
    component!(path: SRC5Component, storage: src5, event: SRC5Event);

    #[abi(embed_v0)]
    impl MetagameImpl = metagame_component::MetagameImpl<ContractState>;
    impl MetagameInternalImpl = metagame_component::InternalImpl<ContractState>;

    #[abi(embed_v0)]
    impl SRC5Impl = SRC5Component::SRC5Impl<ContractState>;
    impl SRC5InternalImpl = SRC5Component::InternalImpl<ContractState>;

    #[storage]
    struct Storage {
        #[substorage(v0)]
        metagame: metagame_component::Storage,
        #[substorage(v0)]
        src5: SRC5Component::Storage,
        denshokan_address: ContractAddress,
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        #[flat]
        MetagameEvent: metagame_component::Event,
        #[flat]
        SRC5Event: SRC5Component::Event,
    }

    //*******************************

    #[abi(embed_v0)]
    impl MetagameMockImpl of super::IMetagameMock<ContractState> {
        fn mint_game(
            ref self: ContractState,
            game_id: Option<u64>,
            player_name: Option<felt252>,
            settings_id: Option<u32>,
            start: Option<u64>,
            end: Option<u64>,
            to: ContractAddress,
            soulbound: bool,
        ) -> u64 {
            let denshokan_dispatcher = IDenshokanDispatcher { contract_address: self.denshokan_address.read() };
            let objective_ids = array![1, 2];
            denshokan_dispatcher
                .mint(
                    game_id,
                    player_name,
                    settings_id,
                    start,
                    end,
                    Option::Some(objective_ids.span()),
                    true,
                    to,
                    soulbound,
                )
        }

        fn create_context(
            ref self: ContractState,
            token_id: u64,
            context: ByteArray,
        ) {
            let mut world = self.world(@self.namespace());
            let mut store: Store = StoreTrait::new(world);
            store.set_context(@Context { token_id, context, exists: true });
        }
    }

    #[abi(embed_v0)]
    impl GameContextImpl of IGameContext<ContractState> {
        fn has_context(self: @ContractState, token_id: u64) -> bool {
            let world = self.world(@self.namespace());
            let store: Store = StoreTrait::new(world);
            let context = store.get_context(token_id);
            context.exists
        }

        fn context(self: @ContractState, token_id: u64) -> ByteArray {
            let world = self.world(@self.namespace());
            let store: Store = StoreTrait::new(world);
            let context = store.get_context(token_id);
            let contexts = array![
                GameContext { name: "Test Context 1", value: context.context },
            ].span();
            create_context_json(contexts)
        }
    }

    #[abi(embed_v0)]
    impl GameContextURIImpl of IGameContextURI<ContractState> {
        fn context_uri(self: @ContractState, token_id: u64) -> ByteArray {
            "test context uri"
        }
    }

    #[abi(embed_v0)]
    impl MetagameInitializerImpl of super::IMetagameMockInit<ContractState> {
        fn initializer(
            ref self: ContractState, namespace: ByteArray, denshokan_address: ContractAddress,
        ) {
            self.metagame.initializer(namespace);
            self.denshokan_address.write(denshokan_address.clone());
        }
    }
}
