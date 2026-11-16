// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import {DoubleEntryPoint, Forta} from "src/levels/DoubleEntryPoint.sol";
import {DoubleEntryPointFactory} from "src/levels/DoubleEntryPointFactory.sol";

// Detection bot: naikkan alert bila ada delegateTransfer yang menguras
// vault (origSender == vault). Forta.notify() memanggilnya di dalam
// fortaNotify; alert -> delegateTransfer revert -> sweepToken gagal.
contract DetectionBot {
    address public vault;
    Forta public forta;

    constructor(address _vault, address _forta) {
        vault = _vault;
        forta = Forta(_forta);
    }

    function handleTransaction(address user, bytes calldata msgData) external {
        // msgData = delegateTransfer(to, value, origSender)
        (, , address origSender) = abi.decode(msgData[4:], (address, uint256, address));
        if (origSender == vault) {
            forta.raiseAlert(user);
        }
    }
}

contract DoubleEntryPointSolve is Test {
    DoubleEntryPointFactory factory;
    DoubleEntryPoint instance;
    address player = address(0xBEEF);

    function setUp() public {
        factory = new DoubleEntryPointFactory();
        instance = DoubleEntryPoint(factory.createInstance(player));
    }

    function testInit() public {
        assertFalse(factory.validateInstance(payable(address(instance)), player));
    }

    function testSolve() public {
        // PENTING: baca alamat Forta DULU — vm.prank hanya berlaku untuk
        // SATU panggilan berikutnya, dan instance.forta() akan menghabiskannya.
        Forta forta = instance.forta();
        DetectionBot bot = new DetectionBot(instance.cryptoVault(), address(forta));
        vm.prank(player);
        forta.setDetectionBot(address(bot));
        assertTrue(factory.validateInstance(payable(address(instance)), player));
    }
}
