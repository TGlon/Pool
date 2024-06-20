import "@stdlib/deploy";
import "@stdlib/ownable";

message Add_Liquidity {
    token0: Address;
    amount_token0: Int as coins;
    token1: Address;
    amount_token1: Int as coins;
}
message SwapTokenA{
    amountToken0: Int as coins;
    receiver: Address;
}
message SwapTokenB{
    amountToken1: Int as coins;
    receiver: Address;
}
contract LiquidityPool with Deployable {
    token0: Address;
    token1: Address;
    fee0: Int as coins;
    fee1: Int as coins;
    fee_percent: Int;
    lsp_supply: Int;
    query_counter: Int;

    init(token0: Address, token1: Address, fee_percent: Int) {
        self.token0 = token0;
        self.token1 = token1;
        self.fee0 = 0;
        self.fee1 = 0;
        self.fee_percent = fee_percent;
        self.lsp_supply = 0;
        self.query_counter = 0; // Initialize the query counter
    }

    receive(msg: Add_Liquidity) {
        self.add_liquidity(msg.token0, msg.token1, msg.amount_token0, msg.amount_token1);
    }

    // fun add_liquidity(amount_token0: Int, amount_token1: Int) {
    //     let ctx: Context = context();
    //     require(ctx.value > 0, "Invalid value!");
        
    //     let supply_to_add: Int = self.calculate_initial_supply(amount_token0, amount_token1);
    //     self.lsp_supply = self.lsp_supply + supply_to_add;

    //     // Transfer token0 and token1 from the sender to the contract
    //     send(SendParameters{
    //         to: self.token0,
    //         value: 0,
    //         bounce: true,
    //         mode: SendRemainingValue,
    //         body: TransferRequest{
    //             amount: amount_token0,
    //             to: myAddress()
    //         }.toCell()
    //     });

    //     send(SendParameters{
    //         to: self.token1,
    //         value: 0,
    //         bounce: true,
    //         mode: SendRemainingValue,
    //         body: TransferRequest{
    //             amount: amount_token1,
    //             to: myAddress()
    //         }.toCell()
    //     });
    // }
    fun add_liquidity(token0: Address, token1: Address, amount_token0: Int, amount_token1: Int) {
        let ctx: Context = context();
        require(ctx.value > 0, "Invalid value!");
        require(amount_token0 > 0, "amount_token0 must be greater than 0!");
        require(amount_token1 > 0, "amount_token1 must be greater than 0!");
        
        let supply_to_add: Int = self.calculate_initial_supply(amount_token0, amount_token1);
        require(supply_to_add > 0, "supply_to_add must be greater than 0!");

        self.lsp_supply = self.lsp_supply + supply_to_add;
        require(self.lsp_supply > 0, "lsp_supply must be greater than 0!");
        // Transfer token0 from the sender to the contract
        send(SendParameters{
            to: token0,
            value: 0,
            bounce: false,
            mode: 3,
            body: TokenTransferInternal{
                queryId: self.query_counter,
                amount: amount_token0,
                from: ctx.sender, 
                response_destination: myAddress(), // Transfer to the pool's address
                forward_ton_amount: 0,
                forward_payload: emptySlice()
            }.toCell()
        });

        // Transfer token1 from the sender to the contract
        send(SendParameters{
            to: token1,
            value: 0,
            bounce: false,
            mode: 3,
            body: TokenTransferInternal{
                queryId: self.query_counter,
                amount: amount_token1,
                from: ctx.sender,
                response_destination: myAddress(), // Transfer to the pool's address
                forward_ton_amount: 0,
                forward_payload: emptySlice()
            }.toCell()
        });

        self.query_counter = self.query_counter + 1; // Increment query counter after transactions
}


    fun calculate_initial_supply(amount_token0: Int, amount_token1: Int): Int {
        let product: Int = amount_token0 * amount_token1;
        return self.sqrt(product);
    }

    fun sqrt(x: Int): Int {
        if (x == 0) {
            return 0;
        }
        let z: Int = (x + 1) / 2;
        let y: Int = x;
        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
        }
        return y;
    }

    fun increase_supply(amount: Int) {
        self.lsp_supply = self.lsp_supply + amount;
    }
    receive(msg: SwapTokenA){
        self.swap_tokenA(msg.amountToken0, msg.receiver);
    }
    fun swap_tokenA(amount_token0: Int, receiver: Address) {
        let ctx: Context = context();
        let token0_balance: Int = self.token_balance(self.token0);
        let token1_balance: Int = self.token_balance(self.token1);
        
        let amount_token1: Int = (amount_token0 * token1_balance) / (token0_balance + amount_token0);
        let fee: Int = (amount_token1 * self.fee_percent) / 100;
        amount_token1 = amount_token1 - fee;
        
        self.fee1 = self.fee1 + fee;
        
        // Transfer token0 from the sender to the contract and token1 to the sender
        send(SendParameters{
            to: self.token0,
            value: amount_token0,
            bounce: true,
            body: TransferRequest{
            queryId: 0,
            amount: amount_token0,
            from: myAddress(),
            response_destination: receiver,
            forward_ton_amount: 0,
            forward_payload: emptySlice()
            }.toCell()
        });

        send(SendParameters{
            to: ctx.sender,
            value: amount_token1,
            bounce: true,
            body: TransferRequest{
            queryId: 0,
            amount: amount_token1,
            from: myAddress(),
            response_destination: receiver,
            forward_ton_amount: 0,
            forward_payload: emptySlice()
            }.toCell()
        });
    }
    receive(msg: SwapTokenB){
        self.swap_tokenB(msg.amountToken1, msg.receiver);
    }
    fun swap_tokenB(amount_token1: Int, receiver: Address) {
        let ctx: Context = context();
        let token0_balance: Int = self.token_balance(self.token0);
        let token1_balance: Int = self.token_balance(self.token1);
        
        let amount_token0:Int = (amount_token1 * token0_balance) / (token1_balance + amount_token1);
        let fee:Int = (amount_token0 * self.fee_percent) / 100;
        amount_token0 = amount_token0 - fee;
        
        self.fee0 = self.fee0 + fee;
        
        // Transfer token1 from the sender to the contract and token0 to the sender
        send(SendParameters{
            to: self.token1,
            value: amount_token1,
            bounce: true,
            body: TransferRequest{
                    queryId: 0,
            amount: amount_token1,
            from: myAddress(),
            response_destination: receiver,
            forward_ton_amount: 0,
            forward_payload: emptySlice()
            }.toCell()
        });

        send(SendParameters{
            to: ctx.sender,
            value: amount_token0,
            bounce: true,
            body: TransferRequest{
                    queryId: 0,
            amount: amount_token0,
            from: myAddress(),
            response_destination: receiver,
            forward_ton_amount: 0,
            forward_payload: emptySlice()
            }.toCell()
        });
    }

    fun token_balance(token: Address): Int {
        // Assumes a synchronous call for simplicity. This may need to be adapted for the specific blockchain you're using.
        let balance_query:TokenBalanceQuery = TokenBalanceQuery{
            address: myAddress()
        };

        send(SendParameters{
            to: token,
            value: 0,
            bounce: false,
            body: balance_query.toCell()
        });
        let response: TokenBalanceResponse = TokenBalanceResponse {
            balance: 0
        };

        return response.balance;
    }
    get fun getBalance(token: Address): Int {
        return self.token_balance(token);
    }
}

