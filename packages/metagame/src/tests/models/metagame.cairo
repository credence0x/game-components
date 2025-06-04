#[dojo::model]
#[derive(Drop, Serde)]
pub struct MetagameContext {
    #[key]
    pub token_id: u64,
    pub context: ByteArray,
    pub exists: bool,
}
