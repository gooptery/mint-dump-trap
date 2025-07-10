// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/MintDumpTrap.sol";

contract DeployMintDumpTrap is Script {
    function run() external {
        vm.startBroadcast();

        MintDumpTrap trap = new MintDumpTrap();

        console.log("? MintDumpTrap deployed at:", address(trap));

        vm.stopBroadcast();
    }
}
