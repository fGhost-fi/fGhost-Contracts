// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import {ERC20} from "Contracts/Support/ERC20.sol";
import "Contracts/Support/ERC4626.sol";

interface IMasterchefv2{
    
   function Deposit(address indexed user, uint indexed pid, uint amount, address indexed to);
   function Withdraw(address indexed user, uint indexed pid, uint amount, address indexed to);
   function Harvest(address indexed user, uint indexed pid, uint amount );
   function PendingBOO( uint indexed pid, address indexed user);
}

Contract SpookyVault is ERC4626{
IMasterchefv2 MasterChef = IMasterChefv2(0x9C9C920E51778c4ABF727b8Bb223e78132F00aA4);

    uint256 public beforeWithdrawHookCalledCounter = 0;
    uint256 public afterDepositHookCalledCounter = 0;

    constructor(
        IERC20Metadata asset,
        string memory name,
        string memory symbol
        uint memory pid
        address memory GhostFarmer
        address memory Reward
    ) ERC20(name, symbol) ERC4626(asset) {};

        pid =_pid;
        Reward = _Reward;
        GhostFarmer = _GhostFarmer;
     function totalAssets() public view override returns (uint256) {
        return asset.balanceOf(address(this));
     }
    function beforeWithdraw (uint256 assets, uint256 shares) internal override{
        SafeIncreaseAllowance(_asset, MasterChef, amount);
        MasterChef.Withdraw(address(this), _pid, uint amount, address(this));
        SafeDecreaseAllowance(_asset, MasterChef, 0);
         beforeWithdrawHookCalledCounter++;
    }
    function afterDeposit(uint256, uint256) internal override{
         SafeIncreaseAllowance(_asset, MasterChef, amount);
        MasterChef.Deposit(address(this), _pid, uint amount, address(this));
        SafeDecreaseAllowance(_asset, MasterChef, 0);
        afterDepositHookCalledCounter++;
    }

    function Harvest(){
       MasterChef.PendingBOO(_pid, address(this)) returns (uint){
        return _amount;
       };

        MasterChef.Harvest(address(this), _pid, _amount);
        SafeERC20.safeTransfer(_Reward, address(this), _GhostFarmer, balanceOf(address(_Reward)));
    }


}
