use starknet::ContractAddress;
use game_components_minigame::extensions::settings::structs::GameSetting;

pub const IMINIGAME_TOKEN_SETTINGS_ID: felt252 = 0x0;

#[starknet::interface]
pub trait IMinigameTokenSettings<TState> {
    fn create_settings(
        ref self: TState, 
        game_address: ContractAddress,
        settings_id: u32, 
        name: ByteArray, 
        description: ByteArray, 
        settings_data: Span<GameSetting>
    );
}