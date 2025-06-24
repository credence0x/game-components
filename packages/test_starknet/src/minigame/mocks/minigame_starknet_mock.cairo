use starknet::ContractAddress;

#[starknet::interface]
pub trait IMinigameStarknetMock<TContractState> {
    fn start_game(ref self: TContractState, token_id: u64);
    fn end_game(ref self: TContractState, token_id: u64, score: u32);
    fn create_objective_score(ref self: TContractState, score: u32);
    fn create_settings_difficulty(
        ref self: TContractState, name: ByteArray, description: ByteArray, difficulty: u8,
    );
}

#[starknet::interface]
pub trait IMinigameStarknetMockInit<TContractState> {
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
        client_url: Option<ByteArray>,
        renderer_address: Option<ContractAddress>,
        settings_address: Option<ContractAddress>,
        objectives_address: Option<ContractAddress>,
        game_namespace: ByteArray,
        token_address: ContractAddress,
        supports_settings: bool,
        supports_objectives: bool,
    );
}

#[starknet::contract]
mod minigame_starknet_mock {
    use game_components_minigame::interface::{
        IMinigameScore, IMinigameDetails, IMinigameSettings, IMinigameObjectives,
    };
    use game_components_minigame::minigame::minigame_component;
    use game_components_minigame::models::game_details::GameDetail;
    use game_components_minigame::models::settings::{GameSetting, GameSettingDetails};
    use game_components_minigame::models::objectives::GameObjective;
    use openzeppelin_introspection::src5::SRC5Component;

    use starknet::ContractAddress;
    use starknet::storage::{
        StoragePointerReadAccess, StoragePointerWriteAccess, Map, Vec, VecTrait, MutableVecTrait
    };

    component!(path: minigame_component, storage: minigame, event: MinigameEvent);
    component!(path: SRC5Component, storage: src5, event: SRC5Event);

    #[abi(embed_v0)]
    impl MinigameImpl = minigame_component::MinigameImpl<ContractState>;
    impl MinigameInternalImpl = minigame_component::InternalImpl<ContractState>;
    impl MinigameInternalObjectivesImpl = minigame_component::InternalObjectivesImpl<ContractState>;
    impl MinigameInternalSettingsImpl = minigame_component::InternalSettingsImpl<ContractState>;

    #[abi(embed_v0)]
    impl SRC5Impl = SRC5Component::SRC5Impl<ContractState>;

    #[storage]
    struct Storage {
        #[substorage(v0)]
        minigame: minigame_component::Storage,
        #[substorage(v0)]
        src5: SRC5Component::Storage,
        
        // Game scores storage
        scores: Map<u64, u32>, // token_id -> score
        
        // Settings storage
        settings_count: u32,
        settings_difficulty: Map<u32, u8>, // settings_id -> difficulty
        settings_details: Map<u32, (ByteArray, ByteArray, bool)>, // settings_id -> (name, description, exists)
        
        // Objectives storage
        objective_count: u32,
        objective_scores: Map<u32, (u32, bool)>, // objective_id -> (target_score, exists)
        
        // Token objective mappings
        token_objectives: Map<u64, Vec<u32>>, // token_id -> objective_ids
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        #[flat]
        MinigameEvent: minigame_component::Event,
        #[flat]
        SRC5Event: SRC5Component::Event,
    }

    #[abi(embed_v0)]
    impl GameScoreImpl of IMinigameScore<ContractState> {
        fn score(self: @ContractState, token_id: u64) -> u32 {
            self.scores.read(token_id)
        }
    }

    #[abi(embed_v0)]
    impl GameDetailsImpl of IMinigameDetails<ContractState> {
        fn token_description(self: @ContractState, token_id: u64) -> ByteArray {
            format!("Test Token Description for token {}", token_id)
        }
        
        fn game_details(self: @ContractState, token_id: u64) -> Span<GameDetail> {
            array![
                GameDetail {
                    name: "Test Game Detail", 
                    value: format!("Test Value for token {}", token_id)
                }
            ].span()
        }
    }

    #[abi(embed_v0)]
    impl SettingsImpl of IMinigameSettings<ContractState> {
        fn setting_exists(self: @ContractState, settings_id: u32) -> bool {
            let (_, _, exists) = self.settings_details.read(settings_id);
            exists
        }
        
