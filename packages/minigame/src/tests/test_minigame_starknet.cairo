use starknet::{ContractAddress, contract_address_const};
use snforge_std::{declare, ContractClassTrait, DeclareResultTrait};

use openzeppelin_introspection::src5::SRC5Component::SRC5Impl;
use crate::interface::{
    IMinigame, IMinigameDispatcher, IMinigameDispatcherTrait, IMinigameScore,
    IMinigameScoreDispatcher, IMinigameScoreDispatcherTrait, IMinigameDetails,
    IMinigameDetailsDispatcher, IMinigameDetailsDispatcherTrait, IMinigameSettings,
    IMinigameSettingsDispatcher, IMinigameSettingsDispatcherTrait, IMinigameObjectives,
    IMinigameObjectivesDispatcher, IMinigameObjectivesDispatcherTrait, IMINIGAME_ID,
    IMINIGAME_SETTINGS_ID, IMINIGAME_OBJECTIVES_ID,
};
use crate::tests::mocks::minigame_starknet_mock::{
    IMinigameStarknetMock, IMinigameStarknetMockDispatcher, IMinigameStarknetMockDispatcherTrait,
    IMinigameStarknetMockInit, IMinigameStarknetMockInitDispatcher,
    IMinigameStarknetMockInitDispatcherTrait,
};

// Test constants
const GAME_CREATOR: felt252 = 'creator';
const GAME_NAME: felt252 = 'TestGame';
const GAME_DEVELOPER: felt252 = 'developer';
const GAME_PUBLISHER: felt252 = 'publisher';
const GAME_GENRE: felt252 = 'strategy';
const GAME_NAMESPACE: felt252 = 'test_namespace';
const PLAYER_NAME: felt252 = 'player1';
const PLAYER_ADDRESS: felt252 = 'player_addr';
const TOKEN_ADDRESS: felt252 = 'token_addr';

fn deploy_minigame_starknet_mock(
    supports_settings: bool, supports_objectives: bool,
) -> ContractAddress {
    let contract = declare("minigame_starknet_mock").unwrap().contract_class();
    let mut constructor_calldata = array![];

    // Constructor arguments
    constructor_calldata.append(GAME_CREATOR); // game_creator
    constructor_calldata.append(GAME_NAME); // game_name
    constructor_calldata.append(4); // game_description length
    constructor_calldata.append('Test'); // game_description
    constructor_calldata.append('Game'); // game_description
    constructor_calldata.append('Desc'); // game_description
    constructor_calldata.append('ription'); // game_description
    constructor_calldata.append(GAME_DEVELOPER); // game_developer
    constructor_calldata.append(GAME_PUBLISHER); // game_publisher
    constructor_calldata.append(GAME_GENRE); // game_genre
    constructor_calldata.append(2); // game_image length
    constructor_calldata.append('img'); // game_image
    constructor_calldata.append('url'); // game_image
    constructor_calldata.append(0); // game_color (None)
    constructor_calldata.append(0); // client_url (None)
    constructor_calldata.append(0); // renderer_address (None)
    constructor_calldata.append(0); // settings_address (None)
    constructor_calldata.append(0); // objectives_address (None)
    constructor_calldata.append(GAME_NAMESPACE); // game_namespace
    constructor_calldata.append(TOKEN_ADDRESS); // token_address
    constructor_calldata.append(if supports_settings {
        1
    } else {
        0
    }); // supports_settings
    constructor_calldata.append(if supports_objectives {
        1
    } else {
        0
    }); // supports_objectives

    let (contract_address, _) = contract.deploy(@constructor_calldata).unwrap();
    contract_address
}

#[test]
fn test_basic_minigame_functionality() {
    let contract_address = deploy_minigame_starknet_mock(true, true);
    let minigame = IMinigameDispatcher { contract_address };

    // Test basic getters
    assert_eq!(minigame.namespace(), GAME_NAMESPACE);
    assert_eq!(minigame.token_address(), contract_address_const::<TOKEN_ADDRESS>());
}

#[test]
fn test_mint_basic() {
    let contract_address = deploy_minigame_starknet_mock(false, false);
    let minigame = IMinigameDispatcher { contract_address };
    let player_addr = contract_address_const::<PLAYER_ADDRESS>();

    let token_id = minigame
        .mint(
            Option::Some(PLAYER_NAME),
            Option::None, // no settings
            Option::None, // no start time
            Option::None, // no end time
            Option::None, // no objectives
            Option::None, // no context
            Option::None, // no client_url
            Option::None, // no renderer_address
            player_addr,
            false // not soulbound
        );

    assert!(token_id > 0, "Token ID should be greater than 0");
}

