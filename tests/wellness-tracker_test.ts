import { Clarinet, Tx, Chain, Account, types } from 'https://deno.land/x/clarinet@v1.5.0/index.ts';
import { assertEquals } from 'https://deno.land/std@0.177.0/testing/asserts.ts';

Clarinet.test({
  name: "wellness-tracker: Can initialize user profile",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const deployer = accounts.get('deployer')!;
    const block = chain.mineBlock([
      Tx.contractCall('wellness-tracker', 'initialize-user', 
        [types.principal(deployer.address)], 
        deployer.address
      )
    ]);
    
    // Assertions here
    assertEquals(block.receipts.length, 1);
  }
}); 

Clarinet.test({
  name: "wellness-tracker: Can log daily metrics",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const user = accounts.get('wallet_1')!;
    const block = chain.mineBlock([
      Tx.contractCall('wellness-tracker', 'log-daily-metrics', 
        [
          types.uint(8),  // rest-duration
          types.uint(2000),  // hydration-volume
          types.uint(30)  // mindfulness-time
        ], 
        user.address
      )
    ]);
    
    // Assertions here
    assertEquals(block.receipts.length, 1);
  }
});

// More test cases covering different contract functionalities