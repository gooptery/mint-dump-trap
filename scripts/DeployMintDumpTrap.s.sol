// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/MintDumpTrap.sol";

contract DeployMintDumpTrap is Script {
    function run() external {
        // Replace this with the target token address
        address tokenAddress = 0x1234567890abcdef1234567890abcdef12345678;

        vm.startBroadcast();
        MintDumpTrap trap = new MintDumpTrap(tokenAddress);
        vm.stopBroadcast();

        console2.log("✅ MintDumpTrap deployed at:", address(trap));
    }
}