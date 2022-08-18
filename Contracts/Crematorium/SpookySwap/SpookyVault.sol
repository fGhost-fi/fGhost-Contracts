// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import {ERC20} from "contracts/Support/ERC20.sol";
import {ERC4626} from "contracts/Support/ERC4626.sol";
import "contracts/Support/IERC20Metadata.sol";

interface IMasterChef{
    
   function deposit(uint pid, uint amount)external;
   function withdraw(uint pid, uint amount, address to) external;
   function Harvest(address user, uint pid, uint amount) external;
   function pendingBOO(uint _pid, address _user) external;
}



contract SpookyVault is ERC4626{
    
address constant MasterChef = 0x9C9C920E51778c4ABF727b8Bb223e78132F00aA4;

    uint256 public beforeWithdrawHookCalledCounter = 0;
    uint256 public afterDepositHookCalledCounter = 0;

    constructor(
        IERC20Metadata asset,
        string memory name,
        string memory symbol,
        uint memory pid,
        address memory GhostFarmer,
        address memory Reward
    ) ERC20(name, symbol) ERC4626(asset) { 
     
        }

       
     function totalAssets() public view override returns (uint256) {
        return asset.balanceOf(address(this));
     }
    function beforeWithdraw (uint256 assets, uint256 shares, uint amount) internal override{
        SafeIncreaseAllowance(address(asset),address(MasterChef), uint (amount));
        IMasterChef.Withdraw(address(this),uint(_pid), uint256 (assets), address(this));
        SafeDecreaseAllowance(address(asset), address(MasterChef), 0);
         beforeWithdrawHookCalledCounter++;
    }
    function afterDeposit(uint256, uint256) internal override{
         SafeIncreaseAllowance(asset, address(MasterChef), amount);
        IMasterChef.Deposit(address(this),uint(_pid), amount, address(this));
        SafeDecreaseAllowance(asset, address(MasterChef), 0);
        afterDepositHookCalledCounter++;
    }

    function Harvest() external{
     uint amount = IMasterChef.PendingBOO(uint(_pid), address(this));
       {

        IMasterChef.Harvest(address(this), _pid, amount);
        SafeERC20.safeTransfer(Reward, address(this), GhostFarmer, balanceOf(address(Reward)));
    }

    }
}

