#[derive(Drop, Serde, Introspect)]
pub struct GameObjective {
    pub name: ByteArray,
    pub value: ByteArray,
}
