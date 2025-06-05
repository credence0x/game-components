use dojo::world::{WorldStorage};
use dojo::model::{ModelStorage};

use crate::tests::models::metagame::Context;

#[derive(Copy, Drop)]
pub struct Store {
    world: WorldStorage,
}

#[generate_trait]
pub impl StoreImpl of StoreTrait {
    #[inline(always)]
    fn new(world: WorldStorage) -> Store {
        (Store { world })
    }

    //
    // Getters
    //

    #[inline(always)]
    fn get_context(self: Store, token_id: u64) -> Context {
        (self.world.read_model(token_id))
    }

    //
    // Setters
    //

    #[inline(always)]
    fn set_context(ref self: Store, model: @Context) {
        self.world.write_model(model);
    }
}
