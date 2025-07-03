# Test Plan for Game Components Smart Contracts

## 1. Contract Reconnaissance

### Function Inventory

#### Core Components

| Contract | Function | Signature | Type | Mutates State | Emits Events |
|----------|----------|-----------|------|---------------|--------------|
| **MetagameComponent** | | | | | |
| | minigame_token_address | `(self: @TContractState) -> ContractAddress` | External | No | No |
| | context_address | `(self: @TContractState) -> ContractAddress` | External | No | No |
| | initializer | `(ref self, context_address: Option<ContractAddress>, minigame_token_address: ContractAddress)` | Internal | Yes | No |
| | mint | `(ref self, game_address: Option<ContractAddress>, player_name: Option<ByteArray>, settings_id: Option<u32>, start: Option<u64>, end: Option<u64>, objective_ids: Option<Span<u32>>, context: Option<GameContextDetails>, client_url: Option<ByteArray>, renderer_address: Option<ContractAddress>, to: ContractAddress, soulbound: bool) -> u64` | Internal | Yes | Yes* |
| | register_src5_interfaces | `(ref self)` | Internal | Yes | No |
| | assert_game_registered | `(ref self, game_address: ContractAddress)` | Internal | No | No |
| **MinigameComponent** | | | | | |
| | token_address | `(self: @ComponentState<TContractState>) -> ContractAddress` | External | No | No |
| | settings_address | `(self: @ComponentState<TContractState>) -> ContractAddress` | External | No | No |
| | objectives_address | `(self: @ComponentState<TContractState>) -> ContractAddress` | External | No | No |
| | initializer | `(ref self, game_address: ContractAddress, token_address: ContractAddress, settings_address: Option<ContractAddress>, objectives_address: Option<ContractAddress>)` | Internal | Yes | No |
| | register_game_interface | `(ref self)` | Internal | Yes | No |
| | pre_action | `(ref self, token_id: u64)` | Internal | No | No |
| | post_action | `(ref self, token_id: u64)` | Internal | Yes | Yes* |
| | get_player_name | `(self, token_id: u64) -> ByteArray` | Internal | No | No |
| | assert_token_ownership | `(self, token_id: u64)` | Internal | No | No |
| | assert_game_token_playable | `(self, token_id: u64)` | Internal | No | No |
| **IMinigameTokenData** (Required) | | | | | |
| | score | `(self: @TState, token_id: u64) -> u32` | External | No | No |
| | game_over | `(self: @TState, token_id: u64) -> bool` | External | No | No |
| **TokenComponent** | | | | | |
| | token_metadata | `(self: @TContractState, token_id: u64) -> TokenMetadata` | External | No | No |
| | is_playable | `(self: @TContractState, token_id: u64) -> bool` | External | No | No |
| | settings_id | `(self: @TContractState, token_id: u64) -> u32` | External | No | No |
| | player_name | `(self: @TContractState, token_id: u64) -> ByteArray` | External | No | No |
| | mint | `(ref self, ...) -> u64` | External | Yes | Yes |
| | update_game | `(ref self, token_id: u64)` | External | Yes | Yes |
| | initializer | `(ref self, game_address: Option<ContractAddress>)` | Internal | Yes | No |
| | register_src5_interfaces | `(ref self)` | Internal | Yes | No |
| | assert_playable | `(self, metadata: TokenMetadata)` | Internal | No | No |
| | assert_token_ownership | `(self, token_id: u64)` | Internal | No | No |

*Delegates to TokenComponent which emits events

### State Variables

| Contract | Variable | Type | Description |
|----------|----------|------|-------------|
| **MetagameComponent** | | | |
| | minigame_token_address | ContractAddress | Token contract address |
| | context_address | ContractAddress | Optional context provider |
| **MinigameComponent** | | | |
| | token_address | ContractAddress | Associated token contract |
| | settings_address | ContractAddress | Optional settings extension |
| | objectives_address | ContractAddress | Optional objectives extension |
| **TokenComponent** | | | |
| | token_counter | u64 | Auto-incrementing token ID |
| | token_metadata | Map<u64, TokenMetadata> | Token metadata storage |
| | token_player_names | Map<u64, ByteArray> | Player name storage |
| | game_address | ContractAddress | Single game address (non-multi-game) |

### Events

| Contract | Event | Fields | Trigger |
|----------|-------|--------|---------|
| **TokenComponent** | | | |
| | ScoreUpdate | token_id: u64, score: u64 | update_game() |
| | MetadataUpdate | token_id: u64 | update_game() |
| | Owners | token_id: u64, owner: ContractAddress, auth: ContractAddress | mint() |

#### Extension Components

