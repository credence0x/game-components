use game_components_denshokan::interface::{IDenshokanDispatcher, IDenshokanDispatcherTrait};
use starknet::ContractAddress;

/// Gets the objective IDs for a game token
///
/// # Arguments
/// * `denshokan_address` - The address of the denshokan contract
/// * `token_id` - The token ID to get objectives for
///
/// # Returns
/// * `Span<u32>` - The objective IDs
pub fn get_objective_ids(denshokan_address: ContractAddress, token_id: u64) -> Span<u32> {
    let denshokan_dispatcher = IDenshokanDispatcher { contract_address: denshokan_address };
    denshokan_dispatcher.objective_ids(token_id)
}

/// Creates an objective in the denshokan contract
///
/// # Arguments
/// * `denshokan_address` - The address of the denshokan contract
/// * `game_address` - The address of the game contract creating the objective
/// * `objective_id` - The ID of the objective to create
/// * `data` - The objective data
pub fn create_objective(
    denshokan_address: ContractAddress,
    game_address: ContractAddress,
    objective_id: u32,
    data: ByteArray,
) {
    let denshokan_dispatcher = IDenshokanDispatcher { contract_address: denshokan_address };
    denshokan_dispatcher.create_objective(game_address, objective_id, data);
}

/// Asserts that an objective exists by checking the game contract
///
/// # Arguments
/// * `game_contract` - Reference to the game contract implementing IMinigameObjectives
/// * `objective_id` - The ID of the objective to check
pub fn assert_objective_exists<T, +crate::interface::IMinigameObjectives<T>>(
    game_contract: @T, objective_id: u32,
) {
    let objective_exists = game_contract.objective_exists(objective_id);
    if !objective_exists {
        panic!("Game: Objective ID {} does not exist", objective_id);
    }
}
