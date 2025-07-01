
fn set_token_metadata(
    ref self: TContractState,
    token_id: u64,
    game_address: ContractAddress,
    player_name: Option<felt252>,
    settings_id: u32,
    start: Option<u64>,
    end: Option<u64>,
    objective_ids: Option<Span<u32>>,
    context: Option<ByteArray>,
);