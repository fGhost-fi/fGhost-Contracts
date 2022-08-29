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
   function userInfo(uint256 pid, address owner) external returns (uint256);
}

contract SpookyVault is ERC4626{
   using SafeERC20 for IERC20;
   using SafeMath for uint;
    
address constant MasterChef = 0x18b4f774fdC7BF685daeeF66c2990b1dDd9ea6aD;
IMasterChef mc = IMasterChef(MasterChef);

    uint256 public beforeWithdrawHookCalledCounter = 0;
    uint256 public afterDepositHookCalledCounter = 0;
    
      uint256 public _pid;
      address public _ghostFarmer;
      IERC20 public  _reward;
      IERC20 public  _asset;
      uint256 public _totalAssets;
    constructor(
        IERC20Metadata asset,
        string memory name,
        string memory symbol,
        uint  pid,
        address GhostFarmer,
        IERC20 Reward
    ) ERC20(name, symbol) ERC4626(asset) { 
      _pid = pid;
      _ghostFarmer = GhostFarmer;
      _reward = Reward;
      _asset = asset;
        }

    function beforeWithdraw (uint256 assets) internal override{
         IERC20(_asset).safeApprove(MasterChef, assets);
          mc.withdraw( _pid, assets);
            IERC20(_asset).safeDecreaseAllowance(MasterChef, 0);
          _totalAssets = mc.userInfo(_pid, address(this));
         beforeWithdrawHookCalledCounter++;
    }

    function afterDeposit(uint256 assets) internal override{
         IERC20(_asset).safeApprove(MasterChef, assets);
        mc.deposit(uint(_pid), assets);
        IERC20(_asset).safeDecreaseAllowance(MasterChef, 0);
        _totalAssets = mc.userInfo(_pid, address(this));
        afterDepositHookCalledCounter++;
    }

    function harvest() external{

        IERC20(_asset).safeApprove(MasterChef, 20000);
        mc.withdraw( _pid, 0);
        IERC20(_asset).safeDecreaseAllowance(MasterChef, 0);
       IERC20(_reward).safeTransfer(address(_ghostFarmer), IERC20(_reward).balanceOf(address(this)));
    }

    function totalAssets () public view override returns (uint256) {
    return _totalAssets;
      
    }

}
    
