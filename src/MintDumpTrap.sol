// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ITrap} from "drosera-contracts/interfaces/ITrap.sol";

interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);
}

contract MintDumpTrap is ITrap {
    address public tokenContract;

    struct TransferEvent {
        address from;
        address to;
        uint256 amount;
    }

    constructor(address _tokenContract) {
        tokenContract = _tokenContract;
    }

    function collect() external pure override returns (bytes memory) {
        // Dummy/mock data for demonstration
        TransferEvent[] memory logs = new TransferEvent[](2);

        logs[0] = TransferEvent({
          from: address(0),
          to: address(0xDEAD),
          amount: 100_000 * 1e18
        });

        logs[1] = TransferEvent({
          from: address(0xDEAD),
          to: address(0xC0FFEE),
          amount: 100_000 * 1e18
        });

        return abi.encode(logs);
    }


    function shouldRespond(bytes[] calldata _data) external pure override returns (bool should, bytes memory reason) {
        require(_data.length > 0, "No input data provided.");

        TransferEvent[] memory logs = abi.decode(_data[0], (TransferEvent[]));
        require(logs.length <= 50, "Too many logs.");

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
