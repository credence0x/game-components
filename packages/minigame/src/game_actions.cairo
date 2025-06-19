use game_components_denshokan::interface::{IDenshokanDispatcher, IDenshokanDispatcherTrait};
use starknet::ContractAddress;
use openzeppelin_token::erc721::interface::{IERC721Dispatcher, IERC721DispatcherTrait};

/// Library functions for game actions that can be used across multiple contracts
pub mod game_actions {
    use super::{IDenshokanDispatcher, IDenshokanDispatcherTrait, ContractAddress, IERC721Dispatcher, IERC721DispatcherTrait};

    /// Performs pre-action validation including token ownership and game playability
    /// 
    /// # Arguments
    /// * `denshokan_address` - The address of the denshokan contract
    /// * `token_id` - The game token ID to validate
    pub fn pre_action(denshokan_address: ContractAddress, token_id: u64) {
        assert_token_ownership(denshokan_address, token_id);
        assert_game_token_playable(denshokan_address, token_id);
    }

    /// Performs post-action updates to the game state
    /// 
    /// # Arguments
    /// * `denshokan_address` - The address of the denshokan contract
    /// * `token_id` - The game token ID to update
    /// * `game_over` - Whether the game has ended
    pub fn post_action(denshokan_address: ContractAddress, token_id: u64, game_over: bool) {
        let denshokan_dispatcher = IDenshokanDispatcher { contract_address: denshokan_address };
        if game_over {
            denshokan_dispatcher.end_game(token_id);
        } else {
            denshokan_dispatcher.update_game(token_id);
        }
    }

    /// Asserts that the caller owns the specified token
    /// 
    /// # Arguments
    /// * `denshokan_address` - The address of the denshokan contract
    /// * `token_id` - The token ID to check ownership for
    pub fn assert_token_ownership(denshokan_address: ContractAddress, token_id: u64) {
        let erc721_dispatcher = IERC721Dispatcher { contract_address: denshokan_address };
        let token_owner = erc721_dispatcher.owner_of(token_id.into());
        assert!(
            token_owner == starknet::get_caller_address(),
            "Caller is not owner of token {}",
            token_id,
        );
    }

    /// Asserts that the game token is in a playable state
    /// 
    /// # Arguments
    /// * `denshokan_address` - The address of the denshokan contract
    /// * `token_id` - The token ID to check playability for
    pub fn assert_game_token_playable(denshokan_address: ContractAddress, token_id: u64) {
        let denshokan_dispatcher = IDenshokanDispatcher { contract_address: denshokan_address };
        let is_playable = denshokan_dispatcher.is_game_token_playable(token_id);
        assert!(is_playable, "Game is not playable");
    }
} 