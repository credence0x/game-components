use starknet::{ContractAddress, contract_address_const, get_caller_address};
use game_components_token::interface::IMinigameToken;
use game_components_token::structs::{TokenMetadata, Lifecycle};
use game_components_metagame::extensions::context::structs::GameContextDetails;
use openzeppelin_token::erc721::interface::IERC721;
use core::num::traits::Zero;

#[starknet::contract]
pub mod MockMinigameToken {
    use super::*;
    use starknet::storage::{Map, StorageMapReadAccess, StorageMapWriteAccess, StoragePointerReadAccess, StoragePointerWriteAccess};

    #[storage]
    struct Storage {
        // Token storage
        next_token_id: u64,
        token_game_address: Map<u64, ContractAddress>,
        token_owner: Map<u64, ContractAddress>,
    }

    #[constructor]
    fn constructor(ref self: ContractState) {
        self.next_token_id.write(1);
    }

    #[abi(embed_v0)]
    impl MinigameTokenImpl of IMinigameToken<ContractState> {
        fn token_metadata(self: @ContractState, token_id: u64) -> TokenMetadata {
            TokenMetadata {
                game_id: 1,
                minted_at: 0,
                settings_id: 0,
                lifecycle: Lifecycle {
                    start: 0,
                    end: 0,
                },
                minted_by: 0,
                soulbound: false,
                game_over: false,
                completed_all_objectives: false,
                has_context: false,
                objectives_count: 0,
            }
        }

        fn is_playable(self: @ContractState, token_id: u64) -> bool {
            // Token is playable if it exists and game is not over
            token_id < self.next_token_id.read()
        }

        fn settings_id(self: @ContractState, token_id: u64) -> u32 {
            0
        }

        fn player_name(self: @ContractState, token_id: u64) -> ByteArray {
            ""
        }

        fn mint(
            ref self: ContractState,
            game_address: Option<ContractAddress>,
            player_name: Option<ByteArray>,
            settings_id: Option<u32>,
            start: Option<u64>,
            end: Option<u64>,
            objective_ids: Option<Span<u32>>,
            context: Option<GameContextDetails>,
            client_url: Option<ByteArray>,
            renderer_address: Option<ContractAddress>,
            to: ContractAddress,
            soulbound: bool
        ) -> u64 {
            let token_id = self.next_token_id.read();
            self.next_token_id.write(token_id + 1);

            if let Option::Some(game_addr) = game_address {
                self.token_game_address.write(token_id, game_addr);
            }
            
            // Store ownership for testing
            self.token_owner.write(token_id, to);

            token_id
        }

        fn update_game(ref self: ContractState, token_id: u64) {
            // Mock implementation - no-op
        }
    }

    // Implement IERC721 for ownership checks
    #[abi(embed_v0)]
    impl ERC721Impl of IERC721<ContractState> {
        fn owner_of(self: @ContractState, token_id: u256) -> ContractAddress {
            // Convert token_id to u64
            let token_id_u64: u64 = token_id.try_into().unwrap();
            
            // Check if token exists
            if token_id_u64 >= self.next_token_id.read() {
                panic!("Token does not exist");
            }
            
            // Return the stored owner
            self.token_owner.read(token_id_u64)
        }

        fn safe_transfer_from(
            ref self: ContractState,
            from: ContractAddress,
            to: ContractAddress,
            token_id: u256,
            data: Span<felt252>
        ) {
            // Mock - no-op
        }

        fn transfer_from(
            ref self: ContractState, from: ContractAddress, to: ContractAddress, token_id: u256
        ) {
            // Mock - no-op
        }

        fn approve(ref self: ContractState, to: ContractAddress, token_id: u256) {
            // Mock - no-op
        }

        fn set_approval_for_all(
            ref self: ContractState, operator: ContractAddress, approved: bool
        ) {
            // Mock - no-op
        }

        fn get_approved(self: @ContractState, token_id: u256) -> ContractAddress {
            contract_address_const::<0x0>()
        }

        fn is_approved_for_all(
            self: @ContractState, owner: ContractAddress, operator: ContractAddress
        ) -> bool {
            false
        }

        fn balance_of(self: @ContractState, account: ContractAddress) -> u256 {
            1 // Mock - always return 1
        }
    }
}