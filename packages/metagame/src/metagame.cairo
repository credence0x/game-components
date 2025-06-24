///
/// Game Component
///
#[starknet::component]
pub mod metagame_component {
    use crate::interface::{IMetagame, IMetagameContext, IMETAGAME_ID, IMETAGAME_CONTEXT_ID};
    use crate::metagame_actions::metagame_actions;

    use dojo::contract::components::world_provider::{IWorldProvider};
    use openzeppelin_introspection::src5::SRC5Component;
    use openzeppelin_introspection::src5::SRC5Component::InternalTrait as SRC5InternalTrait;
    use openzeppelin_introspection::src5::SRC5Component::SRC5Impl;

    use starknet::contract_address::ContractAddress;
    use starknet::storage::{StoragePointerReadAccess, StoragePointerWriteAccess};

    #[storage]
    pub struct Storage {
        namespace: ByteArray,
        minigame_token_address: ContractAddress,
    }

    #[embeddable_as(MetagameImpl)]
    impl Metagame<
        TContractState,
        +HasComponent<TContractState>,
        +IWorldProvider<TContractState>,
        impl SRC5: SRC5Component::HasComponent<TContractState>,
        +Drop<TContractState>,
    > of IMetagame<ComponentState<TContractState>> {
        fn namespace(self: @ComponentState<TContractState>) -> ByteArray {
            self.namespace.read()
        }

        fn minigame_token_address(self: @ComponentState<TContractState>) -> ContractAddress {
            self.minigame_token_address.read()
        }
    }

    #[generate_trait]
    pub impl InternalImpl<
        TContractState,
        +HasComponent<TContractState>,
        +IWorldProvider<TContractState>,
        impl SRC5: SRC5Component::HasComponent<TContractState>,
        +Drop<TContractState>,
    > of InternalTrait<TContractState> {
        fn initializer(
            ref self: ComponentState<TContractState>,
            namespace: ByteArray,
            minigame_token_address: ContractAddress,
        ) {
            self.register_src5_interfaces();
            self.namespace.write(namespace.clone());
            self.minigame_token_address.write(minigame_token_address.clone());
        }

        fn register_src5_interfaces(ref self: ComponentState<TContractState>) {
            let mut src5_component = get_dep_component_mut!(ref self, SRC5);
            src5_component.register_interface(IMETAGAME_ID);
        }

        fn assert_game_registered(
            ref self: ComponentState<TContractState>, game_address: ContractAddress,
        ) {
            let minigame_token_address = self.minigame_token_address.read();
            metagame_actions::assert_game_registered(minigame_token_address, game_address);
        }
    }

    #[generate_trait]
    pub impl InternalContextImpl<
        TContractState,
        +HasComponent<TContractState>,
        +IWorldProvider<TContractState>,
        +IMetagameContext<TContractState>,
        impl SRC5: SRC5Component::HasComponent<TContractState>,
        +Drop<TContractState>,
    > of InternalContextTrait<TContractState> {
        fn initialize_context(ref self: ComponentState<TContractState>) {
            self.register_context_interface();
        }

        fn register_context_interface(ref self: ComponentState<TContractState>) {
            let mut src5_component = get_dep_component_mut!(ref self, SRC5);
            src5_component.register_interface(IMETAGAME_CONTEXT_ID);
        }
    }
}
