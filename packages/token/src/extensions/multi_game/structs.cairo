#[derive(Drop, Serde, starknet::Store)]
pub struct GameMetadata {
    pub creator_token_id: u64,
    pub contract_address: starknet::ContractAddress,
    pub name: felt252,
    pub description: ByteArray,
    pub developer: felt252,
    pub publisher: felt252,
    pub genre: felt252,
    pub image: ByteArray,
    pub color: ByteArray,
    pub client_url: ByteArray,
    pub renderer_address: starknet::ContractAddress,
    pub settings_address: starknet::ContractAddress,
    pub objectives_address: starknet::ContractAddress,
}
