use game_components_minigame::extensions::objectives::interface::{IMinigameObjectives, IMINIGAME_OBJECTIVES_ID};
use game_components_minigame::extensions::objectives::structs::ObjectiveDetails;
use openzeppelin_introspection::interface::ISRC5;

// Mock Objectives contract for testing
#[starknet::contract]
pub mod MockObjectives {
    use super::*;
    use starknet::storage::{Map, StorageMapReadAccess, StorageMapWriteAccess};
    
    #[storage]
    struct Storage {
        objective_exists: Map<u32, bool>,
    }
    
    #[constructor]
    fn constructor(ref self: ContractState) {
        // Mark some objectives as existing for testing
        self.objective_exists.write(1, true);
        self.objective_exists.write(2, true);
        self.objective_exists.write(3, true);
        self.objective_exists.write(100, true);
        self.objective_exists.write(101, true);
    }
    
    // Implement IMinigameObjectives
    #[abi(embed_v0)]
    impl MinigameObjectivesImpl of IMinigameObjectives<ContractState> {
        fn objective_exists(self: @ContractState, objective_id: u32) -> bool {
            self.objective_exists.read(objective_id)
        }
        
        fn completed_objective(self: @ContractState, token_id: u64, objective_id: u32) -> bool {
            // Always return false for testing
            false
        }
        
        fn objectives(self: @ContractState, token_id: u64) -> Span<ObjectiveDetails> {
            // Return mock objectives
            array![
                ObjectiveDetails {
                    objective_id: 1,
                    points: 10,
                    name: "First Objective",
                    description: "Complete the first task",
                    is_completed: false,
                    is_required: true,
                },
                ObjectiveDetails {
                    objective_id: 2,
                    points: 20,
                    name: "Second Objective",
                    description: "Complete the second task",
                    is_completed: false,
                    is_required: false,
                }
            ].span()
        }
        
        fn objectives_svg(self: @ContractState, token_id: u64) -> ByteArray {
            "<svg>Mock Objectives SVG</svg>"
        }
    }
    
    // Implement ISRC5
    #[abi(embed_v0)]
    impl SRC5Impl of ISRC5<ContractState> {
        fn supports_interface(self: @ContractState, interface_id: felt252) -> bool {
            interface_id == IMINIGAME_OBJECTIVES_ID ||
            interface_id == openzeppelin_introspection::interface::ISRC5_ID
        }
    }
    
    // Helper function for testing
    #[abi(embed_v0)]
    fn add_objective(ref self: ContractState, objective_id: u32) {
        self.objective_exists.write(objective_id, true);
    }
}

// Interface for setter methods
#[starknet::interface]
trait IMockObjectivesSetter<TContractState> {
    fn add_objective(ref self: TContractState, objective_id: u32);
}