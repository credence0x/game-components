#[dojo::model]
#[derive(Drop, Serde)]
pub struct Context {
    #[key]
    pub token_id: u64,
    pub context: ByteArray,
    pub exists: bool,
}
