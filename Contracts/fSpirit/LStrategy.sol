// SPDX-License-Identifier: MIT

pragma solidity ^0.8.14;

import "../Support/ERC20.sol";
import "../Support/IERC20.sol";
import "../Support/SafeERC20.sol";
import "../Support/Math/SafeMath.sol";
import "../Support/utils/Ownable.sol";

    interface LinSpiritChef {
        function deposit(uint256 pid, uint256 amount, address to) external;
        function withdraw(uint256 pid, uint256 amount, address to) external;
        function harvest(uint256 pid, address to) external;
        function pendingSpirit(uint256 _pid, address _user) external view returns (uint256 pending);
}

contract lSpiritStrategy is Ownable{
    using SafeERC20 for IERC20;
    using SafeMath for uint256;


address constant SpiritChef = 0x1CC765cD7baDf46A215bD142846595594AD4ffe3;
IERC20 immutable Spirit = IERC20(0x5Cc61A78F164885776AA610fb0FE1257df78E59B);
IERC20 immutable linSpirit = IERC20(0xc5713B6a0F26bf0fdC1c52B90cd184D950be515C);
address constant SpiritLP = 0x54D5B6881b429A694712fa89875448ca8ADF06F4;
LinSpiritChef lStrat = LinSpiritChef(SpiritChef);


uint256 public _pid = 0;
address public _fSpiritMaster;

function setMaster(address Master) public onlyOwner{
_fSpiritMaster = Master;
}

function deposit(uint256 amount) external returns (uint256 Deposited){
    linSpirit.safeApprove(address(lStrat), type(uint256).max);
    lStrat.deposit(_pid, amount, address(this));
    linSpirit.safeApprove(address(lStrat), 0);
    harvest();
    return Deposited;
}

function _withdraw(uint256 amount) internal returns(uint256 Withdrawn){
    lStrat.withdraw(_pid, amount, address(this));
    harvest();
    return Withdrawn;
}

function harvest() public {
    lStrat.harvest(_pid, _fSpiritMaster);
    Spirit.safeTransfer(_fSpiritMaster, Spirit.balanceOf(address(this)));
}

function checkPrice() external view returns(uint256 price) {
uint256 lBalance = linSpirit.balanceOf(SpiritLP);
uint256 sBalance = Spirit.balanceOf(SpiritLP);
return price = lBalance * 1000 /sBalance;
}
function panicAtTheDisco(uint256 amount) external onlyOwner {
    _withdraw(amount);
    linSpirit.safeTransfer(_msgSender(), linSpirit.balanceOf(address(this)));   
}
}