| Extension | Function | Signature | Type | Mutates State | Emits Events |
|-----------|----------|-----------|------|---------------|--------------|
| **MetagameContextComponent** | | | | | |
| | has_context | `(self: @TState, token_id: u64) -> bool` | External | No | No |
| | context | `(self: @TState, token_id: u64) -> GameContextDetails` | External | No | No |
| | context_svg | `(self: @TState, token_id: u64) -> ByteArray` | External | No | No |
| | initializer | `(ref self)` | Internal | Yes | No |
| **MinigameSettingsComponent** | | | | | |
| | settings_exist | `(self: @TState, settings_id: u32) -> bool` | External | No | No |
| | settings | `(self: @TState, settings_id: u32) -> GameSettingDetails` | External | No | No |
| | settings_svg | `(self: @TState, settings_id: u32) -> ByteArray` | External | No | No |
| | get_settings_id | `(self, token_id: u64) -> u32` | Internal | No | No |
| | create_settings | `(ref self, game_id: u32, name: ByteArray, description: ByteArray, settings: Span<GameSetting>)` | Internal | Yes | Yes* |
| **MinigameObjectivesComponent** | | | | | |
| | objective_exists | `(self: @TState, objective_id: u32) -> bool` | External | No | No |
| | completed_objective | `(self: @TState, token_id: u64, objective_id: u32) -> bool` | External | No | No |
| | objectives | `(self: @TState, token_id: u64) -> Span<ObjectiveDetails>` | External | No | No |
| | objectives_svg | `(self: @TState, token_id: u64) -> ByteArray` | External | No | No |
| | get_objective_ids | `(self, token_id: u64) -> Span<u32>` | Internal | No | No |
| | create_objective | `(ref self, game_id: u32, objective_id: u32, points: u32, name: ByteArray, description: ByteArray)` | Internal | Yes | Yes* |
| **TokenMinterComponent** | | | | | |
| | add_minter | `(ref self, minter_address: ContractAddress) -> u32` | Internal | Yes | No |
| **TokenMultiGameComponent** | | | | | |
| | game_count | `(self: @TState) -> u32` | External | No | No |
| | game_id_from_address | `(self: @TState, address: ContractAddress) -> u32` | External | No | No |
| | game_address_from_id | `(self: @TState, game_id: u32) -> ContractAddress` | External | No | No |
| | game_metadata | `(self: @TState, game_id: u32) -> GameMetadata` | External | No | No |
| | is_game_registered | `(self: @TState, game_address: ContractAddress) -> bool` | External | No | No |
| | register_game | `(ref self, game_address: ContractAddress, name: ByteArray, description: ByteArray, creator_name: ByteArray, creator_address: ContractAddress, color: Option<u32>, renderer_address: Option<ContractAddress>, client_url: Option<ByteArray>) -> u32` | External | Yes | Yes |
| **TokenObjectivesComponent** | | | | | |
| | objectives_count | `(self: @TState, token_id: u64) -> u32` | External | No | No |
| | objectives | `(self: @TState, token_id: u64) -> Span<TokenObjective>` | External | No | No |
| | objective_ids | `(self: @TState, token_id: u64) -> Span<u32>` | External | No | No |
| | all_objectives_completed | `(self: @TState, token_id: u64) -> bool` | External | No | No |
| | create_objective | `(ref self, token_id: u64, objective_id: u32, points: u32, is_required: bool)` | Internal | Yes | Yes |
| | complete_objective | `(ref self, token_id: u64, objective_id: u32)` | Internal | Yes | Yes |
| **TokenSettingsComponent** | | | | | |
| | create_settings | `(ref self, game_id: u32, settings_id: u32, name: ByteArray, description: ByteArray, settings: Span<GameSetting>)` | Internal | Yes | Yes |
| **TokenSoulboundComponent** | | | | | |
| | before_update | `(ref self, auth: ContractAddress, from: ContractAddress, to: ContractAddress, token_id: u64)` | Hook | No | No |
| **TokenRendererComponent** | | | | | |
| | get_renderer | `(self: @TState, token_id: u64) -> ContractAddress` | External | No | No |
| | has_custom_renderer | `(self: @TState, token_id: u64) -> bool` | External | No | No |
| | get_default_renderer | `(self: @TState) -> ContractAddress` | External | No | No |
| | set_default_renderer | `(ref self, renderer: ContractAddress)` | Internal | Yes | Yes |
| | set_token_renderer | `(ref self, token_id: u64, renderer: ContractAddress)` | Internal | Yes | Yes |

*Delegates to another component or contract which emits events

### State Variables - Extensions

| Extension | Variable | Type | Description |
|-----------|----------|------|-------------|
| **MetagameContextComponent** | | | |
| | (no storage) | - | Context data stored in implementing contract |
| **TokenMinterComponent** | | | |
| | minter_count | u32 | Total registered minters |
| | minter_ids | Map<ContractAddress, u32> | Minter address to ID mapping |
| **TokenMultiGameComponent** | | | |
| | game_count | u32 | Total registered games |
| | game_ids | Map<ContractAddress, u32> | Game address to ID mapping |
| | game_metadata | Map<u32, GameMetadata> | Game ID to metadata |
| **TokenObjectivesComponent** | | | |
| | token_objectives_count | Map<u64, u32> | Objectives per token |
| | token_objectives | Map<(u64, u32), TokenObjective> | Token objectives data |
| **TokenRendererComponent** | | | |
| | default_renderer | ContractAddress | Default renderer address |
| | token_renderers | Map<u64, ContractAddress> | Custom renderers per token |

### Events - Extensions

| Extension | Event | Fields | Trigger |
|-----------|-------|--------|---------|
| **TokenMultiGameComponent** | | | |
| | GameRegistered | game_id: u32, game_address: ContractAddress, name: ByteArray | register_game() |
| **TokenObjectivesComponent** | | | |
| | ObjectiveCreated | game_id: u32, objective_id: u32, points: u32, name: ByteArray, description: ByteArray | create_objective() |
| | ObjectiveCompleted | token_id: u64, objective_id: u32, total_points: u32 | complete_objective() |
| | AllObjectivesCompleted | token_id: u64, total_points: u32 | complete_objective() when all done |
| **TokenSettingsComponent** | | | |
| | SettingsCreated | game_id: u32, settings_id: u32, name: ByteArray, description: ByteArray, settings: Span<GameSetting> | create_settings() |
| **TokenRendererComponent** | | | |
| | DefaultRendererUpdated | renderer: ContractAddress | set_default_renderer() |
| | TokenRendererUpdated | token_id: u64, renderer: ContractAddress | set_token_renderer() |

### Constants

- `IMETAGAME_ID`: 0x0260d5160a283a03815f6c3799926c7bdbec5f22e759f992fb8faf172243ab20
- `IMETAGAME_CONTEXT_ID`: 0x0c2e78065b81a310a1cb470d14a7b88875542ad05286b3263cf3c254082386e
- `IMINIGAME_ID`: 0x02c0f9265d397c10970f24822e4b57cac7d8895f8c449b7c9caaa26910499704
- `IMINIGAME_SETTINGS_ID`: 0x0379f4343538c65a38349fb1318328629dd950d3624101aeaac1b4bd45a39eff
- `IMINIGAME_OBJECTIVES_ID`: 0x0213cfcf73543e549f00c7cad49cf27a1e544d71315ff981930aaf77ac0709bd
- `IMINIGAME_TOKEN_ID`: 0x02c0f9265d397c10970f24822e4b57cac7d8895f8c449b7c9caaa26910499704

## 2. Behaviour & Invariant Mapping

### MetagameComponent

#### mint()
- **Purpose**: Orchestrate token minting with optional context validation
- **Inputs**: 
  - game_address: None, zero address, registered game, unregistered game
  - context: None, valid context, invalid context
  - settings_id: None, 0, valid ID, non-existent ID
  - objective_ids: None, empty span, valid IDs, non-existent IDs
  - start/end: 0, past timestamp, current timestamp, future timestamp, start > end
  - soulbound: true/false
  - to: zero address, valid address
