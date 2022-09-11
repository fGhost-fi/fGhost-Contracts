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
   function userInfo(uint256 pid, address owner) external returns (uint256);
   function  harvest(uint256 pid, address to) external;
}
interface swap {
  function addLiquidity(uint256[2] calldata amounts, uint256 minToMint, uint256 deadline) external payable;
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
    
      uint256 public _pid;
      IERC20 public _reward0;
      IERC20 public  _reward1;
      IERC20 public  _asset;
      uint256 public _totalAssets;
       uint256 public _rewards;
       IERC20 public _shares = IERC20(address(this));
       uint256 public _tax = IERC20(_shares).balanceOf(address(this)) / 1000;
       address public _treasury;

       
    constructor(
        IERC20Metadata asset,
        string memory name,
        string memory symbol,
        uint  pid,
        address treasury,
        IERC20 Reward0,
        IERC20 Reward1
    ) ERC20(name, symbol) ERC4626(asset) { 
      _pid = pid;
      _reward1 = Reward1;
      _reward0 = Reward0;
      _asset = asset;
      _treasury = treasury;
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
      IERC20(_asset).safeDecreaseAllowance(MasterChef, 0);}
        IERC20(_asset).safeIncreaseAllowance(MasterChef, 200000000000000000000000000);
        mc.harvest( _pid, address(this));
        IERC20(_asset).safeDecreaseAllowance(MasterChef, 0);
        iSwap.addLiquidity([_reward0.balanceOf(address(this)), _reward1.balanceOf(address(this))],1,9999999999999999999999999999);
        uint256 assets = _asset.balanceOf(address(this));
         uint256 shares = previewDeposit(assets);
        _autoDeposit(address(this),address(this), assets, shares);
        _shares.safeTransfer(_treasury, _tax);
        _rewards = _shares.balanceOf(address(this));
    }

    function totalAssets () public view override returns (uint256) {
    return _totalAssets;
      
    }
    function harvest() external {
        uint256 _rewardsPerToken = _rewards / _totalAssets;
        uint256 _balanceOwed = _rewardsPerToken * IERC20(address(this)).balanceOf(msg.sender);
        _asset.safeTransfer(msg.sender, _balanceOwed);
    }
}
    

