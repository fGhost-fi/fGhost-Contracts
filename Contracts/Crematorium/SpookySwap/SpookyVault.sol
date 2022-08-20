// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import {ERC20} from "Contracts/Support/ERC20.sol";
import {ERC4626} from "Contracts/Support/ERC4626.sol";
import "Contracts/Support/IERC20Metadata.sol";
import "Contracts/Support/SafeERC20.sol";
import "Contracts/Support/Math/SafeMath.sol";

interface IMasterChef{
    
   function deposit(uint pid, uint amount)external;
   function withdraw(uint pid, uint amount) external;
   function harvest(address user, uint pid, uint amount) external;
   function pendingBOO(uint _pid, address _user) external view returns(uint pending);
}

contract SpookyVault is ERC4626{
   using SafeERC20 for IERC20;
   using SafeMath for uint;
    
address constant MasterChef = 0x9C9C920E51778c4ABF727b8Bb223e78132F00aA4;
IMasterChef mc = IMasterChef(MasterChef);

    uint256 public beforeWithdrawHookCalledCounter = 0;
    uint256 public afterDepositHookCalledCounter = 0;
    
      uint public _pid;
      address public _ghostFarmer;
      IERC20 public _reward;
      IERC20 public  _asset;

    constructor(
        IERC20Metadata asset,
        string memory name,
        string memory symbol,
        uint pid,
        address GhostFarmer,
        IERC20 Reward      
    ) ERC20(name, symbol) ERC4626(asset) { 
      pid = _pid;
      GhostFarmer = _ghostFarmer;
      Reward = _reward;
      _asset = asset;
        }

    function beforeWithdraw (uint256 assets,uint256) internal override{
       SafeERC20.safeApprove(_asset, MasterChef, uint (assets));
        mc.withdraw( _pid, uint (assets));
        SafeERC20.safeDecreaseAllowance(_asset, MasterChef, 0);
         beforeWithdrawHookCalledCounter++;
    }
    function afterDeposit(uint256 assets, uint256) internal override{
         SafeERC20.safeApprove(_asset, MasterChef, assets);
        mc.deposit(uint(_pid), uint (assets));
        SafeERC20.safeDecreaseAllowance(_asset, MasterChef, 0);
        afterDepositHookCalledCounter++;
    }

    function harvest() external{
      uint amount = mc.pendingBOO(uint(_pid), address(this));

       mc.harvest(address(this),uint(_pid), amount);
       SafeERC20.safeTransfer(_reward, address(_ghostFarmer), balanceOf(address(_reward)));
    }
         
      }
    




