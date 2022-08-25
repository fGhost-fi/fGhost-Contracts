// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import {ERC20} from "Contracts/Support/ERC20.sol";
import {ERC4626} from "Contracts/Support/ERC4626.sol";
import "Contracts/Support/IERC20Metadata.sol";
import "Contracts/Support/SafeERC20.sol";

//Interfaces with designated MultiRewarder contract given in constructor.
interface IMultiRewarder {
     function stake(uint256 amount) external;
     function withdraw(uint256 amount) external;
     function getReward() external;
     function getLength() external view returns(uint);
     function listRewards(uint i) external view returns (address _reward);

}

contract xGhostVault is ERC4626{
 using SafeERC20 for IERC20;
   IMultiRewarder multi = IMultiRewarder(MultiRewarder);
   address public MultiRewarder;
   IERC20 public _asset;   
   uint internal i;
   address private token = multi.listRewards(i);
   uint public _totalShares =  ERC20.totalSupply();
   uint internal _totalReward = IERC20(token).balanceOf(address(this)); 
   uint internal _rewardsPerToken = _totalReward / _totalShares; 
   uint public balanceOwed = _rewardsPerToken * ERC20.balanceOf(msg.sender);
   uint internal rewardLength = multi.getLength();
   uint256 public beforeWithdrawHookCalledCounter = 0;
   uint256 public afterDepositHookCalledCounter = 0;
    
     constructor(
        IERC20Metadata asset,
        string memory name,
        string memory symbol,
        address _multiRewarder
        ) ERC20(name, symbol) ERC4626(asset) {
            MultiRewarder = _multiRewarder;
            _asset = asset;
         }

         function beforeWithdraw (uint256 assets,uint256) internal override{
        SafeERC20.safeApprove(_asset, MultiRewarder, uint (assets));
        multi.withdraw(assets);
        SafeERC20.safeDecreaseAllowance(_asset, MultiRewarder, 0);
         beforeWithdrawHookCalledCounter++;}

         function afterDeposit(uint256 assets, uint256) internal override{
         SafeERC20.safeApprove(_asset, MultiRewarder, assets);
        multi.stake( uint (assets));
        SafeERC20.safeDecreaseAllowance(_asset, MultiRewarder, 0);
        afterDepositHookCalledCounter++;
    }
        
        function harvest() external {
        
             if (_totalReward < 0){ 
                 multi.getReward();
                 }
              while ( i < rewardLength) {
                 SafeERC20.safeTransfer(IERC20(token), msg.sender, balanceOwed);
            i++;
        }
              }

         function pendingRewards(uint256 reward)external returns(uint _pending){
             i = reward;
              return balanceOwed;


         }

        }
