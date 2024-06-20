import { toNano, Address } from '@ton/core';
import { LiquidityPool } from '../wrappers/LiquidityPool';
import { NetworkProvider } from '@ton/blueprint';

export async function run(provider: NetworkProvider) {
    try {
        // Define the token addresses and fee percentage
        const token0 = Address.parse('kQApClTLLRtxIvASOpjvXfOInGVI_n8vvAo9T7tcmQTHyaDZ'); // Replace with actual token0 address
        const token1 = Address.parse('kQBPyvYXkDb2jzLch2w3uJyrUq1QhLjD0k-_0ptrIxd7cd3i'); // Replace with actual token1 address
        const fee_percent = 30n; // Replace with actual fee percentage, for example, 3%

        console.log('Initializing the liquidity pool contract...');
        
        // Initialize the liquidity pool contract
        const liquidityPoolInit = await LiquidityPool.fromInit(token0, token1, fee_percent);
        const liquidityPool = provider.open(liquidityPoolInit);

        console.log('Deploying the liquidity pool contract...');
        
        // Deploy the liquidity pool contract
        await liquidityPool.send(
            provider.sender(),
            {
                value: toNano('0.05'),
            },
            {
                $$type: 'Deploy',
                queryId: 0n,
            }
        );

        // Wait for the contract to be deployed
        await provider.waitForDeploy(liquidityPool.address);

        console.log('Contract deployed successfully at address:', liquidityPool.address.toString());

        // Define the amount of tokens to add as liquidity
        const amountToken0 = toNano('100');
        const amountToken1 = toNano('200');

        console.log('Adding liquidity to the pool...');

        // Add liquidity to the pool
        await liquidityPool.send(
            provider.sender(),
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

        console.log('Liquidity added to the pool successfully');
    } catch (error) {
        // Handle any errors that occur during the process
        console.error('An error occurred:', error);
    }
}
