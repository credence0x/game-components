#[derive(Drop, Serde, Introspect)]
pub struct GameDetail {
    pub name: ByteArray,
    pub value: ByteArray,
}