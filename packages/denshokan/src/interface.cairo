use starknet::ContractAddress;

#[starknet::interface]
pub trait IDenshokan<TContractState> {
    fn get_game_id(self: @TContractState, game_address: ContractAddress) -> u64;
    fn is_game_playable(self: @TContractState, token_id: u64) -> bool;
    fn settings_id(self: @TContractState, token_id: u64) -> u32;
    fn objective_ids(self: @TContractState, token_id: u64) -> Span<u32>;

    fn register_game(
        ref self: TContractState,
        creator_address: ContractAddress,
        name: felt252,
        description: ByteArray,
        developer: felt252,
        publisher: felt252,
        genre: felt252,
        image: ByteArray,
        color: Option<ByteArray>,
    );
    fn mint(
        ref self: TContractState,
        game_id: Option<u64>,
        player_name: Option<felt252>,
        settings_id: Option<u32>,
        start: Option<u64>,
        end: Option<u64>,
        objective_ids: Option<Span<u32>>,
        context: Option<ByteArray>,
        to: ContractAddress,
        soulbound: bool,
    ) -> u64;
    fn set_token_metadata(
        ref self: TContractState,
        token_id: u64,
        game_id: u64,
        player_name: Option<felt252>,
        settings_id: u32,
        start: Option<u64>,
        end: Option<u64>,
        objective_ids: Option<Span<u32>>,
        context: Option<ByteArray>,
    );
    fn update_game(ref self: TContractState, token_id: u64);
    fn end_game(ref self: TContractState, token_id: u64);
    fn create_objective(ref self: TContractState, game_id: u64, objective_id: u32, data: ByteArray);
    fn create_settings(ref self: TContractState, game_id: u64, settings_id: u32, data: ByteArray);
}
