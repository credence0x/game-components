use crate::models::context::GameContext;

#[dojo::model]
#[derive(Drop, Serde)]
pub struct Context {
    #[key]
    pub token_id: u64,
    pub context: Span<GameContext>,
    pub exists: bool,
}
