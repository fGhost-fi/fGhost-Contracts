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
        uint pid,
        address GhostFarmer,
        address Reward
    ) ERC20(name, symbol) ERC4626(asset) { 
     uint _pid = pid;
     address _ghostFarmer = GhostFarmer;
     address _reward = Reward;

        }
       
        
     function totalAssets() public view override returns (uint256) {
        return asset.balanceOf(address(this));
     }
    function beforeWithdraw (uint256 assets, uint256 shares) internal override{
       ERC20.SafeIncreaseAllowance(address(asset),address(MasterChef), uint (assets));
        IMasterChef.withdraw( _pid, address(this), uint (assets));
        ERC20.safeDecreaseAllowance(address(asset), address(MasterChef), 0);
         beforeWithdrawHookCalledCounter++;
    }
    function afterDeposit(uint256 assets, uint256 shares) internal override{
         ERC20.safeIncreaseAllowance(asset, address(MasterChef), assets);
        IMasterChef.deposit(uint(pid), uint (assets));
        ERC20.safeDecreaseAllowance(asset, address(MasterChef), 0);
        afterDepositHookCalledCounter++;
    }

    function Harvest(uint pid, address _reward, address _ghostFarmer) external{
     uint amount = IMasterChef.pendingBOO(uint(pid), address(this));
       {

        IMasterChef.Harvest(address(this),uint(pid), amount);
        ERC20.safeTransfer(address(_reward), address(this), address(_ghostFarmer), balanceOf(address(_reward)));
    }

    }
}
