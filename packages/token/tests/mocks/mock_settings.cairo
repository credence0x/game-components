use game_components_minigame::extensions::settings::interface::{
    IMinigameSettings, IMINIGAME_SETTINGS_ID,
};
use game_components_minigame::extensions::settings::structs::{GameSettingDetails, GameSetting};
use openzeppelin_introspection::interface::ISRC5;

// Mock Settings contract for testing
#[starknet::contract]
pub mod MockSettings {
    use super::*;
    use starknet::storage::{Map, StorageMapReadAccess, StorageMapWriteAccess};

    #[storage]
    struct Storage {
        settings_exist: Map<u32, bool>,
    }

    #[constructor]
    fn constructor(ref self: ContractState) {
        // Mark some settings as existing for testing
        self.settings_exist.write(1, true);
        self.settings_exist.write(2, true);
        self.settings_exist.write(99, true);
    }

    // Implement IMinigameSettings
    #[abi(embed_v0)]
    impl MinigameSettingsImpl of IMinigameSettings<ContractState> {
        fn settings_exist(self: @ContractState, settings_id: u32) -> bool {
            self.settings_exist.read(settings_id)
        }

        fn settings(self: @ContractState, settings_id: u32) -> GameSettingDetails {
            // Return mock settings
            GameSettingDetails {
                name: "Mock Settings",
                description: "Test settings for unit tests",
                settings: array![GameSetting { name: "difficulty", value: "medium" }].span(),
            }
        }

        fn settings_svg(self: @ContractState, settings_id: u32) -> ByteArray {
            "<svg>Mock Settings SVG</svg>"
        }
    }

    // Implement ISRC5
    #[abi(embed_v0)]
    impl SRC5Impl of ISRC5<ContractState> {
        fn supports_interface(self: @ContractState, interface_id: felt252) -> bool {
            interface_id == IMINIGAME_SETTINGS_ID
                || interface_id == openzeppelin_introspection::interface::ISRC5_ID
        }
    }

    // Helper function for testing
    #[abi(embed_v0)]
    fn add_settings(ref self: ContractState, settings_id: u32) {
        self.settings_exist.write(settings_id, true);
    }
}
