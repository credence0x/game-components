#[derive(Model, Copy, Drop, Serde)]
#[dojo::model]
pub struct Score {
    #[key]
    pub token_id: u64,
    pub score: u32,
}

#[derive(Model, Copy, Drop, Serde)]
#[dojo::model]
pub struct ScoreObjective {
    #[key]
    pub id: u32,
    pub score: u32,
    pub exists: bool,
}

#[dojo::model]
#[derive(Copy, Drop, Serde)]
pub struct ScoreObjectiveCount {
    #[key]
    pub key: felt252,
    pub count: u32,
}

#[derive(Model, Copy, Drop, Serde)]
#[dojo::model]
pub struct Settings {
    #[key]
    pub id: u32,
    pub difficulty: u8,
}

#[derive(Model, Clone, Drop, Serde)]
#[dojo::model]
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