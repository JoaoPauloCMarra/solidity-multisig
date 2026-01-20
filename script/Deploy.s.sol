// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/MultiSigWallet.sol";

contract DeployMultiSig is Script {
    function run() external returns (MultiSigWallet) {
        address[] memory owners = new address[](3);
        owners[0] = vm.envAddress("OWNER_1");
        owners[1] = vm.envAddress("OWNER_2");
        owners[2] = vm.envAddress("OWNER_3");

        uint256 threshold = vm.envUint("THRESHOLD");

        vm.startBroadcast();
        MultiSigWallet wallet = new MultiSigWallet(owners, threshold);
        vm.stopBroadcast();

        return wallet;
    }
}
