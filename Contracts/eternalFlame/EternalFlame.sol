// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "Contracts/Support/SafeERC20.sol";
import "Contracts/Support/Math/SafeMath.sol";

interface xGhostVault{
        function Harvest() external;
        function listRewards() external;
        function _rewardLength() external view returns (uint256);
         function pendingRewards(uint256 reward)external returns(uint _pending);
}
interface FireBirdRouter{
     function swap( uint256 amount0Out, uint256 amount1Out, address to, bytes calldata data) external;
}


contract EternalFlame {
using SafeERC20 for IERC20;
using SafeMath for uint256;


IERC20 public stakingToken;
address[] public rewardTokens;
mapping(address => uint256) internal balanceOf;
mapping(address => uint256) public lastUpdate;
uint256 public totalSupply;
address public Vault;
uint256 totalCompounds;
uint compoundFactor;
uint public i;
uint internal rewardLength = xGhost._rewardLength();
IERC20 public _token0;
IERC20 public _token1;
xGhostVault xGhost = xGhostVault(Vault);
address constant fbr = 0xe0C38b2a8D09aAD53f1C67734B9A95E43d5981c0;
FireBirdRouter fireBird = FireBirdRouter(fbr);
 
 
    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);

constructor(
    IERC20 _stakingToken,
    IERC20 Token0,
    IERC20 Token1
){
stakingToken = _stakingToken;
Vault = address(_stakingToken);
_token0 = Token0;
_token1 = Token1;
}
    //deposits amount to 
  function stake(uint256 amount) external updateBalance {
         require(amount > 0, "Cannot stake 0");
        totalSupply += amount;
        balanceOf[msg.sender] += amount;
        stakingToken.safeTransferFrom(msg.sender, address(this), amount);
        emit Staked(msg.sender, amount);
    }
        //update user's balance before 
         function withdraw(uint256 amount) public updateBalance {
          require(amount > 0, "Cannot withdraw 0");
         require (balanceOf[msg.sender] >= amount);
        totalSupply -= amount;
        balanceOf[msg.sender] -= amount;
        stakingToken.safeTransfer(msg.sender, amount);
        emit Withdrawn(msg.sender, amount);
         }
        //withdraw all user's tokens
      function exit() external updateBalance {
        withdraw(balanceOf[msg.sender]);
    }

        function listRewards() internal{
            xGhost.listRewards();
        } 
    
    function forsake() external{
        xGhost.Harvest();
        //To-Do:  do swaps with fire bird router then addLiquidity with Spookyswap Router. Deposit LP to xGhost Vault. 
        uint256 addedBalance = stakingToken.balanceOf(address(this)) - totalSupply;
        uint compound = (addedBalance / totalSupply + 1);
        uint256 ntc = totalCompounds + compound;
        totalCompounds = ntc;
        _token1.safeTransfer( msg.sender, _token1.balanceOf(address(this)));
        _token0.burn(address(this), _token0.balanceOf(address(this)));
    }
    function checkBalance(address user) external view returns (uint256){
        _getCompoundFactor;
        uint balance = balanceOf[user] * compoundFactor;
        if (balance <= 0){ balance = balanceOf[user];}
        return balance;

    }
    function _getCompoundFactor() internal returns (uint256){
           compoundFactor = totalCompounds - lastUpdate[msg.sender];
         if(compoundFactor < 1){compoundFactor = 1;}
         return compoundFactor;
    }
    modifier updateBalance {
          _getCompoundFactor;
        if (compoundFactor > 1){uint oldBalance = balanceOf[msg.sender];
        uint newBalance = oldBalance * compoundFactor;
        balanceOf[msg.sender] = newBalance;
        lastUpdate[msg.sender] = totalCompounds;
         }
        _;
    }
}
