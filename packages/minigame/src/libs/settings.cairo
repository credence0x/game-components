use game_components_denshokan::interface::{IDenshokanDispatcher, IDenshokanDispatcherTrait};
use starknet::ContractAddress;
use crate::models::settings::GameSetting;

/// Gets the settings ID for a game token
/// 
/// # Arguments
/// * `denshokan_address` - The address of the denshokan contract
/// * `token_id` - The token ID to get settings for
/// 
/// # Returns
/// * `u32` - The settings ID
pub fn get_settings_id(denshokan_address: ContractAddress, token_id: u64) -> u32 {
    let denshokan_dispatcher = IDenshokanDispatcher { contract_address: denshokan_address };
    denshokan_dispatcher.settings_id(token_id)
}

/// Creates settings in the denshokan contract
/// 
/// # Arguments
/// * `denshokan_address` - The address of the denshokan contract
/// * `game_address` - The address of the game contract creating the settings
/// * `settings_id` - The ID of the settings to create
/// * `data` - The settings data
pub fn create_settings(denshokan_address: ContractAddress, game_address: ContractAddress, settings_id: u32, name: ByteArray, description: ByteArray, settings: Span<GameSetting>) {
    let denshokan_dispatcher = IDenshokanDispatcher { contract_address: denshokan_address };
    denshokan_dispatcher.create_settings(game_address, settings_id, name, description, settings);
}

/// Asserts that a setting exists by checking the game contract
/// 
/// # Arguments
/// * `game_contract` - Reference to the game contract implementing IMinigameSettings
/// * `settings_id` - The ID of the setting to check
pub fn assert_setting_exists<T, +crate::interface::IMinigameSettings<T>>(game_contract: @T, settings_id: u32) {
    let setting_exists = game_contract.setting_exists(settings_id);
    if !setting_exists {
        panic!("Game: Setting ID {} does not exist", settings_id);
    }
} 