// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {BasicNft} from "src/BasicNft.sol";
import {ListingNft} from "src/ListingNft.sol";
import {Paymaster} from "src/Paymaster.sol";
import {MinimalAccount} from "src/MinimalAccount.sol";
import {Test, console, Vm} from "forge-std/Test.sol";
import {DeployAA} from "script/DeployAA.s.sol";
import {HelperConfig} from "script/HelperConfig.s.sol";
import {IEntryPoint} from "lib/account-abstraction/contracts/interfaces/IEntryPoint.sol";
import {SendPackedUserOp} from "script/SendPackedUserOp.s.sol";
import {PackedUserOperation} from "lib/account-abstraction/contracts/interfaces/PackedUserOperation.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {MessageHashUtils} from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract AccountAbstractionTest is Test {
    using MessageHashUtils for bytes32;

    BasicNft basicNft;
    ListingNft listingNft;
    Paymaster paymaster;
    MinimalAccount account;
    HelperConfig helperConfig;
    DeployAA deployer;
    SendPackedUserOp sendPackedUserOp;

    string public constant PUG = "ipfs.io/ipfs/QmUPjADFGEKmfohdTaNcWhp7VGk26h5jXDA7v3VtTnTLcW?filename=st-bernard.png";
    address public RANDOM_USER = makeAddr("USER");

    function setUp() public {
        deployer = new DeployAA();
        (basicNft, listingNft, helperConfig, account, paymaster) = deployer.deployAA();
        sendPackedUserOp = new SendPackedUserOp();

        vm.deal(address(account), 100 ether);
        vm.deal(RANDOM_USER, 100 ether);
        vm.deal(address(paymaster), 100 ether);
    }

    function testEntryPointCanExecuteCommands() public {
        address dest = address(basicNft);
        uint256 value = 0;
        bytes memory functionData = abi.encodeWithSelector(BasicNft.mintNft.selector, PUG);

        vm.prank(account.getEntryPoint());
        account.execute(dest, value, functionData);

        assertEq(basicNft.balanceOf(address(account)), 1);
        assertEq(keccak256(abi.encodePacked(PUG)), keccak256(abi.encodePacked(basicNft.tokenURI(0))));
    }

    function testRevertExecuteCommands() public {
        address dest = address(basicNft);
        uint256 value = 0;
        bytes memory functionData = abi.encodeWithSelector(BasicNft.mintNft.selector, PUG);

        vm.expectRevert(MinimalAccount.MinimalAccount__NotFromEntryPointOrOwner.selector);
        vm.prank(RANDOM_USER);
        account.execute(dest, value, functionData);
    }

    function testRecoverSignedOp() public {
        address dest = address(basicNft);
        uint256 value = 0;
        bytes memory functionData = abi.encodeWithSelector(BasicNft.mintNft.selector, PUG);
        bytes memory executeCallData =
            abi.encodeWithSelector(MinimalAccount.execute.selector, dest, value, functionData);

        HelperConfig.NetworkConfig memory config = helperConfig.getConfig();
        PackedUserOperation memory packedUserOp =
            sendPackedUserOp.generateSignedUserOperation(executeCallData, config, address(account));
        bytes32 userOperationHash = IEntryPoint(config.entryPoint).getUserOpHash(packedUserOp);
        address actualSigner = ECDSA.recover(userOperationHash.toEthSignedMessageHash(), packedUserOp.signature);

        assertEq(actualSigner, account.owner());
    }

    function testValidationUserOp() public {
        address dest = address(basicNft);
        uint256 value = 0;
        bytes memory functionData = abi.encodeWithSelector(BasicNft.mintNft.selector, PUG);
        bytes memory executeCallData =
            abi.encodeWithSelector(MinimalAccount.execute.selector, dest, value, functionData);

        HelperConfig.NetworkConfig memory config = helperConfig.getConfig();
        PackedUserOperation memory packedUserOp =
            sendPackedUserOp.generateSignedUserOperation(executeCallData, config, address(account));
        bytes32 userOperationHash = IEntryPoint(config.entryPoint).getUserOpHash(packedUserOp);

        vm.prank(config.entryPoint);
        uint256 validationData = account.validateUserOp(packedUserOp, userOperationHash, 0);

        assertEq(validationData, 0);
    }

    function testRevertValidationUserOpNotFromEntryPoint() public {
        address dest = address(basicNft);
        uint256 value = 0;
        bytes memory functionData = abi.encodeWithSelector(BasicNft.mintNft.selector, PUG);
        bytes memory executeCallData =
            abi.encodeWithSelector(MinimalAccount.execute.selector, dest, value, functionData);

        HelperConfig.NetworkConfig memory config = helperConfig.getConfig();
        PackedUserOperation memory packedUserOp =
            sendPackedUserOp.generateSignedUserOperation(executeCallData, config, address(account));
        bytes32 userOperationHash = IEntryPoint(config.entryPoint).getUserOpHash(packedUserOp);

        vm.expectRevert(MinimalAccount.MinimalAccount__NotFromEntryPoint.selector);
        vm.prank(RANDOM_USER);
        account.validateUserOp(packedUserOp, userOperationHash, 0);
    }

    function testRevertValidationPaymasterInsufficientBalance() public {
        uint128 verificationGasLimit = 16777216;
        uint128 callGasLimit = verificationGasLimit;
        uint128 maxPriorityFeePerGas = 256;
        uint128 maxFeePerGas = maxPriorityFeePerGas;
        PackedUserOperation memory userOp = PackedUserOperation({
            // Isi dengan data dummy yang sesuai
            sender: address(0x123),
            nonce: 1,
            initCode: bytes(""),
            callData: bytes(""),
            accountGasLimits: bytes32(uint256(verificationGasLimit) << 128 | callGasLimit),
            preVerificationGas: 1000000,
            gasFees: bytes32(uint256(maxPriorityFeePerGas) << 128 | maxFeePerGas),
            paymasterAndData: bytes(""),
            signature: bytes("")
        });
        bytes32 userOpHash = bytes32(0); // Dummy hash
        uint256 maxCost = 101 ether;
        HelperConfig.NetworkConfig memory config = helperConfig.getConfig();

        vm.startPrank(config.entryPoint);
        vm.expectRevert(Paymaster.Paymaster__InsufficientBalance.selector);
        paymaster.validatePaymasterUserOp(userOp, userOpHash, maxCost);
        vm.stopPrank();
    }

    function testEntryPointCanExecuteCommandsWithRandomUser() public {
        address dest = address(basicNft);
        uint256 value = 0;
        bytes memory functionData = abi.encodeWithSelector(BasicNft.mintNft.selector, PUG);
        bytes memory executeCallData =
            abi.encodeWithSelector(MinimalAccount.execute.selector, dest, value, functionData);

        HelperConfig.NetworkConfig memory config = helperConfig.getConfig();
        paymaster.deposit{value: 100 ether}();

        PackedUserOperation memory packedUserOp =
            sendPackedUserOp.generateSignedUserOperation(executeCallData, config, address(account));
        PackedUserOperation[] memory ops = new PackedUserOperation[](1);
        ops[0] = packedUserOp;

        vm.prank(RANDOM_USER);
        IEntryPoint(config.entryPoint).handleOps(ops, payable(RANDOM_USER));

        assertEq(basicNft.balanceOf(address(account)), 1);
        assertEq(keccak256(abi.encodePacked(PUG)), keccak256(abi.encodePacked(basicNft.tokenURI(0))));
    }

    function testBatchMintAndListingWithAccountAbstraction() public {
        address basicNftAddress = address(basicNft);
        address listingNftAddress = address(listingNft);
        uint256 tokenId = 0; // Assuming this is the first NFT to be minted
        uint256 listingPrice = 1e18; // 1 ETH

        address[] memory destinations = new address[](3);
        uint256[] memory values = new uint256[](3);
        bytes[] memory funcDatas = new bytes[](3);

        destinations[0] = basicNftAddress;
        values[0] = 0;
        funcDatas[0] = abi.encodeWithSelector(BasicNft.mintNft.selector, PUG);

        // 2. Approve ListingNft contract
        destinations[1] = basicNftAddress;
        values[1] = 0;
        funcDatas[1] = abi.encodeWithSelector(IERC721.approve.selector, listingNftAddress, tokenId);

        // 3. List NFT
        destinations[2] = listingNftAddress;
        values[2] = 0;
        funcDatas[2] = abi.encodeWithSelector(ListingNft.listNft.selector, basicNftAddress, tokenId, listingPrice);

        HelperConfig.NetworkConfig memory config = helperConfig.getConfig();
        paymaster.deposit{value: 100 ether}();

        bytes memory executeCallData =
            abi.encodeWithSelector(MinimalAccount.executeBatch.selector, destinations, values, funcDatas);
        PackedUserOperation memory packedUserOp =
            sendPackedUserOp.generateSignedUserOperation(executeCallData, config, address(account));
        PackedUserOperation[] memory ops = new PackedUserOperation[](1);
        ops[0] = packedUserOp;

        vm.prank(RANDOM_USER);
        IEntryPoint(config.entryPoint).handleOps(ops, payable(RANDOM_USER));

        assertEq(basicNft.balanceOf(address(account)), 1, "NFT should be minted");
        assertEq(basicNft.ownerOf(tokenId), address(account), "Account should own the NFT");
        assertEq(basicNft.getApproved(tokenId), listingNftAddress, "ListingNft should be approved");
        (uint256 price, address seller) = listingNft.getListing(basicNftAddress, tokenId);
        assertEq(price, listingPrice, "Listing price should match");
        assertEq(seller, address(account), "Listing seller should be account");
    }

    function testDepositPaymaster() public {
        vm.recordLogs();
        vm.prank(RANDOM_USER);
        paymaster.deposit{value: 100 ether}();

        Vm.Log[] memory entries = vm.getRecordedLogs();

        assertEq(entries.length, 2);
        assertEq(entries[1].topics[0], keccak256("Deposited(address,uint256)"));
        assertEq(paymaster.getBalance(), 100 ether);
    }

    function testWithdrawFromOwner() public {
        vm.recordLogs();
        vm.prank(paymaster.owner());
        paymaster.withdraw(10 ether);

        Vm.Log[] memory entries = vm.getRecordedLogs();

        assertEq(entries.length, 1);
        assertEq(entries[0].topics[0], keccak256("Withdrawn(address,uint256)"));
        assertEq(address(paymaster).balance, 90 ether);
    }

    function testRevertWithdrawTooMuch() public {
        vm.prank(paymaster.owner());
        vm.expectRevert();
        paymaster.withdraw(200 ether);
    }

    function testAddToWhiteListAndDelete() public {
        vm.startPrank(paymaster.owner());
        paymaster.addToWhitelist(RANDOM_USER);
        paymaster.removeFromWhitelist(RANDOM_USER);
        vm.stopPrank();
    }
}
