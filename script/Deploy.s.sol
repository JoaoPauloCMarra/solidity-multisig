// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";
import {MultiSigWallet} from "../src/MultiSigWallet.sol";

contract DeployMultiSig is Script {
    // anvil default accounts (for local dev)
    address constant ANVIL_0 = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;
    address constant ANVIL_1 = 0x70997970C51812dc3A010C7d01b50e0d17dc79C8;
    address constant ANVIL_2 = 0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC;

    function run() external returns (MultiSigWallet) {
        address[] memory owners = new address[](3);
        owners[0] = vm.envOr("OWNER_1", ANVIL_0);
        owners[1] = vm.envOr("OWNER_2", ANVIL_1);
        owners[2] = vm.envOr("OWNER_3", ANVIL_2);

        uint256 threshold = vm.envOr("THRESHOLD", uint256(2));

        vm.startBroadcast();
        MultiSigWallet wallet = new MultiSigWallet(owners, threshold);
        vm.stopBroadcast();

        return wallet;
    }
}
