use starknet::ContractAddress;

#[starknet::interface]
pub trait IMetagameStarknetMock<TContractState> {
    fn mint_game(
        ref self: TContractState,
        game_address: Option<ContractAddress>,
        player_name: Option<felt252>,
        settings_id: Option<u32>,
        start: Option<u64>,
        end: Option<u64>,
        objective_ids: Option<Span<u32>>,
        client_url: Option<ByteArray>,
        renderer_address: Option<ContractAddress>,
        to: ContractAddress,
        soulbound: bool,
    ) -> u64;
}

#[starknet::interface]
pub trait IMetagameStarknetMockInit<TContractState> {
    fn initializer(
        ref self: TContractState, 
        namespace: ByteArray, 
        minigame_token_address: ContractAddress,
        supports_context: bool,
    );
}

#[starknet::contract]
pub mod metagame_starknet_mock {
    use game_components_metagame::interface::{IMetagameContext};
    use game_components_metagame::metagame::metagame_component;
    use game_components_metagame::structs::context::{GameContextDetails, GameContext};
    use game_components_utils::json::create_context_json;
    use openzeppelin_introspection::src5::SRC5Component;

    use starknet::ContractAddress;
    use starknet::storage::{
        StoragePointerWriteAccess, Map, StorageMapReadAccess, StorageMapWriteAccess
    };

    component!(path: metagame_component, storage: metagame, event: MetagameEvent);
    component!(path: SRC5Component, storage: src5, event: SRC5Event);

    #[abi(embed_v0)]
    impl MetagameImpl = metagame_component::MetagameImpl<ContractState>;
    impl MetagameInternalImpl = metagame_component::InternalImpl<ContractState>;
    impl MetagameInternalContextImpl = metagame_component::InternalContextImpl<ContractState>;

    #[abi(embed_v0)]
    impl SRC5Impl = SRC5Component::SRC5Impl<ContractState>;

    #[storage]
    struct Storage {
        #[substorage(v0)]
        metagame: metagame_component::Storage,
        #[substorage(v0)]
        src5: SRC5Component::Storage,
        
        // Metagame storage
        token_counter: u64,
        
        // Token context storage - mimicking the Dojo Context model
        token_context_count: Map<u64, u32>, // token_id -> count of contexts
        token_context_name: Map<(u64, u32), ByteArray>, // (token_id, index) -> context name
        token_context_value: Map<(u64, u32), ByteArray>, // (token_id, index) -> context value
        token_context_exists: Map<u64, bool>, // token_id -> exists
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        #[flat]
        MetagameEvent: metagame_component::Event,
        #[flat]
        SRC5Event: SRC5Component::Event,
    }

    #[abi(embed_v0)]
    impl MetagameContextImpl of IMetagameContext<ContractState> {
        fn has_context(self: @ContractState, token_id: u64) -> bool {
            self.token_context_exists.read(token_id)
        }

        fn context(self: @ContractState, token_id: u64) -> GameContextDetails {
            let context_count = self.token_context_count.read(token_id);
            let mut contexts = array![];
            
            let mut i = 0;
            while i < context_count {
                let context_name = self.token_context_name.read((token_id, i));
                let context_value = self.token_context_value.read((token_id, i));
                
                let game_context = GameContext {
                    name: context_name,
                    value: context_value
                };
                contexts.append(game_context);
                i += 1;
            };
            
            GameContextDetails {
                name: "Test Game Context",
                description: "Test context for testing",
                context: contexts.span()
            }
        }
    }

    #[abi(embed_v0)]
    impl MetagameMockImpl of super::IMetagameStarknetMock<ContractState> {
        fn mint_game(
            ref self: ContractState,
            game_address: Option<ContractAddress>,
            player_name: Option<felt252>,
            settings_id: Option<u32>,
            start: Option<u64>,
            end: Option<u64>,
            objective_ids: Option<Span<u32>>,
            client_url: Option<ByteArray>,
            renderer_address: Option<ContractAddress>,
            to: ContractAddress,
            soulbound: bool,
        ) -> u64 {
            let context = array![
                GameContext { name: "Test Context 1", value: "Test Context" },
            ].span();
            let context_json = create_context_json("Test App", "Test App Description", context);
            // Call the metagame component mint function
            let token_id = self.metagame.mint(
                game_address,
                player_name,
                settings_id,
                start,
                end,
                objective_ids,
                Option::Some(context_json),
                client_url,
                renderer_address,
                to,
                soulbound
            );
            
            // Store the context data in our local storage
            self.token_context_count.write(token_id, 1);
            self.token_context_name.write((token_id, 0), "Test Context 1");
            self.token_context_value.write((token_id, 0), "Test Context");
            self.token_context_exists.write(token_id, true);
            
            token_id
        }
    }

    #[abi(embed_v0)]
    impl MetagameInitializerImpl of super::IMetagameStarknetMockInit<ContractState> {
        fn initializer(
            ref self: ContractState, 
            namespace: ByteArray, 
            minigame_token_address: ContractAddress,
            supports_context: bool,
        ) {
            // Initialize the metagame component
            self.metagame.initializer(namespace, minigame_token_address);
            
            // Initialize local storage
            self.token_counter.write(0);
            
            // Initialize context support if needed
            if supports_context {
                self.metagame.initialize_context();
            }
        }
    }
} 