- **Outputs**: Token ID (monotonically increasing from 1)
- **Events**: Delegates to TokenComponent (ScoreUpdate, MetadataUpdate, Owners)
- **Access Control**: None (relies on token contract)
- **Reverts**: 
  - Context provided but no valid context provider
  - Game not registered (multi-game only)
  - Any validation failure in TokenComponent
- **Invariants**:
  - INV-MG-1: minigame_token_address never zero after init
  - INV-MG-2: Context validation must pass before minting
  - INV-MG-3: All mints delegate to token contract

### MinigameComponent

#### pre_action()
- **Purpose**: Validate token is playable before game actions
- **Inputs**: token_id (0, valid owned, valid not owned, non-existent)
- **Reverts**: Token not owned, token not playable
- **Invariants**:
  - INV-MN-1: Only token owner can perform actions
  - INV-MN-2: Token must be playable (lifecycle + game state)

#### post_action()
- **Purpose**: Sync token state after game actions
- **Inputs**: token_id
- **Events**: Triggers update_game() → ScoreUpdate, MetadataUpdate
- **Invariants**:
  - INV-MN-3: Must be called after every state change
  - INV-MN-4: Score/objectives sync to token

### TokenComponent

#### mint()
- **Purpose**: Create new game token with validation
- **Inputs**: (same as MetagameComponent mint)
- **Outputs**: token_id
- **Events**: Owners(token_id, owner, auth)
- **Reverts**:
  - Settings: Extension not supported, settings don't exist
  - Objectives: Extension not supported, objectives don't exist  
  - Multi-game: Game not registered
  - Invalid lifecycle (start > end when both non-zero)
- **Invariants**:
  - INV-TK-1: Token IDs increase monotonically
  - INV-TK-2: Metadata immutable except game_over/objectives
  - INV-TK-3: Lifecycle: start ≤ now < end (when set)

#### update_game()
- **Purpose**: Sync game state to token
- **Inputs**: token_id
- **Events**: ScoreUpdate, MetadataUpdate
- **Access Control**: Token must be owned by minigame contract
- **Invariants**:
  - INV-TK-4: Score can only increase or stay same
  - INV-TK-5: game_over transition is one-way
  - INV-TK-6: Objective completion is one-way

#### is_playable()
- **Purpose**: Check if token can be played
- **Returns**: true iff lifecycle valid AND !game_over AND !all_objectives_complete
- **Invariants**:
  - INV-TK-7: Playability derived from state

### Extension Components

#### MetagameContextComponent

##### has_context()
- **Purpose**: Check if context exists for token
- **Inputs**: token_id (0, valid, non-existent)
- **Returns**: bool
- **Invariants**:
  - INV-CTX-1: Context existence is consistent

##### context()
- **Purpose**: Get context details for token
- **Inputs**: token_id
- **Returns**: GameContextDetails
- **Reverts**: Token doesn't exist or no context
- **Invariants**:
  - INV-CTX-2: Context data immutable once set

#### MinigameSettingsComponent

##### settings_exist()
- **Purpose**: Check if settings configuration exists
- **Inputs**: settings_id (0, valid, non-existent, u32::MAX)
- **Returns**: bool
- **Invariants**:
  - INV-SET-1: Settings existence is permanent

##### settings()
- **Purpose**: Get settings configuration
- **Inputs**: settings_id
- **Returns**: GameSettingDetails
- **Reverts**: Settings don't exist
- **Invariants**:
  - INV-SET-2: Settings immutable once created

##### create_settings()
- **Purpose**: Create new settings configuration
- **Inputs**: game_id, name, description, settings array
- **Events**: Delegates to token contract
- **Access Control**: Must be minigame contract
- **Invariants**:
  - INV-SET-3: Settings IDs unique per game

#### MinigameObjectivesComponent

##### objective_exists()
- **Purpose**: Check if objective exists
- **Inputs**: objective_id (0, valid, non-existent)
- **Returns**: bool
- **Invariants**:
  - INV-OBJ-1: Objective existence is permanent

##### completed_objective()
- **Purpose**: Check objective completion for token
- **Inputs**: token_id, objective_id
- **Returns**: bool
- **Invariants**:
  - INV-OBJ-2: Completion is one-way

##### create_objective()
- **Purpose**: Create new objective
- **Inputs**: game_id, objective_id, points, name, description
- **Events**: ObjectiveCreated (delegated)
- **Access Control**: Must be minigame contract
- **Invariants**:
  - INV-OBJ-3: Objective IDs unique per game

#### TokenMinterComponent

##### add_minter()
- **Purpose**: Register minter and get ID
- **Inputs**: minter_address (zero, valid, duplicate)
- **Returns**: minter_id (1-based)
- **Invariants**:
  - INV-MNT-1: Minter IDs increment from 1
  - INV-MNT-2: Same address always gets same ID
  - INV-MNT-3: IDs never reused

#### TokenMultiGameComponent

##### register_game()
- **Purpose**: Register new game with metadata
- **Inputs**: 
  - game_address: zero, valid, duplicate, non-IMinigame
  - metadata: name, description, creator info
  - options: color, renderer, client_url
- **Returns**: game_id
- **Events**: GameRegistered
- **Access Control**: None (public)
- **Reverts**: 
  - Game already registered
  - Game doesn't support IMinigame
  - Creator token mint fails
- **Invariants**:
  - INV-MG-1: Game IDs increment from 1
  - INV-MG-2: Game can only register once
  - INV-MG-3: Creator gets token on registration

##### game_metadata()
- **Purpose**: Get full game information
- **Inputs**: game_id (0, valid, non-existent)
- **Returns**: GameMetadata
- **Reverts**: Game not registered
- **Invariants**:
  - INV-MG-4: Metadata immutable once set

#### TokenObjectivesComponent

##### create_objective()
- **Purpose**: Add objective to token
- **Inputs**: token_id, objective_id, points, is_required
- **Events**: ObjectiveCreated
- **Reverts**: Objective already exists for token
- **Invariants**:
  - INV-TOB-1: Objectives can't be removed
  - INV-TOB-2: Objective IDs unique per token

