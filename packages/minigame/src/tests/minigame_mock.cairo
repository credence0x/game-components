use starknet::ContractAddress;

#[starknet::interface]
pub trait IMinigameMock<TContractState> {
    fn start_game(ref self: TContractState, token_id: u64);
    fn end_game(ref self: TContractState, token_id: u64, score: u32);
    fn create_objective_score(ref self: TContractState, score: u32);
    fn create_settings_difficulty(
        ref self: TContractState,
        name: ByteArray,
        description: ByteArray,
        difficulty: u8,
    );
}

#[starknet::interface]
pub trait IMinigameMockInit<TContractState> {
    fn initializer(
        ref self: TContractState,
        game_creator: ContractAddress,
        game_name: felt252,
        game_description: ByteArray,
        game_developer: felt252,
        game_publisher: felt252,
        game_genre: felt252,
        game_image: ByteArray,
        game_color: Option<ByteArray>,
        game_namespace: ByteArray,
        denshokan_address: ContractAddress,
    );
}

#[dojo::contract]
mod minigame_mock {
    use crate::interface::{WorldImpl, IMinigameSettings, IMinigameDetails, IMinigameObjectives, IMinigameTokenUri, IMinigameSettingsURI, IMinigameObjectivesURI};
    use crate::minigame::minigame_component;
    use crate::models::settings::{GameSetting, GameSettingDetails};
    use crate::models::objectives::GameObjective;
    use crate::tests::models::minigame::{Score, ScoreObjective, Settings, SettingsDetails};
    use openzeppelin_introspection::src5::SRC5Component;

    use crate::tests::libs::minigame_store::{Store, StoreTrait};
    use game_components_utils::json::create_settings_json;

    use starknet::ContractAddress;

    component!(path: minigame_component, storage: minigame, event: MinigameEvent);
    component!(path: SRC5Component, storage: src5, event: SRC5Event);
    #[abi(embed_v0)]
    impl MinigameImpl = minigame_component::MinigameImpl<ContractState>;
    impl MinigameInternalImpl = minigame_component::InternalImpl<ContractState>;

    #[abi(embed_v0)]
    impl SRC5Impl = SRC5Component::SRC5Impl<ContractState>;

    #[storage]
    struct Storage {
        #[substorage(v0)]
        minigame: minigame_component::Storage,
        #[substorage(v0)]
        src5: SRC5Component::Storage,
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        #[flat]
        MinigameEvent: minigame_component::Event,
        #[flat]
        SRC5Event: SRC5Component::Event,
    }

    //*******************************

    #[abi(embed_v0)]
    impl SettingsImpl of IMinigameSettings<ContractState> {
        fn setting_exists(self: @ContractState, settings_id: u32) -> bool {
            let world = self.world(@self.namespace());
            let store: Store = StoreTrait::new(world);
            store.get_settings_details(settings_id).exists
        }
        fn settings(self: @ContractState, settings_id: u32) -> GameSettingDetails {
            let world = self.world(@self.namespace());
            let store: Store = StoreTrait::new(world);
            let settings = store.get_settings(settings_id);
            let settings_details = store.get_settings_details(settings_id);
            GameSettingDetails {
                name: settings_details.name,
                description: settings_details.description,
                settings: array![
                    GameSetting {
                        name: "Difficulty",
                        value: format!("{}", settings.difficulty),
                    },
                ].span(),
            }
        }
    }

    #[abi(embed_v0)]
    impl SettingsURIImpl of IMinigameSettingsURI<ContractState> {
        fn settings_uri(self: @ContractState, settings_id: u32) -> ByteArray {
            "test settings uri"
        }
    }

    #[abi(embed_v0)]
    impl GameDetailsImpl of IMinigameDetails<ContractState> {
        fn score(self: @ContractState, token_id: u64) -> u32 {
            let world = self.world(@self.namespace());
            let store: Store = StoreTrait::new(world);
            store.get_score(token_id)
        }
    }

