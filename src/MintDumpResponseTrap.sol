// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IDrosera {
    function getRewardAddress(address trap) external view returns (address);
}

contract MintDumpResponseTrap {
    address public immutable drosera;

    event MintDumpDetected(
        address indexed trap,
        address indexed minter,
        address indexed dumper,
        uint256 amount,
        uint256 blockNumber,
        uint256 timestamp
    );

    constructor(address _drosera) {
        require(_drosera != address(0), "Invalid Drosera address");
        drosera = _drosera;
    }

    function logMintDump(address trap, bytes calldata reason) external {
        require(IDrosera(drosera).getRewardAddress(trap) != address(0), "Unregistered trap");

        (bytes32 code, address minter, address dumper, uint256 amount) =
            abi.decode(reason, (bytes32, address, address, uint256));

        require(code == keccak256("TOKEN_DUMP_DETECTED"), "Invalid reason code");

        emit MintDumpDetected(
            trap,
            minter,
            dumper,
            amount,
            block.number,
            block.timestamp
        );
    }
}