message TransferRequest {
    queryId: Int as uint64;
    amount: Int as coins;
    from: Address;
    response_destination: Address;
    forward_ton_amount: Int as coins;
    forward_payload: Slice as remaining;
}

message TokenBalanceQuery {
    address: Address;
}

message TokenBalanceResponse {
    balance: Int as coins;
}


struct JettonData {
    totalSupply: Int;
    mintable: Bool;
    owner: Address;
    content: Cell;
    walletCode: Cell;
}
// ============================================================================================================ //
@interface("org.ton.jetton.master")
trait Jetton with Ownable {

    totalSupply: Int; // Already set initially 
    mintable: Bool;
    owner: Address;
    content: Cell;

    max_supply: Int; // This is not in the TEP-74 interface

    receive(msg: TokenUpdateContent) {
        self.requireOwner();                // Allow changing content only by owner
        self.content = msg.content;         // Update content
    }

    receive(msg: TokenBurnNotification) {
        self.requireWallet(msg.owner);                     // Check wallet
        self.totalSupply = self.totalSupply - msg.amount; // Update supply

        if (msg.response_destination != null) { // Cashback
            send(SendParameters{
                to: msg.response_destination!!, 
                value: 0,
                bounce: false,
                mode: SendRemainingValue + SendIgnoreErrors,
                body: TokenExcesses{
                    queryId: msg.queryId
                }.toCell()
            });
        }
    }

