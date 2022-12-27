// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.10;

import "../../Support/utils/Ownable.sol";
import "../../Support/IERC20.sol";

abstract contract FrontEndRewarder is Ownable {

  /* ========= STATE VARIABLES ========== */

  uint256 public daoReward; // % reward for dao (3 decimals: 100 = 1%)
  uint256 public refReward; // % reward for referrer (3 decimals: 100 = 1%)
  mapping(address => uint256) public rewards; // front end operator rewards
  mapping(address => bool) public whitelisted; // whitelisted status for operators

  IERC20 internal immutable fghst; // reward token
  address public MultiSig;

  constructor(
    address _multiSig, 
    IERC20 _fghst
  ) {
    fghst = _fghst;
    MultiSig = _multiSig;
  }

  /* ========= EXTERNAL FUNCTIONS ========== */

  // pay reward to front end operator
  function getReward() external {
    uint256 reward = rewards[msg.sender];

    rewards[msg.sender] = 0;
    fghst.transfer(msg.sender, reward);
  }

  /* ========= INTERNAL ========== */

  /** 
   * @notice add new market payout to user data
   */
  function _giveRewards(
    uint256 _payout,
    address _referral
  ) internal returns (uint256) {
    // first we calculate rewards paid to the DAO and to the front end operator (referrer)
    uint256 toDAO = _payout * daoReward / 1e4;
    uint256 toRef = _payout * refReward / 1e4;

    // and store them in our rewards mapping
    if (whitelisted[_referral]) {
      rewards[_referral] += toRef;
      rewards[MultiSig] += toDAO;
    } else { // the DAO receives both rewards if referrer is not whitelisted
      rewards[MultiSig] += toDAO + toRef;
    }
    return toDAO + toRef;
  }

  /**
   * @notice set rewards for front end operators and DAO
   */
  function setRewards(uint256 _toFrontEnd, uint256 _toDAO) external onlyOwner {
    refReward = _toFrontEnd;
    daoReward = _toDAO;
  }

  /**
   * @notice add or remove addresses from the reward whitelist
   */
  function whitelist(address _operator) external onlyOwner {
    whitelisted[_operator] = !whitelisted[_operator];
  }
}