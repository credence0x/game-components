#[derive(Drop, Serde, Introspect)]
pub struct GameSetting {
    pub name: ByteArray,
    pub value: ByteArray,
}

// Mocks for testing

#[dojo::model]
#[derive(Drop, Serde)]
pub struct Settings {
    #[key]
    pub id: u32,
    pub difficulty: u8,
}

#[dojo::model]
#[derive(Drop, Serde)]
pub struct SettingsDetails {
    #[key]
    pub id: u32,
    pub name: ByteArray,
    pub description: ByteArray,
    pub exists: bool,
}

#[dojo::model]
#[derive(Copy, Drop, Serde)]
pub struct SettingsCounter {
    #[key]
    pub key: felt252,
    pub count: u32,
}
