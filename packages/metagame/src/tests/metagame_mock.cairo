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
        objective_ids: Option<Span<u32>>,
        to: ContractAddress,
        soulbound: bool,
    ) -> u64;
}

#[starknet::interface]
pub trait IMetagameMockInit<TContractState> {
    fn initializer(ref self: TContractState, namespace: ByteArray, denshokan_address: ContractAddress);
}

#[dojo::contract]
mod metagame_mock {
    use starknet::ContractAddress;
    use crate::models::context::GameContext;
    use crate::tests::models::metagame::Context;
    use crate::interface::{IMetagameContext, IMetagameContextURI};
    use crate::metagame::metagame_component;

    use openzeppelin_introspection::src5::SRC5Component;
    use starknet::storage::{StoragePointerReadAccess, StoragePointerWriteAccess};

    use crate::tests::libs::metagame_store::{Store, StoreTrait};
    use game_components_utils::json::create_context_json;
    use game_components_denshokan::interface::{IDenshokanDispatcher, IDenshokanDispatcherTrait};

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
            objective_ids: Option<Span<u32>>,
            to: ContractAddress,
            soulbound: bool,
        ) -> u64 {
            let context_key_values = array![
                GameContext { name: "Test Context 1", value: "Test Context" },
            ].span();
            let context = create_context_json(context_key_values);
            let denshokan_dispatcher = IDenshokanDispatcher { contract_address: self.denshokan_address.read() };
            let token_id = denshokan_dispatcher
                .mint(
                    game_id,
                    player_name,
                    settings_id,
                    start,
                    end,
                    objective_ids,
                    Option::Some(context.clone()),
                    to,
                    soulbound,
                );
            let mut world = self.world(@self.namespace());
            let mut store: Store = StoreTrait::new(world);
            store.set_context(@Context { token_id, context: context.clone(), exists: true });
            token_id
        }
    }

    #[abi(embed_v0)]
    impl GameContextImpl of IMetagameContext<ContractState> {
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
            context.context
        }
    }

    #[abi(embed_v0)]
    impl GameContextURIImpl of IMetagameContextURI<ContractState> {
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
