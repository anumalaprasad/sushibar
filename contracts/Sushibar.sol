// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol"; 
 
contract SushiBar is ERC20("SushiBar", "xSUSHI"){
    IERC20 public sushi;
    address owner;
    
    constructor(IERC20 _sushi)   {
        sushi = _sushi;
        owner = msg.sender;
    }

    struct User{
        
        uint stakedAmt;
        uint stakedTime;
        bool isStaked;
    }
    mapping (address => User) public users; 
    
    uint32 constant ONE_DAY = 1 days;
    uint public testSecs = 0;
 
    function stake(uint _amount) public {
        User storage _user = users[msg.sender];
        // check if already staked
        require(_user.isStaked == false, "one stake at a time");
        // check if approved
        require(sushi.allowance(msg.sender, address(this)) >= _amount, "Allowed limit exceeded");
        // Gets the amount of Sushi locked in the contract
        uint totalSushi = sushi.balanceOf(address(this));
        // Gets the amount of xSushi in existence
        uint totalShares = totalSupply();
        // If no xSushi exists, mint it 1:1 to the amount put in
        if (totalShares == 0 || totalSushi == 0) {
            _mint(msg.sender, _amount);
            _user.stakedAmt = _amount;
        } 
        // Calculate and mint the amount of xSushi the Sushi is worth. The ratio will change overtime, as xSushi is burned/minted and Sushi deposited + gained from fees / withdrawn.
        else {
            uint what = _amount*totalShares/totalSushi;
            _mint(msg.sender, what);
             _user.stakedAmt = what;
        }
        _user.stakedTime = block.timestamp;
        // staking is active
        _user.isStaked = true;
        // Lock the Sushi in the contract
        sushi.transferFrom(msg.sender, address(this), _amount);
    }

    // Leave the bar. Claim back your SUSHIs.
    // Unlocks the staked + gained Sushi and burns xSushi
    function unstake() public {
        User storage _user = users[msg.sender];
        uint _share = _user.stakedAmt;
        // Gets the amount of xSushi in existence
        uint totalShares = totalSupply();
        // Calculates the amount of Sushi the xSushi is worth
        uint what = _share*(sushi.balanceOf(address(this)))/(totalShares);

        uint secsElapsed = block.timestamp - _user.stakedTime + testSecs;
        
        if(secsElapsed >= 8*ONE_DAY){
            what = what;
        } else if(secsElapsed >= 6*ONE_DAY){
            what = what*3/4;
        } else if(secsElapsed >= 4*ONE_DAY){
            what = what/2;
        } else if(secsElapsed >= 2*ONE_DAY){
            what = what/4;
        } else {
           revert();
        } 
        // staking is inactive
        _user.isStaked = false;
        _burn(msg.sender, _share);
        sushi.transfer(msg.sender, what); 
    }

    function SetTestSeconds(uint _timeForward) public {
        require(msg.sender == owner, "not allowed");
        testSecs = _timeForward;
    }
}