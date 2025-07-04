use starknet::ContractAddress;
use game_components_minigame::interface::{IMinigame, IMinigameTokenData, IMINIGAME_ID};
use openzeppelin_introspection::interface::ISRC5;

// Mock Minigame contract for testing
#[starknet::contract]
pub mod MockMinigame {
    use super::*;
    use starknet::storage::{StoragePointerReadAccess, StoragePointerWriteAccess};

    #[storage]
    struct Storage {
        token_address: ContractAddress,
        settings_address: ContractAddress,
        objectives_address: ContractAddress,
        // Score tracking for testing
        token_scores: starknet::storage::Map<u64, u32>,
        token_game_over: starknet::storage::Map<u64, bool>,
    }

    #[constructor]
    fn constructor(
        ref self: ContractState,
        token_address: ContractAddress,
        settings_address: ContractAddress,
        objectives_address: ContractAddress,
    ) {
        self.token_address.write(token_address);
        self.settings_address.write(settings_address);
        self.objectives_address.write(objectives_address);
    }

    // Implement IMinigame
    #[abi(embed_v0)]
    impl MinigameImpl of IMinigame<ContractState> {
        fn token_address(self: @ContractState) -> ContractAddress {
            self.token_address.read()
        }

        fn settings_address(self: @ContractState) -> ContractAddress {
            self.settings_address.read()
        }

        fn objectives_address(self: @ContractState) -> ContractAddress {
            self.objectives_address.read()
        }
    }

    // Implement IMinigameTokenData
    #[abi(embed_v0)]
    impl MinigameTokenDataImpl of IMinigameTokenData<ContractState> {
        fn score(self: @ContractState, token_id: u64) -> u32 {
            self.token_scores.read(token_id)
        }

        fn game_over(self: @ContractState, token_id: u64) -> bool {
            self.token_game_over.read(token_id)
        }
    }

    // Implement ISRC5
    #[abi(embed_v0)]
    impl SRC5Impl of ISRC5<ContractState> {
        fn supports_interface(self: @ContractState, interface_id: felt252) -> bool {
            interface_id == IMINIGAME_ID
                || interface_id == openzeppelin_introspection::interface::ISRC5_ID
        }
    }

    // Helper functions for testing
    #[abi(embed_v0)]
    fn set_score(ref self: ContractState, token_id: u64, score: u32) {
        self.token_scores.write(token_id, score);
    }

    #[abi(embed_v0)]
    fn set_game_over(ref self: ContractState, token_id: u64, game_over: bool) {
        self.token_game_over.write(token_id, game_over);
    }
}

// Interface for setter methods
#[starknet::interface]
trait IMockMinigameSetter<TContractState> {
    fn set_score(ref self: TContractState, token_id: u64, score: u32);
    fn set_game_over(ref self: TContractState, token_id: u64, game_over: bool);
}
