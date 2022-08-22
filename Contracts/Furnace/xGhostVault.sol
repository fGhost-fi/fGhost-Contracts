// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import {ERC20} from "Contracts/Support/ERC20.sol";
import {ERC4626} from "Contracts/Support/ERC4626.sol";
import "Contracts/Support/IERC20Metadata.sol";

contract xGhostVault is ERC4626{

     constructor(
        IERC20Metadata asset,
        string memory name,
        string memory symbol
        ) ERC20(name, symbol) ERC4626(asset) { }
}