#[test]
fn test_mint_with_settings_supported() {
    let contract_address = deploy_minigame_starknet_mock(true, false);
    let minigame = IMinigameDispatcher { contract_address };
    let mock = IMinigameStarknetMockDispatcher { contract_address };
    let player_addr = contract_address_const::<PLAYER_ADDRESS>();

    // Create a setting first
    mock.create_settings_difficulty("Easy Mode", "Easy difficulty setting", 1);

    let token_id = minigame
        .mint(
            Option::Some(PLAYER_NAME),
            Option::Some(1), // settings_id
            Option::None,
            Option::None,
            Option::None,
            Option::None,
            Option::None,
            Option::None,
            player_addr,
            false,
        );

    assert!(token_id > 0, "Token ID should be greater than 0");
}

#[test]
fn test_mint_with_objectives_supported() {
    let contract_address = deploy_minigame_starknet_mock(false, true);
    let minigame = IMinigameDispatcher { contract_address };
    let mock = IMinigameStarknetMockDispatcher { contract_address };
    let player_addr = contract_address_const::<PLAYER_ADDRESS>();

    // Create an objective first
    mock.create_objective_score(100);

    let token_id = minigame
        .mint(
            Option::Some(PLAYER_NAME),
            Option::None,
            Option::None,
            Option::None,
            Option::Some(array![1].span()), // objective_ids
            Option::None,
            Option::None,
            Option::None,
            player_addr,
            false,
        );

    assert!(token_id > 0, "Token ID should be greater than 0");
}

#[test]
#[should_panic(expected: ('Minigame: Settings interface not supported',))]
fn test_mint_with_settings_not_supported() {
    let contract_address = deploy_minigame_starknet_mock(false, false);
    let minigame = IMinigameDispatcher { contract_address };
    let player_addr = contract_address_const::<PLAYER_ADDRESS>();

    minigame
        .mint(
            Option::Some(PLAYER_NAME),
            Option::Some(1), // settings_id - should fail
            Option::None,
            Option::None,
            Option::None,
            Option::None,
            Option::None,
            Option::None,
            player_addr,
            false,
        );
}

#[test]
#[should_panic(expected: ('Minigame: Objectives interface not supported',))]
fn test_mint_with_objectives_not_supported() {
    let contract_address = deploy_minigame_starknet_mock(false, false);
    let minigame = IMinigameDispatcher { contract_address };
    let player_addr = contract_address_const::<PLAYER_ADDRESS>();

    minigame
        .mint(
            Option::Some(PLAYER_NAME),
            Option::None,
            Option::None,
            Option::None,
            Option::Some(array![1].span()), // objective_ids - should fail
            Option::None,
            Option::None,
            Option::None,
            player_addr,
            false,
        );
}

#[test]
fn test_src5_interface_registration() {
    let contract_address = deploy_minigame_starknet_mock(true, true);
    let src5 = SRC5Impl::new(contract_address);

    // Test that base minigame interface is always registered
    assert!(src5.supports_interface(IMINIGAME_ID), "Should support IMinigame interface");

    // Test that settings interface is registered when supported
    assert!(
        src5.supports_interface(IMINIGAME_SETTINGS_ID),
        "Should support IMinigameSettings interface",
    );

    // Test that objectives interface is registered when supported
    assert!(
        src5.supports_interface(IMINIGAME_OBJECTIVES_ID),
        "Should support IMinigameObjectives interface",
    );
}

#[test]
fn test_settings_functionality() {
    let contract_address = deploy_minigame_starknet_mock(true, false);
    let settings = IMinigameSettingsDispatcher { contract_address };
    let mock = IMinigameStarknetMockDispatcher { contract_address };

    // Create settings
    mock.create_settings_difficulty("Hard Mode", "Hard difficulty setting", 5);

    // Test settings exist
    assert!(settings.setting_exists(1), "Setting should exist");
    assert!(!settings.setting_exists(999), "Non-existent setting should not exist");

    // Test get settings
    let setting_details = settings.settings(1);
    assert_eq!(setting_details.name, "Hard Mode");
    assert_eq!(setting_details.description, "Hard difficulty setting");
    assert_eq!(setting_details.settings.len(), 1);

    let difficulty_setting = *setting_details.settings.at(0);
    assert_eq!(difficulty_setting.name, "Difficulty");
    assert_eq!(difficulty_setting.value, "5");
}

