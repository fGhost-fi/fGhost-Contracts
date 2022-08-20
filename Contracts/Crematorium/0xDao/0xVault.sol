// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import {ERC20} from "Contracts/Support/ERC20.sol";
import "Contracts/Support/ERC4626.sol";

interface UserProxyInterface{
    
   function depositLPandStake(address solidPoolAddress, uint256 amount);
   function unstakeLpAndWithdraw(address solidPoolAddress, uint256 amount);
   function claimStakingRewards(address stakingPoolAddress );
}

contract OxVault is ERC4626{

address constant Proxy = 0xD2f585C41cca33dce5227C8DF6aDF604085690c2;

    uint256 public beforeWithdrawHookCalledCounter = 0;
    uint256 public afterDepositHookCalledCounter = 0;

    constructor(
        IERC20Metadata asset,
        string memory name,
        string memory symbol,
        address memory GhostFarmer,
        address memory Rewards,
        address memory StakingPoolAddress
    ) ERC20(name, symbol) ERC4626(asset) {}
        
      address  StakingPoolAddress = _StakingPoolAddress;
       address Reward = _Reward;
      address  GhostFarmer = _GhostFarmer;
     
     function totalAssets() external view override returns (uint256) {
        return asset.balanceOf(address(this));
     }
    function beforeWithdraw (uint256 assets, uint256 shares) internal override{
       SafeERC20.safeIncreaseAllowance(_asset, Proxy, amount);
        Proxy.unstakeLpandWithdraw(address(_asset), uint(assets));
       SafeERC20.safeDecreaseAllowance(_asset, Proxy, 0);
         beforeWithdrawHookCalledCounter++;
    }
    function afterDeposit(uint256 assets, uint256 shares) internal override{
         SafeIncreaseAllowance(_asset, Proxy, amount);
        Proxy.depositLPandStake(address(_asset), uint256(assets));
        SafeDecreaseAllowance(_asset, Proxy, 0);
        afterDepositHookCalledCounter++;
    }

    function Harvest()external{
        Proxy.claimStakingRewards(_StakingPoolAddress);
        SafeERC20.safeTransfer(_Reward, address(this), _GhostFarmer, balanceOf(address(_Reward)));
    }


}
