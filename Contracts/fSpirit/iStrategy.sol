// SPDX-License-Identifier: MIT

pragma solidity ^0.8.14;

import "../Support/ERC20.sol";
import "../Support/IERC20.sol";
import "../Support/SafeERC20.sol";
import "../Support/Math/SafeMath.sol";
import "../Support/utils/Ownable.sol";

    interface inSpiritLock {
        function create_lock(uint256 _value, uint256 _unlock_time) external;
        function increase_amount(uint256 _value) external;
        function withdraw() external;}

    interface feeDistributor {
        function claim() external;
}

contract lSpiritStrategy is Ownable{
    using SafeERC20 for IERC20;
    using SafeMath for uint256;


address constant SpiritChef = 0x18CeF75C2b032D7060e9Cf96F29aDF74a9a17ce6;
IERC20 immutable Spirit = IERC20(0x5Cc61A78F164885776AA610fb0FE1257df78E59B);
IERC20 immutable inSpirit = IERC20(0x2FBFf41a9efAEAE77538bd63f1ea489494acdc08);
inSpiritLock IStrat = inSpiritLock(0x2FBFf41a9efAEAE77538bd63f1ea489494acdc08);
feeDistributor ISpirit = feeDistributor(SpiritChef);


address public _fSpiritMaster;

function setMaster(address Master) public onlyOwner{
_fSpiritMaster = Master;
}

function deposit(uint256 amount) external returns (uint256 Deposited){
    Spirit.safeApprove(address(IStrat), type(uint256).max);
     if (inSpirit.balanceOf(address(this)) < 1) 
        { IStrat.create_lock(amount, block.timestamp + 103161600);} 
        if (inSpirit.balanceOf(address(this)) > 0) { IStrat.increase_amount(amount);}     
    Spirit.safeApprove(address(IStrat), 0);
    harvest();
    return Deposited;
}

function _withdraw() internal returns(uint256 Withdrawn){
  IStrat.withdraw();
  return Withdrawn;
}

function harvest() public {
    ISpirit.claim();
    Spirit.safeTransfer(_fSpiritMaster, Spirit.balanceOf(address(this)));
}

function checkPrice() external pure returns(uint256 price) {
return price = 1;
}
function panicAtTheDisco(uint256) external onlyOwner {
    _withdraw();
    inSpirit.safeTransfer(_msgSender(), inSpirit.balanceOf(address(this)));      
}
}