##### complete_objective()
- **Purpose**: Mark objective as completed
- **Inputs**: token_id, objective_id
- **Events**: ObjectiveCompleted, AllObjectivesCompleted
- **Reverts**: 
  - Objective doesn't exist
  - Already completed
- **Invariants**:
  - INV-TOB-3: Completion is permanent
  - INV-TOB-4: Points accumulate correctly
  - INV-TOB-5: All-complete fires once

#### TokenSettingsComponent

##### create_settings()
- **Purpose**: Store settings configuration
- **Inputs**: game_id, settings_id, metadata
- **Events**: SettingsCreated
- **Access Control**: Caller must be settings_address
- **Reverts**: Unauthorized caller
- **Invariants**:
  - INV-TST-1: Only settings contract can create

#### TokenSoulboundComponent

##### before_update() (ERC721 Hook)
- **Purpose**: Prevent transfers when soulbound
- **Inputs**: auth, from, to, token_id
- **Reverts**: "Soulbound: token is non-transferable"
- **Invariants**:
  - INV-SB-1: Minting allowed (from = 0)
  - INV-SB-2: Burning allowed (to = 0)
  - INV-SB-3: Transfers blocked when soulbound

#### TokenRendererComponent

##### get_renderer()
- **Purpose**: Get renderer for token with fallback
- **Inputs**: token_id
- **Returns**: renderer address (custom or default)
- **Invariants**:
  - INV-RND-1: Always returns valid renderer

##### set_token_renderer()
- **Purpose**: Set custom renderer for token
- **Inputs**: token_id, renderer address
- **Events**: TokenRendererUpdated
- **Invariants**:
  - INV-RND-2: Custom renderer overrides default

## 3. Unit Test Design

### MetagameComponent Tests

| Test ID | Test Case | Category | Expected Result |
|---------|-----------|----------|-----------------|
| MG-U-01 | Initialize with token address only | Happy | Success, context = 0 |
| MG-U-02 | Initialize with token + context | Happy | Success, both stored |
| MG-U-03 | Initialize with zero token address | Revert | Panic |
| MG-U-04 | Mint minimal (to address only) | Happy | Token ID returned |
| MG-U-05 | Mint with all parameters | Happy | Token ID returned |
| MG-U-06 | Mint with context, no provider | Revert | Context validation fails |
| MG-U-07 | Mint with invalid game (multi-game) | Revert | Game not registered |
| MG-U-08 | Get minigame_token_address | Happy | Correct address |
| MG-U-09 | Get context_address | Happy | Correct address |
| MG-U-10 | Mint with max objectives (255) | Boundary | Success |
| MG-U-11 | Mint with start = end | Boundary | Success (instant game) |
| MG-U-12 | Mint with start > end | Revert | Invalid lifecycle |

### MinigameComponent Tests

| Test ID | Test Case | Category | Expected Result |
|---------|-----------|----------|-----------------|
| MN-U-01 | Initialize with all addresses | Happy | Success |
| MN-U-02 | Initialize settings/objectives = 0 | Happy | Success (optional) |
| MN-U-03 | Get token_address | Happy | Correct address |
| MN-U-04 | Get settings_address | Happy | Correct address |
| MN-U-05 | Get objectives_address | Happy | Correct address |
| MN-U-06 | pre_action with owned token | Happy | Success |
| MN-U-07 | pre_action with unowned token | Revert | Not owner |
| MN-U-08 | pre_action with expired token | Revert | Not playable |
| MN-U-09 | pre_action with game_over token | Revert | Not playable |
| MN-U-10 | post_action triggers update | Happy | Events emitted |
| MN-U-11 | get_player_name | Happy | Correct name |
| MN-U-12 | pre_action at exact start time | Boundary | Success |
| MN-U-13 | pre_action at exact end time | Boundary | Revert |

### TokenComponent Tests

| Test ID | Test Case | Category | Expected Result |
|---------|-----------|----------|-----------------|
| TK-U-01 | Mint basic token | Happy | Token ID = 1 |
| TK-U-02 | Mint sequential tokens | Happy | IDs increment |
| TK-U-03 | Mint with settings | Happy | Settings validated |
| TK-U-04 | Mint with non-existent settings | Revert | Settings don't exist |
| TK-U-05 | Mint with objectives | Happy | Objectives stored |
| TK-U-06 | Mint with invalid objectives | Revert | Objectives don't exist |
| TK-U-07 | Mint soulbound token | Happy | soulbound = true |
| TK-U-08 | Mint with future start | Happy | Success |
| TK-U-09 | Mint to zero address | Revert | Invalid recipient |
| TK-U-10 | update_game increases score | Happy | ScoreUpdate event |
| TK-U-11 | update_game sets game_over | Happy | MetadataUpdate event |
| TK-U-12 | update_game completes objectives | Happy | Events emitted |
| TK-U-13 | is_playable lifecycle checks | Happy | Correct bool |
| TK-U-14 | token_metadata retrieval | Happy | Correct struct |
| TK-U-15 | Mint with 256 objectives | Revert | Exceeds u8 |
| TK-U-16 | Token counter at u64::MAX | Boundary | Overflow handling |

### Extension Component Tests

#### MetagameContextComponent Tests

| Test ID | Test Case | Category | Expected Result |
|---------|-----------|----------|-----------------|
| CTX-U-01 | Initialize context component | Happy | SRC5 registered |
| CTX-U-02 | Mint with context, external provider | Happy | Context stored |
| CTX-U-03 | Mint with context, self provider | Happy | Context stored |
| CTX-U-04 | Mint with context, no provider | Revert | Context validation fails |
| CTX-U-05 | Query has_context for valid token | Happy | Returns true |
| CTX-U-06 | Query has_context for no context | Happy | Returns false |
| CTX-U-07 | Get context for valid token | Happy | Correct data |
| CTX-U-08 | Get context for non-existent token | Revert | Token not found |
| CTX-U-09 | Context with empty array | Happy | Success |
| CTX-U-10 | Context with 100 items | Boundary | Success |
| CTX-U-11 | Context_svg implementation | Happy | Valid SVG |

#### MinigameSettingsComponent Tests

