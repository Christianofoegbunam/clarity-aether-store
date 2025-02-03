import {
  Clarinet,
  Tx,
  Chain,
  Account,
  types
} from 'https://deno.land/x/clarinet@v1.0.0/index.ts';
import { assertEquals } from 'https://deno.land/std@0.90.0/testing/asserts.ts';

Clarinet.test({
  name: "Can create escrow",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const buyer = accounts.get("wallet_1")!;
    const seller = accounts.get("wallet_2")!;
    
    let block = chain.mineBlock([
      Tx.contractCall("escrow", "create-escrow",
        [types.uint(1000000), types.principal(seller.address), 
         types.principal(buyer.address), types.uint(0)],
        buyer.address
      )
    ]);
    
    assertEquals(block.receipts[0].result.expectOk(), "u0");
  },
});
