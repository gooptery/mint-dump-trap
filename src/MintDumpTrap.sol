// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ITrap} from "drosera-contracts/interfaces/ITrap.sol";

interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);
    function balanceOf(address account) external view returns (uint256);
}

contract MintDumpTrap is ITrap {
    address public tokenContract;

    struct TransferEvent {
        address from;
        address to;
        uint256 amount;
    }

    constructor() {
        address hardcodedToken = 0x499b095Ed02f76E56444c242EC43A05F9c2A3ac8; //TOKEN ADDRESS
        require(hardcodedToken != address(0), "Invalid token contract address");
        tokenContract = hardcodedToken;
    }

    function collect() external view override returns (bytes memory) {
        return abi.encode(block.timestamp, block.number);
    }

    function shouldRespond(bytes[] calldata _data) external pure override returns (bool should, bytes memory reason) {
    if (_data.length == 0) {
        return (false, "No input data provided.");
    }
    if (_data.length < 2) {
        return (false, "Missing Transfer events data from off-chain client");
    }

    TransferEvent[] memory logs = abi.decode(_data[1], (TransferEvent[]));
    if (logs.length > 50) {
        return (false, "Too many logs.");
    }

    for (uint i = 0; i < logs.length; i++) {
        TransferEvent memory mintLog = logs[i];
        if (mintLog.from == address(0)) {
            for (uint j = i + 1; j < logs.length; j++) {
                TransferEvent memory dumpLog = logs[j];

                if (
                    dumpLog.from == mintLog.to &&
                    dumpLog.amount == mintLog.amount &&
                    dumpLog.to != address(0)
                ) {
                    should = true;
                    reason = abi.encode(
                        keccak256("TOKEN_DUMP_DETECTED"),
                        mintLog.to,
                        dumpLog.to,
                        mintLog.amount
                    );
                    return (should, reason);
                  }
              }
          }
      }

      should = false;
      reason = "No suspicious mint-dump detected.";
    }
}