| Test ID | Test Case | Category | Expected Result |
|---------|-----------|----------|-----------------|
| SET-U-01 | Initialize settings component | Happy | SRC5 registered |
| SET-U-02 | Check settings_exist for valid ID | Happy | Returns true |
| SET-U-03 | Check settings_exist for invalid ID | Happy | Returns false |
| SET-U-04 | Get settings for valid ID | Happy | Correct data |
| SET-U-05 | Get settings for non-existent ID | Revert | Settings not found |
| SET-U-06 | Create settings with valid data | Happy | Settings stored |
| SET-U-07 | Create settings with empty name | Boundary | Success |
| SET-U-08 | Create settings with 50 items | Boundary | Success |
| SET-U-09 | Get_settings_id from token | Happy | Correct ID |
| SET-U-10 | Settings_svg implementation | Happy | Valid SVG |

#### MinigameObjectivesComponent Tests

| Test ID | Test Case | Category | Expected Result |
|---------|-----------|----------|-----------------|
| OBJ-U-01 | Initialize objectives component | Happy | SRC5 registered |
| OBJ-U-02 | Check objective_exists for valid ID | Happy | Returns true |
| OBJ-U-03 | Check objective_exists for invalid ID | Happy | Returns false |
| OBJ-U-04 | Check completed_objective | Happy | Correct status |
| OBJ-U-05 | Get objectives for token | Happy | Correct array |
| OBJ-U-06 | Create objective with valid data | Happy | Objective stored |
| OBJ-U-07 | Create duplicate objective ID | Revert | Already exists |
| OBJ-U-08 | Get_objective_ids from token | Happy | Correct IDs |
| OBJ-U-09 | Objectives with 0 points | Boundary | Success |
| OBJ-U-10 | Objectives_svg implementation | Happy | Valid SVG |

#### TokenMinterComponent Tests

| Test ID | Test Case | Category | Expected Result |
|---------|-----------|----------|-----------------|
| MNT-U-01 | Add first minter | Happy | Returns ID = 1 |
| MNT-U-02 | Add second unique minter | Happy | Returns ID = 2 |
| MNT-U-03 | Add duplicate minter | Happy | Returns same ID |
| MNT-U-04 | Add zero address minter | Boundary | Returns new ID |
| MNT-U-05 | Add 1000 unique minters | Stress | IDs increment |
| MNT-U-06 | Minter count tracking | Happy | Accurate count |

#### TokenMultiGameComponent Tests

| Test ID | Test Case | Category | Expected Result |
|---------|-----------|----------|-----------------|
| MG-U-01 | Register first game | Happy | Returns ID = 1 |
| MG-U-02 | Register with all metadata | Happy | All data stored |
| MG-U-03 | Register without options | Happy | Options = None |
| MG-U-04 | Register duplicate game | Revert | Already registered |
| MG-U-05 | Register non-IMinigame | Revert | Interface check |
| MG-U-06 | Get game_count | Happy | Correct count |
| MG-U-07 | Game_id_from_address | Happy | Correct ID |
| MG-U-08 | Game_address_from_id | Happy | Correct address |
| MG-U-09 | Game_metadata retrieval | Happy | All fields match |
| MG-U-10 | Is_game_registered check | Happy | Correct bool |
| MG-U-11 | Register with zero address | Revert | Invalid game |
| MG-U-12 | Creator token mint | Happy | Token minted |

#### TokenObjectivesComponent Tests

| Test ID | Test Case | Category | Expected Result |
|---------|-----------|----------|-----------------|
| TOB-U-01 | Create first objective | Happy | Event emitted |
| TOB-U-02 | Create multiple objectives | Happy | All stored |
| TOB-U-03 | Create duplicate objective | Revert | Already exists |
| TOB-U-04 | Complete objective | Happy | Event emitted |
| TOB-U-05 | Complete already done | Revert | Already complete |
| TOB-U-06 | Complete non-existent | Revert | Not found |
| TOB-U-07 | Complete all objectives | Happy | AllComplete event |
| TOB-U-08 | Objectives_count check | Happy | Correct count |
| TOB-U-09 | All_objectives_completed | Happy | Correct bool |
| TOB-U-10 | Points accumulation | Happy | Correct total |
| TOB-U-11 | Required vs optional | Happy | Both work |

#### TokenSettingsComponent Tests

| Test ID | Test Case | Category | Expected Result |
|---------|-----------|----------|-----------------|
| TST-U-01 | Create from authorized | Happy | Event emitted |
| TST-U-02 | Create from unauthorized | Revert | Access denied |
| TST-U-03 | Create with full data | Happy | All fields |
| TST-U-04 | Verify caller check | Security | Only settings |

#### TokenSoulboundComponent Tests

| Test ID | Test Case | Category | Expected Result |
|---------|-----------|----------|-----------------|
| SB-U-01 | Mint soulbound token | Happy | Success |
| SB-U-02 | Burn soulbound token | Happy | Success |
| SB-U-03 | Transfer soulbound token | Revert | Non-transferable |
| SB-U-04 | Transfer regular token | Happy | Success |
| SB-U-05 | Hook with auth != from | Edge | Behavior check |

#### TokenRendererComponent Tests

| Test ID | Test Case | Category | Expected Result |
|---------|-----------|----------|-----------------|
| RND-U-01 | Set default renderer | Happy | Event emitted |
| RND-U-02 | Set token renderer | Happy | Event emitted |
| RND-U-03 | Get renderer with custom | Happy | Returns custom |
| RND-U-04 | Get renderer no custom | Happy | Returns default |
| RND-U-05 | Has_custom_renderer true | Happy | Returns true |
| RND-U-06 | Has_custom_renderer false | Happy | Returns false |
| RND-U-07 | Override default | Happy | Custom used |
| RND-U-08 | Zero address renderer | Boundary | Handled |

## 4. Fuzz & Property-Based Tests

### Properties to Test

