use game_components_metagame::extensions::context::interface::{IMetagameContext, IMETAGAME_CONTEXT_ID};
use game_components_metagame::extensions::context::structs::{GameContextDetails, GameContext};
use openzeppelin_introspection::interface::ISRC5;

// Mock Context contract for testing
#[starknet::contract]
pub mod MockContext {
    use super::*;
    use starknet::storage::{Map, StorageMapReadAccess, StorageMapWriteAccess};
    
    #[storage]
    struct Storage {
        token_has_context: Map<u64, bool>,
    }
    
    // Implement IMetagameContext
    #[abi(embed_v0)]
    impl MetagameContextImpl of IMetagameContext<ContractState> {
        fn has_context(self: @ContractState, token_id: u64) -> bool {
            self.token_has_context.read(token_id)
        }
        
        fn context(self: @ContractState, token_id: u64) -> GameContextDetails {
            // Return mock context
            GameContextDetails {
                context_id: 1,
                created_by: starknet::contract_address_const::<0x123>(),
                name: "Test Tournament",
                description: "A test tournament context",
                start: 1000,
                end: 2000,
                context: array![
                    GameContext {
                        id: 1,
                        details: "Tournament Round 1"
                    }
                ].span()
            }
        }
        
        fn context_svg(self: @ContractState, token_id: u64) -> ByteArray {
            "<svg>Mock Context SVG</svg>"
        }
    }
    
    // Implement ISRC5
    #[abi(embed_v0)]
    impl SRC5Impl of ISRC5<ContractState> {
        fn supports_interface(self: @ContractState, interface_id: felt252) -> bool {
            interface_id == IMETAGAME_CONTEXT_ID ||
            interface_id == openzeppelin_introspection::interface::ISRC5_ID
        }
    }
    
    // Helper function for testing
    #[abi(embed_v0)]
    fn set_token_context(ref self: ContractState, token_id: u64, has_context: bool) {
        self.token_has_context.write(token_id, has_context);
    }
}