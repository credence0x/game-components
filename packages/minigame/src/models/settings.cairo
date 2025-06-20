#[derive(Drop, Serde, Introspect)]
pub struct GameSettingDetails {
    pub name: ByteArray,
    pub description: ByteArray,
    pub settings: Span<GameSetting>,
}

#[derive(Drop, Serde, Introspect)]
pub struct GameSetting {
    pub name: ByteArray,
    pub value: ByteArray,
}
