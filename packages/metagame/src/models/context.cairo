#[derive(Drop, Serde, Introspect)]
pub struct GameContextDetails {
    pub name: ByteArray,
    pub description: ByteArray,
    pub context: Span<GameContext>,
}

#[derive(Drop, Serde, Introspect)]
pub struct GameContext {
    pub name: ByteArray,
    pub value: ByteArray,
}
