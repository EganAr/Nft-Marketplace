# NFT MARKETPLACE WITH ACCOUNT_ABSTRACTION

This project implements a smart contract for an NFT Marketplace with Account Abstraction features. Users can mint, list, and buy NFTs without directly paying gas fees, as these are handled by a Paymaster contract.

## KEY FEATURES

    1. NFT Minting: Users can create new NFTs.
    2. NFT Listing: NFT owners can list their NFTs for sale.
    3. NFT Buying: Users can purchase listed NFTs.
    4. Account Abstraction: Utilizes ERC-4337 to enhance user experience.
    5. Paymaster: Handles gas fees for user transactions.

## Technologies Used

    - Solidity
    - OpenZeppelin Contracts
    - ERC-4337 (Account Abstraction)
    - Foundry (for testing and deployment)

## How it Works

1. Minting NFTs:

   - Users call the mint function on the BasicNft contract.
   - The Paymaster handles the gas fee for this transaction.

2. Listing NFTs:

   - NFT owners call the listNft function on the ListingNft contract.
   - The Paymaster handles the gas fee for this transaction.

3. Buying NFTs:

   - Buyers call the buyNft function on the ListingNft contract.
   - The Paymaster handles the gas fee for this transaction.

4. Account Abstraction:

   - The MinimalAccount contract acts as a smart contract wallet for users.
   - It allows users to interact with the marketplace without holding ETH for gas.

5. Paymaster:

   - The Paymaster contract provides gas for user transactions.
   - It enables various business models, such as freemium or subscription-based services.

## Testing

Contracts have been test by me with 80%+ coverage.</br>
Use caution when deploying to testnet sepolia.
