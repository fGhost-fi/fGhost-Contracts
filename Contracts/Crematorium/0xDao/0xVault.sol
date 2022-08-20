// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import {ERC20} from "Contracts/Support/ERC20.sol";
import {ERC4626} from "Contracts/Support/ERC4626.sol";
import "Contracts/Support/IERC20Metadata.sol";
import "Contracts/Support/SafeERC20.sol";
import "Contracts/Support/Math/SafeMath.sol";

interface UserProxyInterface{

     function depositLpAndStake(address solidPoolAddress, uint256 amount) external;
   function unstakeLpAndWithdraw(address solidPoolAddress, uint256 amount) external;
   function claimStakingRewards(address stakingPoolAddress ) external;
}

contract OxVault is ERC4626{
    using SafeERC20 for IERC20;
    using SafeMath for uint;

UserProxyInterface constant Ox = UserProxyInterface(Proxy);

address constant Proxy = 0xD2f585C41cca33dce5227C8DF6aDF604085690c2;
    uint256 public beforeWithdrawHookCalledCounter = 0;
    uint256 public afterDepositHookCalledCounter = 0;
 address public _ghostFarmer;
 IERC20 public _reward;
 IERC20 public _asset;
 address public _stakingPoolAddress;
 address public _solidPoolAddress;

    constructor(
        IERC20Metadata asset,
        string memory name,
        string memory symbol,
        address GhostFarmer,
        IERC20 Reward,
        address StakingPoolAddress,
        address SolidPoolAddress
    ) ERC20(name, symbol) ERC4626(asset) {
        _asset = asset;       
       StakingPoolAddress = _stakingPoolAddress;
         Reward = _reward;
        GhostFarmer = _ghostFarmer;
        SolidPoolAddress = _solidPoolAddress;
    }
     
     function totalAssets() public view override returns (uint256) {
        return balanceOf(address(this));
     }
    function beforeWithdraw (uint256 assets, uint256) internal override{
       SafeERC20.safeApprove(_asset, Proxy, uint256(assets));
        Ox.unstakeLpAndWithdraw(_solidPoolAddress, uint(assets));
       SafeERC20.safeDecreaseAllowance(_asset, Proxy, 0);
         beforeWithdrawHookCalledCounter++;
    }
    function afterDeposit(uint256 assets, uint256) internal override{
         SafeERC20.safeApprove(_asset, Proxy, uint256(assets));
        Ox.depositLpAndStake(_solidPoolAddress, uint256(assets));
        SafeERC20.safeDecreaseAllowance(_asset, Proxy, 0);
        afterDepositHookCalledCounter++;
    }

    function Harvest()external{
        Ox.claimStakingRewards(_stakingPoolAddress);
        SafeERC20.safeTransfer(_reward, _ghostFarmer, balanceOf(address(_reward)));
    }


}