    #[abi(embed_v0)]
    impl ObjectivesImpl of IMinigameObjectives<ContractState> {
        fn objective_exists(self: @ContractState, objective_id: u32) -> bool {
            let world = self.world(@self.namespace());
            let store: Store = StoreTrait::new(world);
            let objective_score = store.get_objective_score(objective_id);
            objective_score.exists
        }
        fn completed_objective(self: @ContractState, token_id: u64, objective_id: u32) -> bool {
            let world = self.world(@self.namespace());
            let store: Store = StoreTrait::new(world);
            let objective_score = store.get_objective_score(objective_id);
            store.get_score(token_id) >= objective_score.score
        }
        fn objectives(self: @ContractState, token_id: u64) -> Span<GameObjective> {
            let world = self.world(@self.namespace());
            let store: Store = StoreTrait::new(world);
            let objective_ids = self.minigame.get_objective_ids(token_id);
            let mut objective_index = 0;
            let mut objectives = array![];
            loop {
                if objective_index == objective_ids.len() {
                    break;
                }
                let objective_id = *objective_ids.at(objective_index);
                let objective_score = store.get_objective_score(objective_id);
                objectives.append(GameObjective { name: "Score Target", value: format!("Score Above {}", objective_score.score) });
                objective_index += 1;
            };
            objectives.span()
        }
    }

    #[abi(embed_v0)]
    impl ObjectivesURIImpl of IMinigameObjectivesURI<ContractState> {
        fn objectives_uri(self: @ContractState, token_id: u64) -> ByteArray {
            "test objectives uri"
        }
    }

    #[abi(embed_v0)]
    impl TokenUriImpl of IMinigameTokenUri<ContractState> {
        fn token_uri(self: @ContractState, token_id: u256) -> ByteArray {
            "game mock uri"
        }
    }

    #[abi(embed_v0)]
    impl GameMockImpl of super::IMinigameMock<ContractState> {
        fn start_game(ref self: ContractState, token_id: u64) {
            let mut world = self.world(@self.namespace());
            let mut store: Store = StoreTrait::new(world);

            store.set_score(@Score { token_id, score: 0 });
        }

        fn end_game(ref self: ContractState, token_id: u64, score: u32) {
            let mut world = self.world(@self.namespace());
            let mut store: Store = StoreTrait::new(world);
            store.set_score(@Score { token_id, score });
            self.minigame.end_game(token_id);
        }

        fn create_objective_score(ref self: ContractState, score: u32) {
            let mut world = self.world(@self.namespace());
            let mut store: Store = StoreTrait::new(world);
            let objective_count = store.get_objective_count();
            store
                .set_objective_score(
                    @ScoreObjective { id: objective_count + 1, score, exists: true },
                );
            store.set_objective_count(objective_count + 1);
            self.minigame.create_objective(objective_count + 1, format!("Score Above {}", score));
        }

        fn create_settings_difficulty(
            ref self: ContractState,
            name: ByteArray,
            description: ByteArray,
            difficulty: u8,
        ) {
            let mut world = self.world(@self.namespace());
            let mut store: Store = StoreTrait::new(world);

            let settings_count = store.get_settings_count();
            store.set_settings(@Settings { id: settings_count + 1, difficulty });
            store
                .set_settings_details(
                    @SettingsDetails { id: settings_count + 1, name: name.clone(), description: description.clone(), exists: true },
                );
            store.set_settings_count(settings_count + 1);
            let settings = array![
                GameSetting {
                    name: "Difficulty",
                    value: format!("{}", difficulty),
                },
            ];
            let settings_json = create_settings_json(name.clone(), description.clone(), settings.span());
            self.minigame.create_settings(settings_count + 1, settings_json);
        }
    }

    #[abi(embed_v0)]
    impl GameInitializerImpl of super::IMinigameMockInit<ContractState> {
        fn initializer(
            ref self: ContractState,
            game_creator: ContractAddress,
            game_name: felt252,
            game_description: ByteArray,
            game_developer: felt252,
            game_publisher: felt252,
            game_genre: felt252,
            game_image: ByteArray,
            game_color: Option<ByteArray>,
            game_namespace: ByteArray,
            denshokan_address: ContractAddress,
        ) {
            self
                .minigame
                .initializer(
                    game_creator,
                    game_name,
                    game_description,
                    game_developer,
                    game_publisher,
                    game_genre,
                    game_image,
                    game_color,
                    game_namespace,
                    denshokan_address,
                );
        }
    }
}
