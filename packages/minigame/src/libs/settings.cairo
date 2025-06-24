use game_components_minigame_token::interface::{
    IMinigameTokenDispatcher, IMinigameTokenDispatcherTrait,
};
use starknet::ContractAddress;
use crate::models::settings::GameSetting;

/// Gets the settings ID for a game token
///
/// # Arguments
/// * `minigame_token_address` - The address of the minigame token contract
/// * `token_id` - The token ID to get settings for
///
/// # Returns
/// * `u32` - The settings ID
pub fn get_settings_id(minigame_token_address: ContractAddress, token_id: u64) -> u32 {
    let minigame_token_dispatcher = IMinigameTokenDispatcher {
        contract_address: minigame_token_address,
    };
    minigame_token_dispatcher.settings_id(token_id)
}

/// Creates settings in the minigame token contract
///
/// # Arguments
/// * `minigame_token_address` - The address of the minigame token contract
/// * `game_address` - The address of the game contract creating the settings
/// * `settings_id` - The ID of the settings to create
/// * `data` - The settings data
pub fn create_settings(
    minigame_token_address: ContractAddress,
    game_address: ContractAddress,
    settings_id: u32,
    name: ByteArray,
    description: ByteArray,
    settings: Span<GameSetting>,
) {
    let minigame_token_dispatcher = IMinigameTokenDispatcher {
        contract_address: minigame_token_address,
    };
    minigame_token_dispatcher
        .create_settings(game_address, settings_id, name, description, settings);
}

/// Asserts that a setting exists by checking the game contract
///
/// # Arguments
/// * `game_contract` - Reference to the game contract implementing IMinigameSettings
/// * `settings_id` - The ID of the setting to check
pub fn assert_setting_exists<T, +crate::interface::IMinigameSettings<T>>(
    game_contract: @T, settings_id: u32,
) {
    let setting_exists = game_contract.setting_exists(settings_id);
    if !setting_exists {
        panic!("Game: Setting ID {} does not exist", settings_id);
    }
}
