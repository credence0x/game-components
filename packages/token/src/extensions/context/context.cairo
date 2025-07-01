
            // Set context if provided
            if let Option::Some(context) = params.context {
                let context_address = self.context_address.read();
                if !context_address.is_zero() {
                    let context_dispatcher = IMetagameContextDispatcher { contract_address: context_address };
                    context_dispatcher.set_context(token_id, context);
                }
            }