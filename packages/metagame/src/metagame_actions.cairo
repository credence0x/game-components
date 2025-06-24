use game_components_minigame_token::interface::{IMinigameTokenDispatcher, IMinigameTokenDispatcherTrait};
use starknet::ContractAddress;

/// Library functions for metagame actions that can be used across multiple contracts
pub mod metagame_actions {
    use super::{IMinigameTokenDispatcher, IMinigameTokenDispatcherTrait, ContractAddress};

    /// Asserts that a game is registered in the denshokan
    ///
    /// # Arguments
    /// * `denshokan_address` - The address of the denshokan contract
    /// * `game_address` - The address of the game contract to check
    pub fn assert_game_registered(
        minigame_token_address: ContractAddress, game_address: ContractAddress,
    ) {
        let minigame_token_dispatcher = IMinigameTokenDispatcher { contract_address: minigame_token_address };
        let game_exists = minigame_token_dispatcher.is_game_registered(game_address);
        assert!(game_exists, "Game is not registered");
    }
}