    // @to The Address receive the Jetton token after minting
    // @amount The amount of Jetton token being minted
    // @response_destination The previous owner address
    fun mint(to: Address, amount: Int, response_destination: Address) {
        require(self.totalSupply + amount <= self.max_supply, "The total supply will be overlapping.");
        self.totalSupply = self.totalSupply + amount; // Update total supply

        let winit: StateInit = self.getJettonWalletInit(to); // Create message
        send(SendParameters{
            to: contractAddress(winit), 
            value: 0, 
            bounce: false,
            mode: SendRemainingValue,
            body: TokenTransferInternal{ 
                queryId: 0,
                amount: amount,
                from: myAddress(),
                response_destination: response_destination,
                forward_ton_amount: 0,
                forward_payload: emptySlice()
            }.toCell(),
            code: winit.code,
            data: winit.data
        });
    }

    fun requireWallet(owner: Address) {
        let ctx: Context = context();
        let winit: StateInit = self.getJettonWalletInit(owner);
        require(contractAddress(winit) == ctx.sender, "Invalid sender");
    }

    virtual fun getJettonWalletInit(address: Address): StateInit {
        return initOf JettonDefaultWallet(myAddress(), address);
    }

    // ====== Get Methods ====== //
    get fun get_jetton_data(): JettonData {
        let code: Cell = self.getJettonWalletInit(myAddress()).code;
        return JettonData{ 
            totalSupply: self.totalSupply, 
            mintable: self.mintable, 
            owner: self.owner, 
            content: self.content, 
            walletCode: code
        };
    }

