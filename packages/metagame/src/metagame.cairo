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

    use starknet::storage::{StoragePointerReadAccess, StoragePointerWriteAccess};

    #[storage]
    pub struct Storage {
        namespace: ByteArray,
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
    }

    #[generate_trait]
    pub impl InternalImpl<
        TContractState,
        +HasComponent<TContractState>,
        +IWorldProvider<TContractState>,
        impl SRC5: SRC5Component::HasComponent<TContractState>,
        +Drop<TContractState>,
    > of InternalTrait<TContractState> {
        fn initializer(ref self: ComponentState<TContractState>, namespace: ByteArray) {
            self.register_src5_interfaces();
            self.namespace.write(namespace.clone());
        }

        fn register_src5_interfaces(ref self: ComponentState<TContractState>) {
            let mut src5_component = get_dep_component_mut!(ref self, SRC5);
            src5_component.register_interface(IMETAGAME_ID);
        }
    }
}
