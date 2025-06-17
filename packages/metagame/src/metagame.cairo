///
/// Game Component
///
#[starknet::component]
pub mod metagame_component {
    use crate::interface::{IMetagame, IMetagameContext, IMETAGAME_ID};

    use dojo::contract::components::world_provider::{IWorldProvider};
    use openzeppelin_introspection::src5::SRC5Component;
    use openzeppelin_introspection::src5::SRC5Component::InternalTrait as SRC5InternalTrait;
    use openzeppelin_introspection::src5::SRC5Component::SRC5Impl;

    use starknet::contract_address::ContractAddress;
    use starknet::storage::{StoragePointerReadAccess, StoragePointerWriteAccess};

    use game_components_denshokan::interface::{IDenshokanDispatcher, IDenshokanDispatcherTrait};

    #[storage]
    pub struct Storage {
        namespace: ByteArray,
        denshokan_address: ContractAddress,
    }

    #[embeddable_as(MetagameImpl)]
    impl Metagame<
        TContractState,
        +HasComponent<TContractState>,
        +IWorldProvider<TContractState>,
        +IMetagameContext<TContractState>,
        impl SRC5: SRC5Component::HasComponent<TContractState>,
        +Drop<TContractState>,
    > of IMetagame<ComponentState<TContractState>> {
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
        impl SRC5: SRC5Component::HasComponent<TContractState>,
        +Drop<TContractState>,
    > of InternalTrait<TContractState> {
        fn initializer(ref self: ComponentState<TContractState>, namespace: ByteArray, denshokan_address: ContractAddress) {
            self.register_src5_interfaces();
            self.namespace.write(namespace.clone());
            self.denshokan_address.write(denshokan_address.clone());
        }

        fn register_src5_interfaces(ref self: ComponentState<TContractState>) {
            let mut src5_component = get_dep_component_mut!(ref self, SRC5);
            src5_component.register_interface(IMETAGAME_ID);
        }

        fn assert_game_registered(ref self: ComponentState<TContractState>, game_address: ContractAddress) {
            let denshokan_dispatcher = IDenshokanDispatcher{ contract_address: self.denshokan_address.read() };
            let game_exists = denshokan_dispatcher.is_game_registered(game_address);
            assert!(game_exists, "Game is not registered");
        }
    }
}
