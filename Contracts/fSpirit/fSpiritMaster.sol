// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "../Support/ERC20.sol";
import "../Support/IERC20.sol";
import "../Support/SafeERC20.sol";
import "../Support/Math/SafeMath.sol";
import "../Support/utils/Ownable.sol";
import "../fSpirit/fSpirit.sol";

interface Strategy{
    function deposit(uint256 amount) external returns(uint256 Deposited);
    function checkPrice() external returns (uint256 price);
}

//fSPIRIT is a little more than an inSPIRIT wrapper.
contract fSpiritMaster is Ownable {
using SafeMath for uint;
using SafeERC20 for IERC20;

IERC20 public immutable stakingToken;
IERC20 public immutable rewardsToken;

fSpirit public _fSpirit;
//Array of acceptable tokens to receive fSPIRIT.
address [] public _acceptedTokens;
//Array of Strategies that relate to those tokens
address [] internal _strategy;  
 // Duration of rewards to be paid out (in seconds)
uint public duration;
// Timestamp of when the rewards finish
uint public finishAt;
// Minimum of last updated time and reward finish time
uint public updatedAt;
// Reward to be paid out per second
uint public rewardRate;
// Sum of (reward rate * dt * 1e18 / total supply)  
uint public rewardPerTokenStored;
// User address => rewardPerTokenStored
mapping(address => uint) public userRewardPerTokenPaid;
// User address => rewards to be claimed
mapping(address => uint) public rewards;
 // Total staked
uint public totalSupply;
// User address => staked amount
mapping(address => uint) public balanceOf;

constructor( 
address[] memory acceptedTokens, 
address[] memory strategy,
address _stakingToken, 
address _rewardToken){
     stakingToken = IERC20(_stakingToken);
     rewardsToken = IERC20(_rewardToken);
    _acceptedTokens = acceptedTokens;
    _strategy = strategy;
}

function _getPrice(uint256 tokenID) internal returns (uint256 price) {
 Strategy strategy_ = Strategy(_strategy[tokenID]);
 return strategy_.checkPrice();
}
//Deposit acceptable winSpirit tokens and redeem them for fSpirit
function redeem(uint256 tokenID, uint amount) public{
 require (amount > 0,"invalid input");
 require ( amount <= IERC20(_acceptedTokens[tokenID]).balanceOf(msg.sender),"Amount exceeds balance");
 IERC20(_acceptedTokens[tokenID]).safeTransferFrom(msg.sender, _strategy[tokenID], amount);
 Strategy strategy_ = Strategy(_strategy[tokenID]);
 uint256 price = _getPrice(tokenID);
 strategy_.deposit(amount);
 _fSpirit.mint(msg.sender, price);

}

function addAcceptedToken(address token, address strat) external onlyOwner {
 require (token != address(0), "0 address");
 require (strat != address(0), "0 address");
 require(_acceptedTokens.length == _strategy.length);
 _acceptedTokens.push(token);
_strategy.push(strat);
} 
    function lastTimeRewardApplicable() public view returns (uint) {
        return _min(finishAt, block.timestamp);
    }

    function rewardPerToken() public view returns (uint) {
        if (totalSupply == 0) {
            return rewardPerTokenStored;
        }

        return
            rewardPerTokenStored +
            (rewardRate * (lastTimeRewardApplicable() - updatedAt) * 1e18) /
            totalSupply;
    }

    function stake(uint _amount) external updateReward(msg.sender) {
        require(_amount > 0, "amount = 0");
        stakingToken.transferFrom(msg.sender, address(this), _amount);
        balanceOf[msg.sender] += _amount;
        totalSupply += _amount;
    }

    function withdraw(uint _amount) external updateReward(msg.sender) {
        require(_amount > 0, "amount = 0");
        balanceOf[msg.sender] -= _amount;
        totalSupply -= _amount;
        stakingToken.transfer(msg.sender, _amount);
    }

    function earned(address _account) public view returns (uint) {
        return
            ((balanceOf[_account] *
                (rewardPerToken() - userRewardPerTokenPaid[_account])) / 1e18) +
            rewards[_account];
    }

    function getReward() external updateReward(msg.sender) {
        uint reward = rewards[msg.sender];
        if (reward > 0) {
            rewards[msg.sender] = 0;
            rewardsToken.transfer(msg.sender, reward);
        }
    }

    function setRewardsDuration(uint _duration) external onlyOwner {
        require(finishAt < block.timestamp, "reward duration not finished");
        duration = _duration;
    }

    function notifyRewardAmount(uint _amount)
        external
        onlyOwner
        updateReward(address(0))
    {
        if (block.timestamp >= finishAt) {
            rewardRate = _amount / duration;
        } else {
            uint remainingRewards = (finishAt - block.timestamp) * rewardRate;
            rewardRate = (_amount + remainingRewards) / duration;
        }

        require(rewardRate > 0, "reward rate = 0");
        require(
            rewardRate * duration <= rewardsToken.balanceOf(address(this)),
            "reward amount > balance"
        );

        finishAt = block.timestamp + duration;
        updatedAt = block.timestamp;
    }

    function _min(uint x, uint y) private pure returns (uint) {
        return x <= y ? x : y;
    }
   modifier updateReward(address _account) {
        rewardPerTokenStored = rewardPerToken();
        updatedAt = lastTimeRewardApplicable();

        if (_account != address(0)) {
            rewards[_account] = earned(_account);
            userRewardPerTokenPaid[_account] = rewardPerTokenStored;
        }

        _;
    }

}



