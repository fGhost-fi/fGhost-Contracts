//SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import {ERC20} from "Contracts/Support/ERC20.sol";
import {ERC4626} from "Contracts/Support/ERC4626.sol";
import "Contracts/Support/IERC20Metadata.sol";
import "Contracts/Support/SafeERC20.sol";
import "Contracts/Support/utils/Ownable.sol";

interface TarotSupplyVault{

     function deposit(uint256 _pid, uint256 _amount) external;
     function withdraw(uint256 _pid, uint256 _amount) external;

}

contract xTarotVault is ERC4626, Ownable{
   using SafeERC20 for IERC20;
    
address constant xTarotSupply = 0x466eBD9EC2027776fa11a982E9BBe4F67aa6e86B;
TarotSupplyVault xTarot = TarotSupplyVault(xTarotSupply);
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
       SafeERC20.safeApprove(_asset, xTarotSupply, uint (assets)); 
        xTarot.withdraw( _pid, uint (assets));
        SafeERC20.safeDecreaseAllowance(_asset, xTarotSupply, 0);
         beforeWithdrawHookCalledCounter++;
    }
    function afterDeposit(uint256 assets, uint256) internal override{
         SafeERC20.safeApprove(_asset, xTarotSupply, assets);
        xTarot.deposit(uint(_pid), uint (assets));
        SafeERC20.safeDecreaseAllowance(_asset, xTarotSupply, 0);
        afterDepositHookCalledCounter++;
    }
function Harvest()external{
     SafeERC20.safeApprove(_asset, xTarotSupply, 1000); 
        xTarot.withdraw( _pid, 0);
        SafeERC20.safeDecreaseAllowance(_asset, xTarotSupply, 0);
        SafeERC20.safeTransfer(_reward, address(_ghostFarmer), balanceOf(address(_reward)));
}
function changeReward(uint _newPid) public onlyOwner {
_pid = _newPid;
}
}