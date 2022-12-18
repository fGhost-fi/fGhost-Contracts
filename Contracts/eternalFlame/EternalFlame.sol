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

interface IUniswapV2Router {
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    )
        external
        returns (
            uint amountA,
            uint amountB,
            uint liquidity
        );
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
address constant spookyRouter = 0xF491e7B69E4244ad4002BC14e878a34207E38c29;
 IUniswapV2Router Spooky =  IUniswapV2Router(spookyRouter);
address constant private WFTM = 0x21be370D5312f44cB42ce377BC9b8a0cEF1A4C83;
address constant private USDC = 0x04068DA6C83AFCFA0e13ba15A6696662335D5B75;
address constant private FGHST = 0x5C762a454B89C70f96e69890d502d795A639A06A;
IERC20 private ftm = IERC20(WFTM);
IERC20 private usdc = IERC20(USDC);
IERC20 private fGhost = IERC20(FGHST);
 
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
        uint256 rewardSplit = _token0.balanceOf(address(this)) / 2;
        uint256 slippage = rewardSplit/100; 
        uint256 minAmount = rewardSplit - slippage;
        _swap(address(_token0), address(_token1), rewardSplit, minAmount);
        uint256 bounty = _token0.balanceOf(address(this)) / 100;
        uint256 burn = _token1.balanceOf(address(this)) / 100; 
        _addLiquidity(address(_token0),address(_token1), _token0.balanceOf(address(this)) - bounty, _token1.balanceOf(address(this)) - burn);
        uint256 addedBalance = stakingToken.balanceOf(address(this)) - totalSupply;
        uint compound = (addedBalance / totalSupply * 100);
        uint256 ntc = totalCompounds/100 * compound + totalCompounds;
        totalCompounds = ntc;
        _token0.safeTransfer( msg.sender, _token0.balanceOf(address(this)));
        _token1.burn(address(this), _token1.balanceOf(address(this)));
    }
    function checkBalance(address user) external view returns (uint256){
        _getCompoundFactor;
        uint balance = balanceOf[user]/100 * compoundFactor;
        if (balance <= 0){ balance = balanceOf[user];}
        return balance;

    }
    function _getCompoundFactor() internal returns (uint256){
           compoundFactor = totalCompounds - lastUpdate[msg.sender];
         if(compoundFactor < 1){compoundFactor = 1;}
         return compoundFactor;
    }
    function _swap(address tokenIn, address tokenOut, uint256 amountIn, uint256 amountOutMin) internal returns( uint256 amountOut) {
          IERC20(tokenIn).transferFrom(msg.sender, address(this), amountIn);
        IERC20(tokenIn).approve(address(Spooky), amountIn);

        address[] memory path;
        path = new address[](2);
        path[0] = tokenIn;
        path[1] = tokenOut;

        uint[] memory amounts = Spooky.swapExactTokensForTokens(
            amountIn,
            amountOutMin,
            path,
            msg.sender,
            block.timestamp
        );
              return amounts[1];
    

    }
    function _addLiquidity( 
        address _tokenA,
        address _tokenB,
        uint _amountA,
        uint _amountB) internal {
       if (_token0.allowance(address(this),address(Spooky))>0){ 
           _token0.approve(address(Spooky),0);
       }
         if (_token1.allowance(address(this),address(Spooky))>0){ 
           _token1.approve(address(Spooky),0);
       }
        _token0.approve(address(Spooky), _token0.balanceOf(address(this)));
        _token1.approve(address(Spooky), _token0.balanceOf(address(this)));

            Spooky.addLiquidity(
                _tokenA,
                _tokenB,
                _amountA,
                _amountB,
                1,
                1,
                address(this),
                block.timestamp
            );
          _token0.approve(address(Spooky),0);
            _token1.approve(address(Spooky),0);
    }

    modifier updateBalance {
          _getCompoundFactor;
        if (compoundFactor > 1){
        uint oldBalance = balanceOf[msg.sender];
        uint newBalance = oldBalance * compoundFactor;
        balanceOf[msg.sender] = newBalance;
        lastUpdate[msg.sender] = totalCompounds;
         }
        _;
    }
}
