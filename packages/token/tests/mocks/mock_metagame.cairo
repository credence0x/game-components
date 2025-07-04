use starknet::ContractAddress;

// Mock Metagame contract for testing TokenComponent
#[starknet::contract]
pub mod MockMetagame {
    use starknet::ContractAddress;
    use starknet::storage::{StoragePointerReadAccess, StoragePointerWriteAccess};

    #[storage]
    struct Storage {
        minigame_token_address: ContractAddress,
    }

    #[constructor]
    fn constructor(ref self: ContractState, minigame_token_address: ContractAddress) {
        self.minigame_token_address.write(minigame_token_address);
    }

    // Function to check if a game is registered (always returns true for testing)
    #[abi(embed_v0)]
    fn is_game_registered(self: @ContractState, game_address: ContractAddress) -> bool {
        true
    }
}