#[test]
fn test_objectives_functionality() {
    let contract_address = deploy_minigame_starknet_mock(false, true);
    let objectives = IMinigameObjectivesDispatcher { contract_address };
    let mock = IMinigameStarknetMockDispatcher { contract_address };
    let minigame = IMinigameDispatcher { contract_address };
    let player_addr = contract_address_const::<PLAYER_ADDRESS>();

    // Create objective
    mock.create_objective_score(200);

    // Test objective exists
    assert!(objectives.objective_exists(1), "Objective should exist");
    assert!(!objectives.objective_exists(999), "Non-existent objective should not exist");

    // Mint a token with this objective
    let token_id = minigame
        .mint(
            Option::Some(PLAYER_NAME),
            Option::None,
            Option::None,
            Option::None,
            Option::Some(array![1].span()),
            Option::None,
            Option::None,
            Option::None,
            player_addr,
            false,
        );

    // Test objective completion (should be false initially)
    assert!(
        !objectives.completed_objective(token_id, 1), "Objective should not be completed initially",
    );
}

#[test]
fn test_score_functionality() {
    let contract_address = deploy_minigame_starknet_mock(false, true);
    let score = IMinigameScoreDispatcher { contract_address };
    let objectives = IMinigameObjectivesDispatcher { contract_address };
    let mock = IMinigameStarknetMockDispatcher { contract_address };
    let minigame = IMinigameDispatcher { contract_address };
    let player_addr = contract_address_const::<PLAYER_ADDRESS>();

    // Create objective
    mock.create_objective_score(100);

    // Mint token
    let token_id = minigame
        .mint(
            Option::Some(PLAYER_NAME),
            Option::None,
            Option::None,
            Option::None,
            Option::Some(array![1].span()),
            Option::None,
            Option::None,
            Option::None,
            player_addr,
            false,
        );

    // Start game
    mock.start_game(token_id);
    assert_eq!(score.score(token_id), 0, "Initial score should be 0");

    // End game with score
    mock.end_game(token_id, 150);
    assert_eq!(score.score(token_id), 150, "Score should be updated");

    // Check if objective is completed
    assert!(
        objectives.completed_objective(token_id, 1), "Objective should be completed with score 150",
    );
}

#[test]
fn test_full_integration_scenario() {
    let contract_address = deploy_minigame_starknet_mock(true, true);
    let minigame = IMinigameDispatcher { contract_address };
    let settings = IMinigameSettingsDispatcher { contract_address };
    let objectives = IMinigameObjectivesDispatcher { contract_address };
    let score = IMinigameScoreDispatcher { contract_address };
    let mock = IMinigameStarknetMockDispatcher { contract_address };
    let player_addr = contract_address_const::<PLAYER_ADDRESS>();

    // Setup: Create settings and objectives
    mock.create_settings_difficulty("Expert Mode", "Expert difficulty setting", 10);
    mock.create_objective_score(500);

    // Verify setup
    assert!(settings.setting_exists(1), "Settings should exist");
    assert!(objectives.objective_exists(1), "Objective should exist");

    // Mint a token with both settings and objectives
    let token_id = minigame
        .mint(
            Option::Some(PLAYER_NAME),
            Option::Some(1), // settings_id
            Option::None,
            Option::None,
            Option::Some(array![1].span()), // objective_ids
            Option::Some("Game context data"),
            Option::None,
            Option::None,
            player_addr,
            false,
        );

    // Play the game
    mock.start_game(token_id);
    assert_eq!(score.score(token_id), 0, "Initial score should be 0");

    // Complete with high score
    mock.end_game(token_id, 750);
    assert_eq!(score.score(token_id), 750, "Final score should be 750");

    // Verify objective completion
    assert!(
        objectives.completed_objective(token_id, 1), "High score objective should be completed",
    );

    // Verify settings are applied
    let game_settings = settings.settings(1);
    assert_eq!(game_settings.name, "Expert Mode");

    let difficulty_setting = *game_settings.settings.at(0);
    assert_eq!(difficulty_setting.value, "10");
}
