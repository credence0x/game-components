#[derive(Drop, Serde, Introspect)]
pub struct GameContext {
    pub name: ByteArray,
    pub value: ByteArray,
}