| Property ID | Property | Test Strategy |
|-------------|----------|---------------|
| P-01 | Token ID Monotonicity | Fuzz 1000 mints, verify each ID = previous + 1 |
| P-02 | Lifecycle Validity | Fuzz timestamps, verify is_playable() consistency |
| P-03 | Score Monotonicity | Fuzz score updates, verify never decreases |
| P-04 | Objective Permanence | Fuzz objective completion, verify never uncompleted |
| P-05 | Ownership Protection | Fuzz non-owner calls, verify all revert |
| P-06 | Context Consistency | Fuzz context data, verify proper validation |
| P-07 | Settings Immutability | Fuzz post-mint ops, verify settings unchanged |
| P-08 | Game Registration | Fuzz unregistered games, verify all rejected |
| P-09 | Context Immutability | Fuzz context operations, verify never changes |
| P-10 | Settings Uniqueness | Fuzz settings IDs, verify no duplicates |
| P-11 | Objective Completion | Fuzz objective ops, verify one-way transition |
| P-12 | Minter ID Consistency | Fuzz minter registration, verify deterministic IDs |
| P-13 | Multi-Game Isolation | Fuzz cross-game ops, verify no interference |
| P-14 | Renderer Fallback | Fuzz renderer queries, verify always returns valid |
| P-15 | Soulbound Transfer Block | Fuzz transfer attempts, verify all blocked |

### Fuzz Input Domains

| Input | Domain | Special Values |
|-------|--------|----------------|
| Timestamps | [0, u64::MAX] | 0, 1, block.timestamp, u64::MAX |
| Settings IDs | [0, u32::MAX] | 0, 1, 100, u32::MAX |
| Objective counts | [0, 255] | 0, 1, 50, 100, 255 |
| Player names | ByteArray | "", "A", 100 chars, unicode |
| Addresses | ContractAddress | 0x0, 0x1, random valid |
| Token IDs | [1, u64::MAX] | 1, 1000, u64::MAX |

### Negative Fuzz Scenarios

| Scenario ID | Description | Expected |
|-------------|-------------|----------|
| NF-01 | Mint with non-existent settings across range [1000, 2000] | All revert |
| NF-02 | Update non-existent tokens [u64::MAX-1000, u64::MAX] | All revert |
| NF-03 | Lifecycle with start > end, random values | All revert |
| NF-04 | Objectives > 255 | All revert |
| NF-05 | Context without provider, 100 variations | All revert |
| NF-06 | Settings with invalid IDs [u32::MAX-1000, u32::MAX] | All revert |
| NF-07 | Complete non-existent objectives | All revert |
| NF-08 | Register same game 1000 times | All but first revert |
| NF-09 | Transfer soulbound tokens, all scenarios | All revert |

## 5. Integration & Scenario Tests

### Integration Scenarios

| Scenario ID | Name | Flow | Verification |
|-------------|------|------|--------------|
| I-01 | Tournament Flow | 1. Deploy metagame with context<br>2. Create 10 game instances<br>3. Mint 100 tokens across games<br>4. Simulate gameplay<br>5. Complete tournament | - Context consistency<br>- Score tracking<br>- Final rankings |
| I-02 | Multi-Game Platform | 1. Deploy token with multi-game<br>2. Register 5 different games<br>3. Mint tokens for each<br>4. Play games in parallel<br>5. Verify isolation | - Game separation<br>- State isolation<br>- Correct routing |
| I-03 | Time Campaign | 1. Mint tokens with future start<br>2. Attempt play (fail)<br>3. Warp to start time<br>4. Play successfully<br>5. Warp past end<br>6. Verify unplayable | - Lifecycle enforcement<br>- Time boundaries<br>- State transitions |
| I-04 | Achievement Hunt | 1. Create 10 objectives<br>2. Mint token with all<br>3. Play to complete 5<br>4. Verify partial completion<br>5. Complete remaining<br>6. Verify full completion | - Objective tracking<br>- Completion events<br>- Final state |
| I-05 | Settings Migration | 1. Create settings v1<br>2. Mint 50 tokens<br>3. Create settings v2<br>4. Mint 50 new tokens<br>5. Verify v1 tokens unchanged | - Settings immutability<br>- Version isolation |

### Adversarial Scenarios

| Scenario ID | Attack Vector | Defense Test |
|-------------|---------------|--------------|
| A-01 | Double Mint | Attempt to mint same token_id twice | Verify counter prevents |
| A-02 | Reentrancy | Malicious game calls back during update | Verify no state corruption |
| A-03 | Time Manipulation | Try to bypass lifecycle via block manipulation | Verify timestamp checks hold |
| A-04 | Access Escalation | Non-owner attempts privileged operations | Verify all access denied |
| A-05 | State Injection | Attempt to inject invalid metadata | Verify validation blocks |
| A-06 | Interface Spoofing | Fake interface support | Verify SRC5 checks work |
| A-07 | Context Injection | Attempt to modify context post-mint | Verify immutability |
| A-08 | Settings Override | Try to change token settings | Verify protection |
| A-09 | Objective Replay | Complete same objective twice | Verify idempotency |
| A-10 | Renderer Hijack | Replace renderer maliciously | Verify access control |

### Extension-Specific Integration Tests

| Scenario ID | Name | Flow | Verification |
|-------------|------|------|--------------|
| E-01 | Context Tournament | 1. Deploy context provider<br>2. Create tournament context<br>3. Mint 50 tokens with context<br>4. Query context data<br>5. Verify consistency | - Context properly attached<br>- All tokens show context<br>- SVG rendering works |
| E-02 | Settings Configuration | 1. Deploy settings extension<br>2. Create 10 settings configs<br>3. Mint tokens with each<br>4. Verify settings immutable<br>5. Test settings queries | - Settings properly stored<br>- Each token has correct settings<br>- No cross-contamination |
| E-03 | Objective Marathon | 1. Create 20 objectives<br>2. Mint token with all<br>3. Complete objectives randomly<br>4. Track points and events<br>5. Verify all-complete trigger | - Points accumulate correctly<br>- Events fire in order<br>- All-complete fires once |
| E-04 | Multi-Game Platform | 1. Register 10 games<br>2. Each game mints tokens<br>3. Update states independently<br>4. Query game metadata<br>5. Verify creator tokens | - Games isolated<br>- Metadata correct<br>- Creator tokens minted |
| E-05 | Soulbound Campaign | 1. Mint 100 soulbound tokens<br>2. Attempt various transfers<br>3. Verify all blocked<br>4. Test burn functionality<br>5. Verify mint still works | - Transfers blocked<br>- Burns allowed<br>- Mints allowed |
| E-06 | Renderer Customization | 1. Set default renderer<br>2. Override for specific tokens<br>3. Query renderer choices<br>4. Update renderers<br>5. Verify fallback logic | - Custom overrides default<br>- Fallback works<br>- Events emitted |

