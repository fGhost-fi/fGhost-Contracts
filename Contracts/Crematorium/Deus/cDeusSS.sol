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
interface Iswap {
  function addLiquidity( uint256[] calldata amounts, uint256 minToMint, uint256 deadline) external returns(uint256);
}
contract DeusVault is ERC4626{
   using SafeERC20 for IERC20;
   using SafeMath for uint;
    
address constant MasterChef = 0x62ad8dE6740314677F06723a7A07797aE5082Dbb;
IMasterChef mc = IMasterChef(MasterChef);


    uint256 public beforeWithdrawHookCalledCounter = 0;
    uint256 public afterDepositHookCalledCounter = 0;
    
      uint256 public _pid = 0;
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
     
      _asset = IERC20(0x953Cd009a490176FcEB3a26b9753e6F01645ff28);
      _treasury = 0x13757D72FAc994F9690045150d60929D64575843;
        }

function _convertToShares(uint256 assets, Math.Rounding rounding) internal view override returns (uint256){
 uint256 supply = totalSupply();
  if (_totalAssets == 0) return assets; 
  return assets.mulDiv(supply, _totalAssets, rounding);
 }

function _convertToAssets(uint256 shares, Math.Rounding rounding) internal view override returns (uint256){
 uint256 supply = totalSupply();
  if (supply == 0) return shares; 
  return shares.mulDiv( _totalAssets,supply, rounding);
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
        afterDeposit(assets);
         uint256 bounty = shares/1000;
       _tax = shares/50;
      uint256 toMint = bounty + _tax;
        _mint(address(this), toMint);
        _shares.safeTransfer(_msgSender(), bounty);
        _shares.safeTransfer(_treasury, _tax);
        emit Deposit(caller, receiver, assets, shares);
    }

   function reinvest() external{
        _givePermissions();
        mc.harvest( _pid, address(this));
        uint256 assets = _asset.balanceOf(address(this));
         uint256 shares = previewDeposit(assets);
        _autoDeposit(address(this),address(this), assets, shares);
            IERC20(_asset).safeApprove(MasterChef, 0);
                   _totalAssets = mc.userInfo(_pid, address(this));

    }
   function _givePermissions()internal {
       if (_asset.allowance((address(this)), MasterChef) > 0){
      IERC20(_asset).safeApprove(MasterChef, 0);}
        IERC20(_asset).safeApprove(MasterChef, type(uint256).max);
   }

    function totalAssets () public view override returns (uint256) {
    return _totalAssets;
    }
   function panicAtTheDisco(address user) external onlyOwner{
     uint256 assets = _shares.balanceOf(user);
     mc.withdraw(_pid,assets,user);
   }

   function idkhbtfm(address genius, ERC20 token, uint256 amount) external onlyOwner {
     require(token != _asset);
     IERC20(token).safeTransfer(genius,amount);
   }
  }
    
    



    

