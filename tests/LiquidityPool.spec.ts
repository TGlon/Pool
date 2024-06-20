import { Blockchain, SandboxContract, TreasuryContract } from '@ton/sandbox';
import { toNano, Address } from '@ton/core';
import { LiquidityPool } from '../wrappers/LiquidityPool';
import '@ton/test-utils';

describe('LiquidityPool', () => {
    let blockchain: Blockchain;
    let deployer: SandboxContract<TreasuryContract>;
    let liquidityPool: SandboxContract<LiquidityPool>;

    beforeEach(async () => {
        blockchain = await Blockchain.create();
        const token0 = Address.parse('kQApClTLLRtxIvASOpjvXfOInGVI_n8vvAo9T7tcmQTHyaDZ'); // Replace with actual token0 address
        const token1 = Address.parse('kQBPyvYXkDb2jzLch2w3uJyrUq1QhLjD0k-_0ptrIxd7cd3i'); // Replace with actual token1 address
        const fee_percent = 30n;
        liquidityPool = blockchain.openContract(await LiquidityPool.fromInit(token0, token1, fee_percent));

        deployer = await blockchain.treasury('deployer');

        const deployResult = await liquidityPool.send(
            deployer.getSender(),
            {
                value: toNano('0.05'),
            },
            {
                $$type: 'Deploy',
                queryId: 0n,
            }
        );
        const amountToken0 = toNano('10'); 
        const amountToken1 = toNano('20'); 
        await liquidityPool.send(
            deployer.getSender(),
            {
                value: toNano('0.05'),
            },
            {
                $$type: 'Add_Liquidity',
                token0: token0,
                token1: token1,
                amount_token0: amountToken0,
                amount_token1: amountToken1,
            }
        );
        expect(deployResult.transactions).toHaveTransaction({
            from: deployer.address,
            to: liquidityPool.address,
            deploy: true,
            success: true,
        });
    });

    it('should deploy', async () => {
        // the check is done inside beforeEach
        // blockchain and liquidityPool are ready to use
    });
});