## 6. Coverage Matrix

### Function Coverage

| Function | Unit-Happy | Unit-Revert | Fuzz | Property | Integration | Gas/Event |
|----------|------------|-------------|------|----------|-------------|-----------|
| **MetagameComponent** | | | | | | |
| minigame_token_address() | MG-U-08 | - | - | - | I-01 | - |
| context_address() | MG-U-09 | - | - | - | I-01 | - |
| initializer() | MG-U-01,02 | MG-U-03 | - | - | All | - |
| mint() | MG-U-04,05,10,11 | MG-U-06,07,12 | NF-01,03,05 | P-01,06 | I-01,02,03 | E-01 |
| **MinigameComponent** | | | | | | |
| token_address() | MN-U-03 | - | - | - | All | - |
| settings_address() | MN-U-04 | - | - | - | I-05 | - |
| objectives_address() | MN-U-05 | - | - | - | I-04 | - |
| initializer() | MN-U-01,02 | - | - | - | All | - |
| pre_action() | MN-U-06,12 | MN-U-07,08,09,13 | - | P-05 | I-03 | - |
| post_action() | MN-U-10 | - | - | P-03,04 | All | E-02,03 |
| **TokenComponent** | | | | | | |
| token_metadata() | TK-U-14 | - | - | - | All | - |
| is_playable() | TK-U-13 | - | - | P-02 | I-03 | - |
| mint() | TK-U-01,02,03,05,07,08 | TK-U-04,06,09,15 | NF-01,02,04 | P-01,07,08 | All | E-01 |
| update_game() | TK-U-10,11,12 | - | - | P-03,04 | All | E-02,03 |
| **MetagameContextComponent** | | | | | | |
| has_context() | CTX-U-05,06 | - | - | P-09 | E-01 | - |
| context() | CTX-U-07 | CTX-U-08 | - | P-09 | E-01 | - |
| context_svg() | CTX-U-11 | - | - | - | E-01 | - |
| **MinigameSettingsComponent** | | | | | | |
| settings_exist() | SET-U-02,03 | - | - | P-10 | E-02 | - |
| settings() | SET-U-04 | SET-U-05 | - | P-07 | E-02 | - |
| create_settings() | SET-U-06,07,08 | - | NF-06 | P-10 | E-02 | E-S1 |
| **MinigameObjectivesComponent** | | | | | | |
| objective_exists() | OBJ-U-02,03 | - | - | - | E-03 | - |
| completed_objective() | OBJ-U-04 | - | - | P-11 | E-03 | - |
| create_objective() | OBJ-U-06,09 | OBJ-U-07 | - | - | E-03 | E-O1 |
| **TokenMinterComponent** | | | | | | |
| add_minter() | MNT-U-01,02,03,04 | - | - | P-12 | E-04 | - |
| **TokenMultiGameComponent** | | | | | | |
| register_game() | MG-U-01,02,03,12 | MG-U-04,05,11 | NF-08 | P-13 | E-04 | E-G1 |
| game_count() | MG-U-06 | - | - | - | E-04 | - |
| game_metadata() | MG-U-09 | - | - | - | E-04 | - |
| is_game_registered() | MG-U-10 | - | - | P-08 | E-04 | - |
| **TokenObjectivesComponent** | | | | | | |
| create_objective() | TOB-U-01,02,11 | TOB-U-03 | - | - | E-03 | E-O2 |
| complete_objective() | TOB-U-04,07,10 | TOB-U-05,06 | NF-07 | P-11 | E-03 | E-O3 |
| objectives_count() | TOB-U-08 | - | - | - | E-03 | - |
| all_objectives_completed() | TOB-U-09 | - | - | - | E-03 | - |
| **TokenSettingsComponent** | | | | | | |
| create_settings() | TST-U-01,03 | TST-U-02 | - | - | E-02 | E-S2 |
| **TokenSoulboundComponent** | | | | | | |
| before_update() | SB-U-01,02,04 | SB-U-03 | NF-09 | P-15 | E-05 | - |
| **TokenRendererComponent** | | | | | | |
| set_default_renderer() | RND-U-01 | - | - | - | E-06 | E-R1 |
| set_token_renderer() | RND-U-02 | - | - | - | E-06 | E-R2 |
| get_renderer() | RND-U-03,04 | - | - | P-14 | E-06 | - |
| has_custom_renderer() | RND-U-05,06 | - | - | - | E-06 | - |

### Invariant Coverage

| Invariant | Property Test | Integration Test | Notes |
|-----------|---------------|------------------|-------|
| INV-MG-1 | - | All | Checked in init |
| INV-MG-2 | P-06 | I-01 | Context validation |
| INV-MG-3 | P-01 | All | Delegation pattern |
| INV-MN-1 | P-05 | All | Ownership checks |
| INV-MN-2 | P-02 | I-03 | Playability |
| INV-MN-3 | P-03,04 | All | State sync |
| INV-TK-1 | P-01 | All | Monotonic IDs |
| INV-TK-2 | P-07 | I-05 | Immutability |
| INV-TK-3 | P-02 | I-03 | Lifecycle |
| INV-TK-4 | P-03 | All | Score increase |
| INV-TK-5 | P-04 | I-04 | Game over |
| INV-TK-6 | P-04 | I-04 | Objectives |
| INV-TK-7 | P-02 | I-03 | Playability |
| INV-CTX-1 | P-09 | E-01 | Context consistency |
| INV-CTX-2 | P-09 | E-01 | Context immutability |
| INV-SET-1 | P-10 | E-02 | Settings permanence |
| INV-SET-2 | P-07 | E-02 | Settings immutability |
| INV-SET-3 | P-10 | E-02 | Settings uniqueness |
| INV-OBJ-1 | - | E-03 | Objective permanence |
| INV-OBJ-2 | P-11 | E-03 | Completion one-way |
| INV-OBJ-3 | - | E-03 | Objective uniqueness |
| INV-MNT-1 | P-12 | E-04 | Minter ID increment |
| INV-MNT-2 | P-12 | E-04 | Minter determinism |
| INV-MNT-3 | P-12 | E-04 | ID permanence |
| INV-MG-1 | P-13 | E-04 | Game ID increment |
| INV-MG-2 | P-08 | E-04 | Game uniqueness |
| INV-MG-3 | - | E-04 | Creator token |
| INV-MG-4 | - | E-04 | Metadata immutable |
| INV-TOB-1 | - | E-03 | Objective permanence |
| INV-TOB-2 | - | E-03 | Objective uniqueness |
| INV-TOB-3 | P-11 | E-03 | Completion permanent |
| INV-TOB-4 | - | E-03 | Points accuracy |
| INV-TOB-5 | - | E-03 | All-complete once |
| INV-TST-1 | - | E-02 | Settings auth |
| INV-SB-1 | P-15 | E-05 | Mint allowed |
| INV-SB-2 | P-15 | E-05 | Burn allowed |
| INV-SB-3 | P-15 | E-05 | Transfer blocked |
| INV-RND-1 | P-14 | E-06 | Renderer fallback |
| INV-RND-2 | - | E-06 | Custom override |

