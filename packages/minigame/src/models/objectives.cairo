#[derive(Drop, Serde, Introspect)]
pub struct GameObjective {
    pub name: felt252,
    pub value: felt252,
}

#[dojo::model]
#[derive(Drop, Serde)]
pub struct ObjectiveDetails {
    #[key]
    pub id: u32,
    pub name: felt252,
    pub description: ByteArray,
    pub exists: bool,
}

#[dojo::model]
#[derive(Copy, Drop, Serde)]
pub struct ObjectiveCounter {
    #[key]
    pub key: felt252,
    pub count: u32,
}
