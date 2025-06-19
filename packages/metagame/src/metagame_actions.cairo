use game_components_denshokan::interface::{IDenshokanDispatcher, IDenshokanDispatcherTrait};
use starknet::ContractAddress;

/// Library functions for metagame actions that can be used across multiple contracts
pub mod metagame_actions {
    use super::{IDenshokanDispatcher, IDenshokanDispatcherTrait, ContractAddress};

    /// Asserts that a game is registered in the denshokan
    /// 
    /// # Arguments
    /// * `denshokan_address` - The address of the denshokan contract
    /// * `game_address` - The address of the game contract to check
    pub fn assert_game_registered(denshokan_address: ContractAddress, game_address: ContractAddress) {
        let denshokan_dispatcher = IDenshokanDispatcher { contract_address: denshokan_address };
        let game_exists = denshokan_dispatcher.is_game_registered(game_address);
        assert!(game_exists, "Game is not registered");
    }
} 