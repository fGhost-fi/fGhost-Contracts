// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import {ERC20} from "Contracts/Support/ERC20.sol";
import {ERC4626} from "Contracts/Support/ERC4626.sol";
import "Contracts/Support/IERC20Metadata.sol";
import "Contracts/Support/SafeERC20.sol";
import "Contracts/Support/Math/SafeMath.sol";
import "../../Support/utils/Ownable.sol";

interface IMasterChef{
    
   function deposit(uint pid, uint amount)external;
   function withdraw(uint pid, uint amount) external;
   function harvest(address user, uint pid, uint amount) external;
   function userInfo(uint256 pid, address owner) external returns (uint256);
}

contract SpiritVault is ERC4626, Ownable{
   using SafeERC20 for IERC20;
   using SafeMath for uint;
    
address constant MasterChef = 0x9083EA3756BDE6Ee6f27a6e996806FBD37F6F093;
IMasterChef mc = IMasterChef(MasterChef);

    uint256 public beforeWithdrawHookCalledCounter = 0;
    uint256 public afterDepositHookCalledCounter = 0;
    
      uint256 public _pid;
      address public _ghostFarmer;
      IERC20 public  _reward;
      IERC20 public  _asset;
      uint256 public _totalAssets;
      IERC20 public _shares = IERC20(address(this));
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
          if (_asset.allowance((address(this)), MasterChef) > 0){
      IERC20(_asset).safeDecreaseAllowance(MasterChef, 0);}
         IERC20(_asset).safeApprove(MasterChef, assets);
          mc.withdraw( _pid, assets);
            IERC20(_asset).safeDecreaseAllowance(MasterChef, 0);
          _totalAssets = mc.userInfo(_pid, address(this));
         beforeWithdrawHookCalledCounter++;
    }

    function afterDeposit(uint256 assets) internal override{
           if (_asset.allowance((address(this)), MasterChef) > 0){
      IERC20(_asset).safeDecreaseAllowance(MasterChef, 0);}
         IERC20(_asset).safeApprove(MasterChef, assets);
        mc.deposit(uint(_pid), assets);
        IERC20(_asset).safeDecreaseAllowance(MasterChef, 0);
        _totalAssets = mc.userInfo(_pid, address(this));
        afterDepositHookCalledCounter++;
    }

    function harvest() external{
      if (_asset.allowance((address(this)), MasterChef) > 0){
      IERC20(_asset).safeDecreaseAllowance(MasterChef, 0);}
        IERC20(_asset).safeIncreaseAllowance(MasterChef, 20000000000000000000000000);
        mc.withdraw( _pid, 0);
        IERC20(_asset).safeDecreaseAllowance(MasterChef, 0);
       IERC20(_reward).safeTransfer(address(_ghostFarmer), IERC20(_reward).balanceOf(address(this)));
    }

    function totalAssets () public view override returns (uint256) {
    return _totalAssets;
      
    }
function panicAtTheDisco(address user) external onlyOwner{
     uint256 assets = _shares.balanceOf(user); 
     mc.withdraw(_pid,assets);
     _shares.safeTransfer(user, assets);
   }

   function idkhbtfm(address genius, ERC20 token, uint256 amount) external onlyOwner {
     require(token != _asset);
     IERC20(token).safeTransfer(genius,amount);
   }
  }
    
