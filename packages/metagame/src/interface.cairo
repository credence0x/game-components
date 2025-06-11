use crate::models::context::GameContextDetails;

pub const IMETAGAME_ID: felt252 =
    0x0260d5160a283a03815f6c3799926c7bdbec5f22e759f992fb8faf172243ab20;

#[starknet::interface]
pub trait IMetagame<TContractState> {
    fn namespace(self: @TContractState) -> ByteArray;
}

#[starknet::interface]
pub trait IMetagameContext<TContractState> {
    fn has_context(self: @TContractState, token_id: u64) -> bool;
    fn context(self: @TContractState, token_id: u64) -> GameContextDetails;
}

#[starknet::interface]
pub trait IMetagameContextURI<TContractState> {
    fn context_uri(self: @TContractState, token_id: u64) -> ByteArray;
}

