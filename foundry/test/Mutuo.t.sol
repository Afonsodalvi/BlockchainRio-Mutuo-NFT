// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";

import "../src/NFT.sol";

contract ContractTest is Test {
    address constant tester = address(0x69);
    address constant another = address(0x69);
    NFT nft;

    string constant name = "Omnes-NFT";
    string constant symbol = "OMNES";
    string constant baseURI = "https://ipfs.io/ipfs/CID.json";
    string constant hiddenMetadataUri = "https://ipfs.io/ipfs/CID.json";
    function setUp() public {
    nft = new NFT(name,symbol, baseURI, hiddenMetadataUri);
         
    }
    function testExample() public {
        nft.setPaused(false);
        // vm.startPrank(tester); se colocar o endereço do teste ele que executa sempre
        nft.mintAirdrp(tester);
    }
}
