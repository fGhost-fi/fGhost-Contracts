// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import {ERC20} from "Contracts/Support/ERC20.sol";
import {ERC4626} from "Contracts/Support/ERC4626.sol";
import "Contracts/Support/IERC20Metadata.sol";
import "../../Support/SafeERC20.sol";
import "../../Support/Math/SafeMath.sol";
import "../../Support/utils/Ownable.sol"; 
import "../../Support/Math/Math.sol";

interface IMasterChef{
    
   function deposit(uint pid, uint amount, address to)external;
   function withdraw(uint pid, uint amount, address to) external;
   function userInfo(uint256 pid, address owner) external returns (uint256);
   function  harvest(uint256 pid, address to) external;
    function pendingTokens(uint256 _pid, address _user) external view returns (uint256 pending);
}

interface Iswap {
  function addLiquidity( uint256[] calldata amounts, uint256 minToMint, uint256 deadline) external returns(uint256);
}
contract DeusVault is ERC4626, Ownable{
   using SafeERC20 for IERC20;
   using Math for uint; 
    
address constant MasterChef = 0x62ad8dE6740314677F06723a7A07797aE5082Dbb;
IMasterChef mc = IMasterChef(MasterChef);
address constant swapper = 0x54a5039C403fff8538fC582e0e3f07387B707381;
Iswap swap = Iswap(swapper);

    uint256 public beforeWithdrawHookCalledCounter = 0;
    uint256 public afterDepositHookCalledCounter = 0;
    
      uint256 public _pid = 2;
      IERC20 public _reward0;
      IERC20 public  _reward1;
      IERC20 public  _asset;
      uint256 public _totalAssets;
       IERC20 public _shares = IERC20(address(this));
       uint256 public _tax;
       uint256 public _bounty = 10;
       address public _treasury;
       mapping (address => uint256) public lastDeposit;
      

    constructor(
        IERC20Metadata asset,
        string memory name,
        string memory symbol
    ) ERC20(name, symbol) ERC4626(asset) { 
     
      _reward1 = IERC20(0xDE5ed76E7c05eC5e4572CfC88d1ACEA165109E44);
      _reward0 = IERC20(0x953Cd009a490176FcEB3a26b9753e6F01645ff28);
      _asset = IERC20(0xECd9E18356bb8d72741c539e75CEAdB3C5869ea0);
      _treasury = 0x13757D72FAc994F9690045150d60929D64575843;
        }

    function beforeWithdraw (uint256 assets) internal override{
          if (_asset.allowance((address(this)), MasterChef) > 0){
      IERC20(_asset).safeApprove(MasterChef, 0);}
         IERC20(_asset).safeApprove(MasterChef, assets);
         require (lastDeposit[_msgSender()] != block.timestamp);
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
        lastDeposit[_msgSender()] = block.timestamp;
        afterDepositHookCalledCounter++;
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
 
   function withdraw(
        uint256 shares,
        address owner
    ) public override returns (uint256) {
        require(shares <= maxWithdraw(owner), "ERC4626: withdraw more than max");
        uint256 sharePerToken = _totalAssets*100/ totalSupply();
        uint256 assets = sharePerToken * shares/100;
        _withdraw(address(this), _msgSender(), owner, assets, shares);
        return shares;
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
        _addLiquidity();
        uint256 assets = _asset.balanceOf(address(this));
         uint256 shares = previewDeposit(assets);
        _autoDeposit(address(this),address(this), assets, shares);
            IERC20(_asset).safeApprove(MasterChef, 0);
                IERC20(_reward0).safeApprove(swapper, 0);
                  IERC20(_reward1).safeApprove(swapper, 0);
                   _totalAssets = mc.userInfo(_pid, address(this));
    }
    function _givePermissions()internal {
       if (_asset.allowance((address(this)), MasterChef) > 0){
      IERC20(_asset).safeApprove(MasterChef, 0);}
        IERC20(_asset).safeApprove(MasterChef, type(uint256).max);
          if (_reward0.allowance((address(this)), swapper) > 0){
      IERC20(_reward0).safeApprove(swapper, 0);}
         IERC20(_reward0).safeApprove(swapper, type(uint256).max);
          if (_reward1.allowance((address(this)), swapper) > 0){
      IERC20(_reward1).safeApprove(swapper, 0);}
         IERC20(_reward1).safeApprove(swapper, type(uint256).max);

    }

    function _addLiquidity() internal {
        uint256 [] memory amounts = new uint256[](2);
        amounts[0] = _reward0.balanceOf(address(this));
        amounts[1] = _reward1.balanceOf(address(this));
        swap.addLiquidity(amounts,0, block.timestamp*2);
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
    
    

