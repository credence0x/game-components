#[derive(Drop, Serde, Introspect)]
pub struct GameObjective {
    pub name: felt252,
    pub value: felt252,
}
