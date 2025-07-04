// Mock Renderer contract for testing
#[starknet::contract]
pub mod MockRenderer {
    use starknet::ContractAddress;
    
    #[storage]
    struct Storage {}
    
    #[constructor]
    fn constructor(ref self: ContractState) {}
    
    // Mock render function
    #[abi(embed_v0)]
    fn render(self: @ContractState, token_id: u64) -> ByteArray {
        // Return mock rendered content
        "<html><body>Token #" + token_id.to_string() + "</body></html>"
    }
    
    // Mock render_svg function
    #[abi(embed_v0)]
    fn render_svg(self: @ContractState, token_id: u64) -> ByteArray {
        "<svg>Token #" + token_id.to_string() + "</svg>"
    }
}