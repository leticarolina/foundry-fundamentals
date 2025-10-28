//SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Test} from "forge-std/Test.sol";
import {DeployBox} from "../script/DeployBox.s.sol";
import {UpgradeBox} from "../script/UpgradeBox.s.sol";
import {BoxV1} from "../src/BoxV1.sol";
import {BoxV2} from "../src/BoxV2.sol";

contract DeployAndUpgradeTest is Test {
    DeployBox public deployBox;
    UpgradeBox public upgrader;
    address public owner = makeAddr("owner");
    address public proxy;

    function setUp() public {
        deployBox = new DeployBox();
        upgrader = new UpgradeBox();
        proxy = deployBox.run(); //pointing to boxv1 rn
    }

    function test_deployBox_startsWithBoxV1() public view {
        string memory initialVersion = BoxV1(proxy).getVersion();
        assertEq(initialVersion, "v1");
    }

    function test_upgrade_works() public {
        BoxV2 boxV2 = new BoxV2();
        upgrader.upgradeBox(proxy, address(boxV2));
        string memory expectedVersion = "v2";
        string memory version = BoxV2(proxy).getVersion();

        BoxV2(proxy).setNumber(17);
        assertEq(expectedVersion, version);
        assertEq(BoxV2(proxy).getNumber(), 17);
    }
}
