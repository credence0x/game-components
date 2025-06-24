use crate::models::context::GameContextDetails;
use starknet::ContractAddress;

pub const IMETAGAME_ID: felt252 =
    0x0260d5160a283a03815f6c3799926c7bdbec5f22e759f992fb8faf172243ab20;
pub const IMETAGAME_CONTEXT_ID: felt252 =
    0x0c2e78065b81a310a1cb470d14a7b88875542ad05286b3263cf3c254082386e;

#[starknet::interface]
pub trait IMetagame<TContractState> {
    fn namespace(self: @TContractState) -> ByteArray;
    fn minigame_token_address(self: @TContractState) -> ContractAddress;
}

#[starknet::interface]
pub trait IMetagameContext<TContractState> {
    fn has_context(self: @TContractState, token_id: u64) -> bool;
    fn context(self: @TContractState, token_id: u64) -> GameContextDetails;
}

#[starknet::interface]
pub trait IMetagameContextSVG<TContractState> {
    fn context_svg(self: @TContractState, token_id: u64) -> ByteArray;
}

