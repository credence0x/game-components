use starknet::ContractAddress;
use crate::structs::game_details::GameDetail;
use crate::structs::settings::GameSettingDetails;
use crate::structs::objectives::GameObjective;

pub const IMINIGAME_ID: felt252 =
    0x02c0f9265d397c10970f24822e4b57cac7d8895f8c449b7c9caaa26910499704;
pub const IMINIGAME_SETTINGS_ID: felt252 =
    0x0379f4343538c65a38349fb1318328629dd950d3624101aeaac1b4bd45a39eff;
pub const IMINIGAME_OBJECTIVES_ID: felt252 =
    0x0213cfcf73543e549f00c7cad49cf27a1e544d71315ff981930aaf77ac0709bd;

#[starknet::interface]
pub trait IMinigame<TState> {
    fn mint(
        ref self: TState,
        player_name: Option<felt252>,
        settings_id: Option<u32>,
        start: Option<u64>,
        end: Option<u64>,
        objective_ids: Option<Span<u32>>,
        context: Option<ByteArray>,
        client_url: Option<ByteArray>,
        renderer_address: Option<ContractAddress>,
        to: ContractAddress,
        soulbound: bool,
    ) -> u64;
    fn namespace(self: @TState) -> ByteArray;
    fn token_address(self: @TState) -> ContractAddress;
}

#[starknet::interface]
pub trait IMinigameTokenData<TState> {
    fn score(self: @TState, token_id: u64) -> u32;
    fn game_over(self: @TState, token_id: u64) -> bool;
}

#[starknet::interface]
pub trait IMinigameDetails<TState> {
    fn token_description(self: @TState, token_id: u64) -> ByteArray;
    fn game_details(self: @TState, token_id: u64) -> Span<GameDetail>;
}

#[starknet::interface]
pub trait IMinigameDetailsSVG<TState> {
    fn game_details_svg(self: @TState, token_id: u64) -> ByteArray;
}

#[starknet::interface]
pub trait IMinigameSettings<TState> {
    fn setting_exists(self: @TState, settings_id: u32) -> bool;
    fn settings(self: @TState, settings_id: u32) -> GameSettingDetails;
}

#[starknet::interface]
pub trait IMinigameSettingsSVG<TState> {
    fn settings_svg(self: @TState, settings_id: u32) -> ByteArray;
}

#[starknet::interface]
pub trait IMinigameObjectives<TState> {
    fn objective_exists(self: @TState, objective_id: u32) -> bool;
    fn completed_objective(self: @TState, token_id: u64, objective_id: u32) -> bool;
    fn objectives(self: @TState, token_id: u64) -> Span<GameObjective>;
}

#[starknet::interface]
pub trait IMinigameObjectivesSVG<TState> {
    fn objectives_svg(self: @TState, token_id: u64) -> ByteArray;
}

#[starknet::interface]
pub trait IMinigameTokenUri<TState> {
    fn token_uri(self: @TState, token_id: u256) -> ByteArray;
}

