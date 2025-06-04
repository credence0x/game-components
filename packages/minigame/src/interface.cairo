use starknet::{ContractAddress, contract_address_const};
use dojo::world::{WorldStorage, WorldStorageTrait, IWorldDispatcher};

pub const IMINIGAME_ID: felt252 =
    0x02c0f9265d397c10970f24822e4b57cac7d8895f8c449b7c9caaa26910499704;

#[starknet::interface]
pub trait IMinigame<TState> {
    fn mint(
        ref self: TState,
        player_name: Option<felt252>,
        settings_id: Option<u32>,
        start: Option<u64>,
        end: Option<u64>,
        objective_ids: Option<Span<u32>>,
        to: ContractAddress,
        soulbound: bool,
    ) -> u64;
    fn namespace(self: @TState) -> ByteArray;
}

#[starknet::interface]
pub trait IMinigameDetails<TState> {
    fn score(self: @TState, token_id: u64) -> u32;
}

#[starknet::interface]
pub trait IMinigameSettings<TState> {
    fn setting_exists(self: @TState, settings_id: u32) -> bool;
    fn settings(self: @TState, settings_id: u32) -> ByteArray;
}

#[starknet::interface]
pub trait IMinigameSettingsURI<TState> {
    fn settings_uri(self: @TState, settings_id: u32) -> ByteArray;
}

#[starknet::interface]
pub trait IMinigameObjectives<TState> {
    fn objective_exists(self: @TState, objective_id: u32) -> bool;
    fn completed_objective(self: @TState, token_id: u64, objective_id: u32) -> bool;
    fn objectives(self: @TState, token_id: u64) -> ByteArray;
}

#[starknet::interface]
pub trait IMinigameObjectivesURI<TState> {
    fn objectives_uri(self: @TState, token_id: u64) -> ByteArray;
}

#[starknet::interface]
pub trait IMinigameTokenUri<TState> {
    fn token_uri(self: @TState, token_id: u256) -> ByteArray;
}

#[generate_trait]
pub impl WorldImpl of WorldTrait {
    fn contract_address(self: @WorldStorage, contract_name: @ByteArray) -> ContractAddress {
        match self.dns(contract_name) {
            Option::Some((contract_address, _)) => { (contract_address) },
            Option::None => { (contract_address_const::<0x0>()) },
        }
    }

    // Create a Store from a dispatcher
    // https://github.com/dojoengine/dojo/blob/main/crates/dojo/core/src/contract/components/world_provider.cairo
    // https://github.com/dojoengine/dojo/blob/main/crates/dojo/core/src/world/storage.cairo
    #[inline(always)]
    fn storage(dispatcher: IWorldDispatcher, namespace: @ByteArray) -> WorldStorage {
        (WorldStorageTrait::new(dispatcher, namespace))
    }
}

