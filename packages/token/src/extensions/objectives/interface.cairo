use starknet::ContractAddress;
use game_components_minigame::extensions::objectives::structs::GameObjective;
use crate::extensions::objectives::structs::TokenObjective;

pub const IMINIGAME_TOKEN_OBJECTIVES_ID: felt252 = 0x0;

#[starknet::interface]
pub trait IMinigameTokenObjectives<TState> {
    fn objectives_count(self: @TState, token_id: u64) -> u32;
    fn objectives(self: @TState, token_id: u64) -> Array<TokenObjective>;
    fn objective_ids(self: @TState, token_id: u64) -> Span<u32>;
    // fn objective_completed(self: @TState, token_id: u64, objective_id: u32) -> bool;
    fn all_objectives_completed(self: @TState, token_id: u64) -> bool;

    fn create_objective(
        ref self: TState, 
        game_address: ContractAddress, 
        objective_id: u32, 
        objective_data: GameObjective,
    );
}