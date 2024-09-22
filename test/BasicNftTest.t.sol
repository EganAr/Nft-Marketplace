// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {BasicNft} from "src/BasicNft.sol";
import {ListingNft, FailingReceiver} from "src/ListingNft.sol";
import {DeployBasicNft} from "script/DeployBasicNft.s.sol";
import {Test, console} from "forge-std/Test.sol";

contract BasicNftTest is Test {
    BasicNft basicNft;
    DeployBasicNft deployer;
    ListingNft listingNft;

    address public USER = makeAddr("USER");
    address public BUYER = makeAddr("BUYER");
    string public constant PUG = "ipfs.io/ipfs/QmUPjADFGEKmfohdTaNcWhp7VGk26h5jXDA7v3VtTnTLcW?filename=st-bernard.png";
    uint256 public constant USER_BALANCE = 100 ether;

    function setUp() public {
        deployer = new DeployBasicNft();
        (basicNft, listingNft) = deployer.run();

        vm.deal(USER, USER_BALANCE);
        vm.deal(BUYER, USER_BALANCE);
    }

    function testNameAndSymbolIsCorrect() public view {
        string memory expectedName = "Sneks";
        string memory actualName = basicNft.name();

        string memory expectedSymbol = "SNK";
        string memory actualSymbol = basicNft.symbol();

        assertEq(keccak256(abi.encodePacked(expectedName)), keccak256(abi.encodePacked(actualName)));
        assertEq(keccak256(abi.encodePacked(expectedSymbol)), keccak256(abi.encodePacked(actualSymbol)));
    }

    function testUserCanMint() public {
        vm.prank(USER);
        basicNft.mintNft(PUG);

        assertEq(basicNft.balanceOf(USER), 1);
        assertEq(keccak256(abi.encodePacked(PUG)), keccak256(abi.encodePacked(basicNft.tokenURI(0))));
    }

    ///////////////////////////////////////
    //////// MINT & LISTING NFT ///////////
    ///////////////////////////////////////
    function testMintAndListingNft() public {
        vm.startPrank(USER);
        basicNft.mintNft(PUG);
        basicNft.approve(address(listingNft), 0);
        assertEq(basicNft.getApproved(0), address(listingNft), "NFT is not approved!");

        listingNft.listNft(address(basicNft), 0, 1e18);
        vm.stopPrank();

        (uint256 price, address seller) = listingNft.getListing(address(basicNft), 0);
        assertEq(price, 1e18);
        assertEq(seller, USER);
    }

    function testRevertListingPriceMustGreaterThanZero() public {
        vm.startPrank(USER);
        basicNft.mintNft(PUG);
        basicNft.approve(address(listingNft), 0);

        vm.expectRevert(ListingNft.ListingNft__PriceMustBeGreaterThanZero.selector);

        listingNft.listNft(address(basicNft), 0, 0);
        vm.stopPrank();
    }

    function testRevertListingNftNotOwner() public {
        vm.startPrank(USER);
        basicNft.mintNft(PUG);
        basicNft.approve(address(listingNft), 0);
        vm.stopPrank();

        vm.expectRevert(ListingNft.ListingNft__NotNftOwner.selector);
        vm.prank(address(this));
        listingNft.listNft(address(basicNft), 0, 1e18);
    }

    function testReverTokenNotApprovedWhenListingNft() public {
        vm.startPrank(USER);
        basicNft.mintNft(PUG);
        vm.expectRevert(ListingNft.ListingNft__NftNotApproved.selector);
        listingNft.listNft(address(basicNft), 0, 1e18);
        vm.stopPrank();
    }

    ///////////////////////////////////////
    //////// BUY NFT //////////////////////
    ///////////////////////////////////////
    modifier mintAndListing() {
        vm.startPrank(USER);
        basicNft.mintNft(PUG);
        basicNft.approve(address(listingNft), 0);
        listingNft.listNft(address(basicNft), 0, 1e18);
        vm.stopPrank();
        _;
    }

    function testBuyNft() public mintAndListing {
        vm.prank(BUYER);
        listingNft.buyNft{value: 1e18}(address(basicNft), 0);
        assertEq(basicNft.balanceOf(BUYER), 1);
        assertEq(basicNft.balanceOf(USER), 0);
    }

    function testRevertBuyNftWhenNotEnoughEthSent() public mintAndListing {
        vm.expectRevert(ListingNft.ListingNft__NotEnoughEthSent.selector);
        vm.prank(BUYER);
        listingNft.buyNft{value: 0}(address(basicNft), 0);
    }

    ///////////////////////////////////////
    //////// CANCEL LISTING ///////////////
    ///////////////////////////////////////
    function testCancelListing() public mintAndListing {
        vm.prank(USER);
        listingNft.cancelListing(address(basicNft), 0);
    }

    function testRevertCancelListingNotOwner() public mintAndListing {
        vm.expectRevert(ListingNft.ListingNft__NotNftOwner.selector);
        vm.prank(BUYER);
        listingNft.cancelListing(address(basicNft), 0);
    }

    ///////////////////////////////////////
    //////// GETTER FUNCTION //////////////
    ///////////////////////////////////////
    function testGetTokenCounter() public mintAndListing {
        uint256 tokenCounter = basicNft.getTokenCounter();
        assertEq(tokenCounter, 1);
    }

    
}
