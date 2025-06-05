#[derive(Drop, Serde, Introspect)]
pub struct GameSetting {
    pub name: ByteArray,
    pub value: ByteArray,
}