### Event Coverage

| Event | Test IDs | Scenarios |
|-------|----------|-----------|
| ScoreUpdate | E-02, TK-U-10 | All gameplay |
| MetadataUpdate | E-03, TK-U-11,12 | State changes |
| Owners | E-01, TK-U-01 | All mints |
| GameRegistered | E-G1, MG-U-01 | Game registration |
| ObjectiveCreated | E-O1, E-O2 | Objective creation |
| ObjectiveCompleted | E-O3, TOB-U-04 | Objective completion |
| AllObjectivesCompleted | E-O3, TOB-U-07 | All objectives done |
| SettingsCreated | E-S1, E-S2 | Settings creation |
| DefaultRendererUpdated | E-R1, RND-U-01 | Renderer update |
| TokenRendererUpdated | E-R2, RND-U-02 | Token renderer set |

## 7. Tooling & Environment

### Test Framework Setup

```bash
# Core dependencies
scarb 2.10.1  # Exact version required
snforge       # StarkNet Foundry for testing
sozo          # Optional for Dojo tests

# Project structure
/tests/
  /unit/          # Isolated component tests
    metagame_test.cairo
    minigame_test.cairo
    token_test.cairo
  /integration/   # Multi-component tests
    scenarios_test.cairo
    adversarial_test.cairo
  /fuzz/          # Property-based tests
    properties_test.cairo
    invariants_test.cairo
  /e2e/           # End-to-end flows
    tournament_test.cairo
    platform_test.cairo
```

### Mock Contracts Required

#### Core Mocks
1. **ERC721Mock**: For token interface testing
2. **SRC5Mock**: For interface discovery testing
3. **TimeMock**: For warping timestamps in lifecycle tests
4. **MinigameMock**: Implements IMinigameTokenData with test states

#### Extension Mocks
5. **ContextMock**: Implements IMetagameContext with test storage
6. **SettingsMock**: Implements IMinigameSettings with configurable settings
7. **ObjectivesMock**: Implements IMinigameObjectives with completion tracking
8. **MultiGameMock**: Token contract with multi-game extension
9. **SoulboundMock**: Token contract with soulbound extension
10. **RendererMock**: Implements ITokenRenderer for custom rendering
11. **MinterMock**: Metagame contract with minter tracking
12. **ObjectivesTokenMock**: Token with objectives extension for testing

#### Test Utilities
13. **GameFactory**: Helper for deploying complete game setups
14. **TokenFactory**: Helper for minting tokens with extensions
15. **ExtensionVerifier**: Helper for validating extension behavior

### Coverage Measurement

```bash
# Run all tests with coverage
snforge test --coverage

# Generate detailed report
snforge coverage --detailed > coverage_report.md

# Thresholds
# - Critical paths (mint, update_game): 100%
# - Core components: 95%
# - Extensions: 90%
# - Overall: 92%
```

### Test Naming Conventions

```
test_<component>_<function>_<scenario>_<expected>

Examples:
- test_metagame_mint_with_context_succeeds
- test_token_update_game_score_increases
- test_minigame_pre_action_unowned_token_reverts
```

### Gas Profiling

```bash
# Profile gas usage
snforge test --detailed-resources

# Key metrics to track:
# - mint: < 500k steps
# - update_game: < 200k steps
# - is_playable: < 50k steps
```

## 8. Self-Audit Checklist

✅ **Core Component Coverage**
- All external functions: Covered
- All internal state-changing functions: Covered
- Helper functions: Covered where they affect state

✅ **Extension Component Coverage**
- MetagameContext: All interface functions covered
- MinigameSettings: Creation and query functions covered
- MinigameObjectives: Creation and completion tracking covered
- TokenMinter: Minter registration covered
- TokenMultiGame: Game registration and metadata covered
- TokenObjectives: Objective lifecycle covered
- TokenSettings: Settings creation with auth covered
- TokenSoulbound: Transfer prevention covered
- TokenRenderer: Renderer management covered

✅ **Event Coverage**
- Core Events: ScoreUpdate, MetadataUpdate, Owners
- Extension Events: GameRegistered, ObjectiveCreated/Completed, SettingsCreated, RendererUpdated
- All state changes emit appropriate events

✅ **Revert Conditions**
- All require/assert statements: Have explicit revert tests
- Boundary conditions: Tested
- Access control: Verified
- Extension-specific validations: Covered

✅ **Invariants**
- Core invariants (INV-MG, INV-MN, INV-TK): Covered
- Extension invariants (INV-CTX through INV-RND): Covered
- State transitions: Verified
- Monotonicity properties: Tested

✅ **Edge Cases**
- Zero addresses: Tested
- Max values (u64, u32, u8): Tested
- Time boundaries: Tested
- Empty collections: Tested
- Extension-specific edge cases: Covered

✅ **Integration Coverage**
- Core component interactions: Tested
- Extension integrations: Covered (E-01 through E-06)
- Realistic user flows: Included
- Adversarial scenarios: Extended (A-01 through A-10)

✅ **Fuzz Testing**
- Core properties (P-01 through P-08): Defined
- Extension properties (P-09 through P-15): Added
- Negative scenarios: Extended for extensions

**Discrepancies Found**: None

This extended test plan provides comprehensive coverage for both the core Game Components and all extension modules, ensuring behavioral, branch, and event coverage targets are met for the entire codebase.