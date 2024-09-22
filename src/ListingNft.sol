// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract ListingNft is ReentrancyGuard {
    error ListingNft__PriceMustBeGreaterThanZero();
    error ListingNft__NotNftOwner();
    error ListingNft__NftNotApproved();
    error ListingNft__NotEnoughEthSent();
    error ListingNft__TransferFailed();

    struct Listing {
        uint256 price;
        address seller;
    }

    mapping(address => mapping(uint256 => Listing)) public listings;

    event NFTListed(address indexed nftContract, uint256 indexed tokenId, uint256 price, address indexed seller);
    event NFTSold(address indexed nftContract, uint256 indexed tokenId, uint256 price, address indexed buyer);

    function listNft(address nftContract, uint256 tokenId, uint256 price) external nonReentrant {
        if (price <= 0) {
            revert ListingNft__PriceMustBeGreaterThanZero();
        }
        ERC721 nft = ERC721(nftContract);
        if (nft.ownerOf(tokenId) != msg.sender) {
            revert ListingNft__NotNftOwner();
        }
        if (nft.getApproved(tokenId) != address(this)) {
            revert ListingNft__NftNotApproved();
        }

        listings[nftContract][tokenId] = Listing({price: price, seller: msg.sender});
        emit NFTListed(nftContract, tokenId, price, msg.sender);
    }

    function buyNft(address nftContract, uint256 tokenId) external payable nonReentrant {
        Listing memory listing = listings[nftContract][tokenId];
        if (msg.value < listing.price) {
            revert ListingNft__NotEnoughEthSent();
        }

        delete listings[msg.sender][tokenId];

        (bool sent,) = listing.seller.call{value: listing.price}("");
        if (!sent) {
            revert ListingNft__TransferFailed();
        }

        ERC721 nft = ERC721(nftContract);
        nft.safeTransferFrom(listing.seller, msg.sender, tokenId);

        emit NFTSold(nftContract, tokenId, listing.price, msg.sender);
    }

    function cancelListing(address _nftContract, uint256 _tokenId) external nonReentrant {
        Listing memory listing = listings[_nftContract][_tokenId];
        if (listing.seller != msg.sender) {
            revert ListingNft__NotNftOwner();
        }

        delete listings[_nftContract][_tokenId];
    }

    function getListing(address _nftContract, uint256 _tokenId) external view returns (uint256 price, address seller) {
        Listing memory listing = listings[_nftContract][_tokenId];
        return (listing.price, listing.seller);
    }
}

contract FailingReceiver {
    receive() external payable {
        revert("Transfer failed");
    }

    fallback() external payable {
        revert("Transfer failed");
    }
}
