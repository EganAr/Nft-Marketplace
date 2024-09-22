// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {IPaymaster} from "lib/account-abstraction/contracts/interfaces/IPaymaster.sol";
import {PackedUserOperation} from "lib/account-abstraction/contracts/interfaces/PackedUserOperation.sol";
import {MessageHashUtils} from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {SIG_VALIDATION_FAILED, SIG_VALIDATION_SUCCESS} from "lib/account-abstraction/contracts/core/Helpers.sol";
import {IEntryPoint} from "lib/account-abstraction/contracts/interfaces/IEntryPoint.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract Paymaster is IPaymaster, Ownable {
    error Paymaster__requireFromEntryPoint();
    error Paymaster__InsufficientBalance();
    error Paymaster__CallFailed();

    IEntryPoint private immutable i_entryPoint;
    mapping(address => bool) public whitelist;
    mapping(address => uint256) public userNonce;

    event Deposited(address indexed account, uint256 amount);
    event Withdrawn(address indexed account, uint256 amount);

    constructor(address _entryPoint) Ownable(msg.sender) {
        i_entryPoint = IEntryPoint(_entryPoint);
    }

    modifier requireFromEntryPoint() {
        if (msg.sender != address(i_entryPoint)) {
            revert Paymaster__requireFromEntryPoint();
        }
        _;
    }

    function deposit() external payable {
        IEntryPoint(i_entryPoint).depositTo{value: msg.value}(address(this));
        emit Deposited(msg.sender, msg.value);
    }

    function getBalance() public view returns (uint256) {
        return IEntryPoint(i_entryPoint).balanceOf(address(this));
    }

    function withdraw(uint256 amount) external onlyOwner {
        if (amount >= address(this).balance) {
            revert Paymaster__InsufficientBalance();
        }
        (bool success,) = owner().call{value: amount}("");
        if (!success) {
            revert Paymaster__CallFailed();
        }
        emit Withdrawn(msg.sender, amount);
    }

    function addToWhitelist(address user) external onlyOwner {
        whitelist[user] = true;
    }

    function removeFromWhitelist(address user) external onlyOwner {
        whitelist[user] = false;
    }

    function validatePaymasterUserOp(PackedUserOperation calldata userOp, bytes32, uint256 maxCost)
        external
        view
        requireFromEntryPoint
        returns (bytes memory context, uint256 validationData)
    {
        if (address(this).balance <= maxCost) {
            revert Paymaster__InsufficientBalance();
        }

        validationData = SIG_VALIDATION_SUCCESS;
        context = abi.encode(userOp.sender, maxCost);
        return (context, validationData);
    }

    function postOp(PostOpMode mode, bytes calldata context, uint256 actualGasCost, uint256 actualUserOpFeePerGas)
        external
        requireFromEntryPoint
    {}

    function getEntryPoint() external view returns (address) {
        return address(i_entryPoint);
    }
}
