// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/MintDumpResponseTrap.sol";

contract DeployMintDumpResponseTrap is Script {
    function run() external {
        address droseraaddress = vm.envAddress("DROSERA_ADDRESS");

        vm.startBroadcast();
        MintDumpResponseTrap response = new MintDumpResponseTrap(droseraaddress);
        vm.stopBroadcast();

        console2.log("? Deployed MintDumpResponseTrap to:", address(response));
    }
}
