// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/MintDumpTrap.sol";

contract MintDumpTrapTest is Test {
    MintDumpTrap trap;

    struct TransferEvent {
        address from;
        address to;
        uint256 amount;
    }

    function setUp() public {
        trap = new MintDumpTrap();
    }

    function testShouldRespondWhenMintAndDump() public view {
        TransferEvent[] memory logs = new TransferEvent[](2);

        logs[0] = TransferEvent({
            from: address(0),
            to: address(0xBADBEEF),
            amount: 1000 ether
        });

        logs[1] = TransferEvent({
            from: address(0xBADBEEF),
            to: address(0xCAFEBABE),
            amount: 1000 ether
        });

        bytes[] memory input = new bytes[](2);
        input[0] = abi.encode(block.timestamp, block.number);
        input[1] = abi.encode(logs);

        (bool shouldRespond, bytes memory reason) = trap.shouldRespond(input);
        assertTrue(shouldRespond, "Should respond to mint-and-dump");

        bytes32 expectedReasonHash = keccak256("TOKEN_DUMP_DETECTED");
        bytes memory expectedReason = abi.encode(
            expectedReasonHash,
            logs[0].to,
            logs[1].to,
            logs[0].amount
        );
        assertEq(reason, expectedReason, "Reason should match expected mint-dump details");
    }

    function testShouldNotRespondWhenOnlyMinted() public view {
        TransferEvent[] memory logs = new TransferEvent[](1);

        logs[0] = TransferEvent({
            from: address(0),
            to: address(0xBADBEEF),
            amount: 1000 ether
        });

        bytes[] memory input = new bytes[](2);
        input[0] = abi.encode(block.timestamp, block.number);
        input[1] = abi.encode(logs);

        (bool shouldRespond, ) = trap.shouldRespond(input);
        assertFalse(shouldRespond, "Should not respond without dump");
    }

    function testShouldNotRespondWithNoData() public view {
        bytes[] memory input = new bytes[](0); // Empty array

        (bool shouldRespond, bytes memory reason) = trap.shouldRespond(input);
        assertFalse(shouldRespond, "Should not respond with empty input");
        assertEq(string(reason), "No input data provided.", "Expected reason: No input data provided.");
    }

    function testShouldNotRespondWithTooManyLogs() public view {
        TransferEvent[] memory logs = new TransferEvent[](51); // More than 50 logs

        for (uint i = 0; i < 51; i++) {
            logs[i] = TransferEvent({
                from: address(uint160(i)),
                to: address(uint160(i + 1)),
                amount: 100
            });
        }

        bytes[] memory input = new bytes[](2); // Allocate space for 2 elements
        input[0] = abi.encode(block.timestamp, block.number); // Add timestamp and block number
        input[1] = abi.encode(logs); // Add the logs

        (bool shouldRespond, bytes memory reason) = trap.shouldRespond(input);
        assertFalse(shouldRespond, "Should not respond with too many logs");
        assertEq(string(reason), "Too many logs.", "Expected reason: Too many logs.");
    }

    function testShouldNotRespondWhenNoMint() public view {
        TransferEvent[] memory logs = new TransferEvent[](2);

        logs[0] = TransferEvent({
            from: address(0x1111),
            to: address(0x2222),
            amount: 100 ether
        });

        logs[1] = TransferEvent({
            from: address(0x2222),
            to: address(0x3333),
            amount: 100 ether
        });

        bytes[] memory input = new bytes[](2);
        input[0] = abi.encode(block.timestamp, block.number);
        input[1] = abi.encode(logs);

        (bool shouldRespond, bytes memory reason) = trap.shouldRespond(input);
        assertFalse(shouldRespond, "Should not respond if no mint detected");
        assertEq(string(reason), "No suspicious mint-dump detected.", "Reason should be 'No suspicious mint-dump detected.'");
    }

    function testShouldNotRespondWhenMintButNoMatchingDump() public view {
        TransferEvent[] memory logs = new TransferEvent[](2);

        logs[0] = TransferEvent({
            from: address(0),
            to: address(0xABCDEF),
            amount: 50 ether
        });

        logs[1] = TransferEvent({
            from: address(0x123456),
            to: address(0x789ABC),
            amount: 50 ether
        });

        bytes[] memory input = new bytes[](2);
        input[0] = abi.encode(block.timestamp, block.number);
        input[1] = abi.encode(logs);

        (bool shouldRespond, bytes memory reason) = trap.shouldRespond(input);
        assertFalse(shouldRespond, "Should not respond if mint but no matching dump");
        assertEq(string(reason), "No suspicious mint-dump detected.", "Reason should be 'No suspicious mint-dump detected.'");
    }
}