        fn settings(self: @ContractState, settings_id: u32) -> GameSettingDetails {
            let (name, description, _) = self.settings_details.read(settings_id);
            let difficulty = self.settings_difficulty.read(settings_id);
            
            GameSettingDetails {
                name,
                description,
                settings: array![
                    GameSetting { 
                        name: "Difficulty", 
                        value: format!("{}", difficulty) 
                    }
                ].span(),
            }
        }
    }

    #[abi(embed_v0)]
    impl ObjectivesImpl of IMinigameObjectives<ContractState> {
        fn objective_exists(self: @ContractState, objective_id: u32) -> bool {
            let (_, exists) = self.objective_scores.read(objective_id);
            exists
        }
        
        fn completed_objective(self: @ContractState, token_id: u64, objective_id: u32) -> bool {
            let (target_score, _) = self.objective_scores.read(objective_id);
            let player_score = self.scores.read(token_id);
            player_score >= target_score
        }
        
        fn objectives(self: @ContractState, token_id: u64) -> Span<GameObjective> {
            let objective_ids = self.token_objectives.read(token_id);
            let mut objectives = array![];
            
            let mut i = 0;
            while i < objective_ids.len() {
                let objective_id = objective_ids.at(i).read();
                let (target_score, _) = self.objective_scores.read(objective_id);
                
                objectives.append(
                    GameObjective {
                        name: "Score Target",
                        value: format!("Score Above {}", target_score),
                    }
                );
                i += 1;
            };
            
            objectives.span()
        }
    }

    #[abi(embed_v0)]
    impl GameMockImpl of super::IMinigameStarknetMock<ContractState> {
        fn start_game(ref self: ContractState, token_id: u64) {
            self.scores.write(token_id, 0);
        }

        fn end_game(ref self: ContractState, token_id: u64, score: u32) {
            self.scores.write(token_id, score);
            self.minigame.post_action(token_id);
        }

        fn create_objective_score(ref self: ContractState, score: u32) {
            let objective_count = self.objective_count.read();
            let new_objective_id = objective_count + 1;
            
            self.objective_scores.write(new_objective_id, (score, true));
            self.objective_count.write(new_objective_id);
            
            self.minigame.create_objective(
                new_objective_id, 
                "Score Target", 
                format!("Score Above {}", score)
            );
        }

        fn create_settings_difficulty(
            ref self: ContractState, 
            name: ByteArray, 
            description: ByteArray, 
            difficulty: u8,
        ) {
            let settings_count = self.settings_count.read();
            let new_settings_id = settings_count + 1;
            
            self.settings_difficulty.write(new_settings_id, difficulty);
            self.settings_details.write(new_settings_id, (name.clone(), description.clone(), true));
            self.settings_count.write(new_settings_id);
            
            let settings = array![
                GameSetting { name: "Difficulty", value: format!("{}", difficulty) }
            ];
            
            self.minigame.create_settings(
                new_settings_id, 
                name, 
                description, 
                settings.span()
            );
        }
    }

    #[abi(embed_v0)]
    impl GameInitializerImpl of super::IMinigameStarknetMockInit<ContractState> {
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
            client_url: Option<ByteArray>,
            renderer_address: Option<ContractAddress>,
            settings_address: Option<ContractAddress>,
            objectives_address: Option<ContractAddress>,
            game_namespace: ByteArray,
            token_address: ContractAddress,
            supports_settings: bool,
            supports_objectives: bool,
        ) {
            // Initialize storage counters
            self.settings_count.write(0);
            self.objective_count.write(0);
            
            // Initialize the base minigame component
            self.minigame.initializer(
                game_creator,
                game_name,
                game_description,
                game_developer,
                game_publisher,
                game_genre,
                game_image,
                game_color,
                client_url,
                renderer_address,
                settings_address,
                objectives_address,
                game_namespace,
                token_address,
            );

            // Initialize optional features - these will only compile if the contract implements the required traits
            if supports_settings {
                self.minigame.initialize_settings();
            }
            if supports_objectives {
                self.minigame.initialize_objectives();
            }
        }
    }

    // Helper function to store token objectives (called during mint)
    #[generate_trait]
    impl HelperImpl of HelperTrait {
        fn store_token_objectives(ref self: ContractState, token_id: u64, objective_ids: Span<u32>) {
            let mut objectives_vec = self.token_objectives.read(token_id);
            
            let mut i = 0;
            while i < objective_ids.len() {
                objectives_vec.append().write(*objective_ids.at(i));
                i += 1;
            };
        }
    }
} 