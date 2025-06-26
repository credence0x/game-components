//
// Settings Component
//
#[starknet::component]
pub mod settings_component {
    use crate::interface::{IMinigameSettings, IMINIGAME_SETTINGS_ID};
    use crate::libs;
    use crate::structs::{GameSetting};
    use starknet::{ContractAddress, get_contract_address};
    use starknet::storage::{StoragePointerReadAccess, StoragePointerWriteAccess};

    use openzeppelin_introspection::src5::SRC5Component;
    use openzeppelin_introspection::src5::SRC5Component::InternalTrait as SRC5InternalTrait;

    #[storage]
    pub struct Storage {
        token_address: ContractAddress,
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    pub enum Event {}  // No events for now, but needed for component

    #[generate_trait]
    pub impl InternalImpl<
        TContractState,
        +HasComponent<TContractState>,
        +IMinigameSettings<TContractState>,
        impl SRC5: SRC5Component::HasComponent<TContractState>,
        +Drop<TContractState>,
    > of InternalTrait<TContractState> {
        fn initializer(ref self: ComponentState<TContractState>, token_address: ContractAddress) {
            self.token_address.write(token_address);
            self.register_settings_interface();
        }

        fn get_settings_id(self: @ComponentState<TContractState>, token_id: u64) -> u32 {
            let token_address = self.token_address.read();
            libs::get_settings_id(token_address, token_id)
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
            libs::create_settings(
                token_address, get_contract_address(), settings_id, name, description, settings,
            );
        }
    }
} 