// Stacks.js Integration Helper Functions
// This file provides helper functions to interact with smart contracts

// Note: For tablet deployment, you can use this as reference
// Actual integration will be done through Hiro Platform or Stacks Explorer

export const CONTRACT_ADDRESS = 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM';

export const CONTRACTS = {
  CREDENTIAL: 'disability-credential',
    MARKETPLACE: 'marketplace-escrow',
      EMERGENCY: 'emergency-fund',
        BOUNTY: 'bounty',
        };

        // Helper to convert STX amounts
        export function microStxToStx(microStx: number): number {
          return microStx / 1000000;
          }

          export function stxToMicroStx(stx: number): number {
            return Math.floor(stx * 1000000);
            }

            export function formatStx(microStx: number): string {
              return `${microStxToStx(microStx).toFixed(2)} STX`;
              }

              // For full integration, install @stacks/connect and @stacks/transactions
              // Then uncomment and use the functions below:

              /*
              import { openContractCall } from '@stacks/connect';
              import { uintCV, principalCV, stringAsciiCV } from '@stacks/transactions';

              export async function createListing(price: number, title: string, category: string) {
                const functionArgs = [
                    uintCV(price),
                        stringAsciiCV(title),
                            stringAsciiCV(category),
                              ];

                                return openContractCall({
                                    contractAddress: CONTRACT_ADDRESS,
                                        contractName: CONTRACTS.MARKETPLACE,
                                            functionName: 'create-listing',
                                                functionArgs,
                                                  });
                                                  }
                                                  */

                                                  export default {
                                                    CONTRACT_ADDRESS,
                                                      CONTRACTS,
                                                        microStxToStx,
                                                          stxToMicroStx,
                                                            formatStx,
                                                            };