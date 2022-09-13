// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import {ERC20} from "Contracts/Support/ERC20.sol";
import {ERC4626} from "Contracts/Support/ERC4626.sol";
import "Contracts/Support/IERC20Metadata.sol";
import "Contracts/Support/SafeERC20.sol";
import "Contracts/Support/Math/SafeMath.sol";

interface IMasterChef{
    
   function deposit(uint pid, uint amount, address to)external;
   function withdraw(uint pid, uint amount, address to) external;
   function userInfo(uint256 pid, address owner) external returns (uint256);
   function  harvest(uint256 pid, address to) external;
}
interface swap {
  function addLiquidity( uint256[2] calldata amounts, uint256 minToMint, uint256 deadline) external payable returns(uint256);
  function calculateTokenAmount(uint256[2] calldata amounts, bool deposit) external  view  returns (uint256);
}
contract DeusVault is ERC4626{
   using SafeERC20 for IERC20;
   using SafeMath for uint;
    
address constant MasterChef = 0x62ad8dE6740314677F06723a7A07797aE5082Dbb;
IMasterChef mc = IMasterChef(MasterChef);
address constant swapper = 0x54a5039C403fff8538fC582e0e3f07387B707381;
swap iSwap = swap(swapper);

    uint256 public beforeWithdrawHookCalledCounter = 0;
    uint256 public afterDepositHookCalledCounter = 0;
    
      uint256 public _pid = 2;
      IERC20 public _reward0;
      IERC20 public  _reward1;
      IERC20 public  _asset;
      uint256 public _totalAssets;
       uint256 public _rewards;
       IERC20 public _shares = IERC20(address(this));
       uint256 public _tax;
       address public _treasury;
       uint256 _rewardsPerToken;
      

    constructor(
        IERC20Metadata asset,
        string memory name,
        string memory symbol
    ) ERC20(name, symbol) ERC4626(asset) { 
     
      _reward1 = IERC20(0xDE5ed76E7c05eC5e4572CfC88d1ACEA165109E44);
      _reward0 = IERC20(0x953Cd009a490176FcEB3a26b9753e6F01645ff28);
      _asset = IERC20(0xECd9E18356bb8d72741c539e75CEAdB3C5869ea0);
      _treasury = 0x19B8F9b3D418f18C141155bFE3ee242B05edd42B;
        }

    function beforeWithdraw (uint256 assets) internal override{
          if (_asset.allowance((address(this)), MasterChef) > 0){
      IERC20(_asset).safeApprove(MasterChef, 0);}
         IERC20(_asset).safeApprove(MasterChef, assets);
          mc.withdraw( _pid, assets, address(this));
            IERC20(_asset).safeApprove(MasterChef, 0);
          _totalAssets = mc.userInfo(_pid, address(this));
         beforeWithdrawHookCalledCounter++;
    }

    function afterDeposit(uint256 assets) internal override{
           if (_asset.allowance((address(this)), MasterChef) > 0){
      IERC20(_asset).safeApprove(MasterChef, 0);}
         IERC20(_asset).safeApprove(MasterChef, assets);
        mc.deposit(uint(_pid), assets, address(this));
        IERC20(_asset).safeApprove(MasterChef, 0);
        _totalAssets = mc.userInfo(_pid, address(this));
        afterDepositHookCalledCounter++;
    }

    function _autoDeposit(
        address caller,
        address receiver,
        uint256 assets,
        uint256 shares
    ) private {
        
        SafeERC20.safeTransferFrom(_asset, caller, address(this), assets);
        _mint(address(this), shares);
        afterDeposit(assets);
        emit Deposit(caller, receiver, assets, shares);
    }
    function reinvest() external{
      if (_asset.allowance((address(this)), MasterChef) > 0){
      IERC20(_asset).safeApprove(MasterChef, 0);}
        IERC20(_asset).safeApprove(MasterChef, 900000000000000000000000000000);
        mc.harvest( _pid, address(this));
           if (_reward0.allowance((address(this)), swapper) > 0){
      IERC20(_reward0).safeApprove(swapper, 0);}
         IERC20(_reward0).safeApprove(swapper, _reward0.balanceOf(address(this)));
              if (_reward1.allowance((address(this)), swapper) > 0){
      IERC20(_reward1).safeApprove(swapper, 0);}
         IERC20(_reward1).safeApprove(swapper, _reward1.balanceOf(address(this)));
        uint256 tokenBalance1 = _reward0.balanceOf(address(this));
        uint256 tokenBalance2 = _reward1.balanceOf(address(this)); 
       uint256 _minAmount = (iSwap.calculateTokenAmount([tokenBalance1,tokenBalance2],true)/100) *98;
        iSwap.addLiquidity([tokenBalance1, tokenBalance2],_minAmount, block.timestamp*2);
        uint256 assets = _asset.balanceOf(address(this));
         uint256 shares = previewDeposit(assets);
        _autoDeposit(address(this),address(this), assets, shares);
        _tax = _shares.balanceOf(address(this)) / 1000;
        _shares.safeTransfer(_treasury, _tax);
        _rewards = _shares.balanceOf(address(this));
         _rewardsPerToken = _rewards / _totalAssets;
            IERC20(_asset).safeApprove(MasterChef, 0);
                IERC20(_reward0).safeApprove(swapper, 0);
                  IERC20(_reward1).safeApprove(swapper, 0);
    }

    function totalAssets () public view override returns (uint256) {
    return _totalAssets;
      
    }
    
    function harvest() external {
      _rewardsPerToken = _rewards / _totalAssets;
    uint256 _balanceOwed = _rewardsPerToken * IERC20(address(this)).balanceOf(msg.sender);
        _shares.safeTransfer(msg.sender, _balanceOwed);
    }
    
    function pendingRewards(address user) external view returns(uint256 pendingShares) {
     
       uint256 _balanceOwed = _rewardsPerToken * IERC20(address(this)).balanceOf(user);
        return _balanceOwed;
    }
}
    