    get fun get_wallet_address(owner: Address): Address {
        let winit: StateInit = self.getJettonWalletInit(owner);
        return contractAddress(winit);
    }
}
// ============================================================ //
@interface("org.ton.jetton.wallet")
contract JettonDefaultWallet {
    const minTonsForStorage: Int = ton("0.01");
    const gasConsumption: Int = ton("0.01");

    balance: Int;
    owner: Address;
    master: Address;

    init(master: Address, owner: Address) {
        self.balance = 0;
        self.owner = owner;
        self.master = master;
    }

    receive(msg: TokenTransfer) { // 0xf8a7ea5
        let ctx: Context = context(); // Check sender
        require(ctx.sender == self.owner, "Invalid sender");

        // Gas checks
        let fwdFee: Int = ctx.readForwardFee() + ctx.readForwardFee();  
        let final: Int =  2 * self.gasConsumption + self.minTonsForStorage + fwdFee;
        require(ctx.value > min(final, ton("0.01")), "Invalid value!!"); 

        // Update balance
        self.balance = self.balance - msg.amount; 
        require(self.balance >= 0, "Invalid balance");

        let init: StateInit = initOf JettonDefaultWallet(self.master, msg.destination);  
        let walletAddress: Address = contractAddress(init);
        send(SendParameters{
                to: walletAddress, 
                value: 0,
                mode: SendRemainingValue, 
                bounce: false,
                body: TokenTransferInternal{
                    queryId: msg.queryId,
                    amount: msg.amount,
                    from: self.owner,
                    response_destination: msg.response_destination,
                    forward_ton_amount: msg.forward_ton_amount,
                    forward_payload: msg.forward_payload
                }.toCell(),
                code: init.code,
                data: init.data
            });
    }

    receive(msg: TokenTransferInternal) { // 0x178d4519
        let ctx: Context = context();

        if (ctx.sender != self.master) {
            let sinit: StateInit = initOf JettonDefaultWallet(self.master, msg.from);
            require(contractAddress(sinit) == ctx.sender, "Invalid sender!");
        }

        // Update balance
        self.balance = self.balance + msg.amount;
        require(self.balance >= 0, "Invalid balance"); 
        
        // Get value for gas
        let msgValue: Int = self.msgValue(ctx.value);  
        let fwdFee: Int = ctx.readForwardFee();
        msgValue = msgValue - msg.forward_ton_amount - fwdFee;
        
         // 0x7362d09c - notify the new owner of JettonToken that the transfer is complete
        if (msg.forward_ton_amount > 0) { 
            send(SendParameters{
                to: self.owner,
                value: msg.forward_ton_amount,
                mode: SendPayGasSeparately + SendIgnoreErrors,
                bounce: false,
                body: TokenNotification {
                    queryId: msg.queryId,
                    amount: msg.amount,
                    from: msg.from,
                    forward_payload: msg.forward_payload
                }.toCell()
            });
        }

        // 0xd53276db -- Cashback to the original Sender
        if (msg.response_destination != null) { 
            send(SendParameters {
                to: msg.response_destination, 
                value: msgValue,  
                bounce: false,
                body: TokenExcesses { 
                    queryId: msg.queryId
                }.toCell(),
                mode: SendIgnoreErrors
            });
        }
    }

    receive(msg: TokenBurn) {
        let ctx: Context = context();
        require(ctx.sender == self.owner, "Invalid sender");  // Check sender

        self.balance = self.balance - msg.amount; // Update balance
        require(self.balance >= 0, "Invalid balance");

        let fwdFee: Int = ctx.readForwardFee(); // Gas checks
        require(ctx.value > fwdFee + 2 * self.gasConsumption + self.minTonsForStorage, "Invalid value - Burn");

        // Burn tokens
        send(SendParameters{  
            to: self.master,
            value: 0,
            mode: SendRemainingValue,
            bounce: true,
            body: TokenBurnNotification{
                queryId: msg.queryId,
                amount: msg.amount,
                owner: self.owner,
                response_destination: self.owner
            }.toCell()
        });
    }

    get fun msgValue(value: Int): Int {
        let msgValue: Int = value;
        let tonBalanceBeforeMsg: Int = myBalance() - msgValue;
        let storageFee: Int = self.minTonsForStorage - min(tonBalanceBeforeMsg, self.minTonsForStorage);
        msgValue = msgValue - (storageFee + self.gasConsumption);
        return msgValue;
    }

    bounced(src: bounced<TokenTransferInternal>) {
        self.balance = self.balance + src.amount;
    }

    bounced(src: bounced<TokenBurnNotification>) {
        self.balance = self.balance + src.amount;
    }

    get fun get_wallet_data(): JettonWalletData {
        return JettonWalletData{
            balance: self.balance,
            owner: self.owner,
            master: self.master,
            walletCode: (initOf JettonDefaultWallet(self.master, self.owner)).code
        };
    }
}

struct JettonWalletData {
    balance: Int;
    owner: Address;
    master: Address;
    walletCode: Cell;
}

message(0xf8a7ea5) TokenTransfer {
    queryId: Int as uint64;
    amount: Int as coins;
    destination: Address;
    response_destination: Address;
    custom_payload: Cell?;
    forward_ton_amount: Int as coins;
    forward_payload: Slice as remaining; // Comment Text message when Transfer the jetton
}

message(0x178d4519) TokenTransferInternal {
    queryId: Int as uint64;
    amount: Int as coins;
    from: Address;
    response_destination: Address;
    forward_ton_amount: Int as coins;
    forward_payload: Slice as remaining; // Comment Text message when Transfer the jetton
}

message(0x7362d09c) TokenNotification {
    queryId: Int as uint64;
    amount: Int as coins;
    from: Address;
    forward_payload: Slice as remaining; // Comment Text message when Transfer the jetton 
}

message(0x595f07bc) TokenBurn {
    queryId: Int as uint64;
    amount: Int as coins;
    owner: Address;
    response_destination: Address;
}

message(0x7bdd97de) TokenBurnNotification {
    queryId: Int as uint64;
    amount: Int as coins;
    owner: Address;
    response_destination: Address?;
}

message(0xd53276db) TokenExcesses {
    queryId: Int as uint64;
}

message TokenUpdateContent {
    content: Cell;
}
