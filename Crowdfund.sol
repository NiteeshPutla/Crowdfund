// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
interface IERC20 {
    function transfer(address, uint) external returns (bool);
    function transferFrom(address, address, uint) external returns (bool);
    function balanceOf(address) external view returns (uint);
}

contract CrowdFunding {
    address public manager;
    uint256 public goal;
    uint256 public totalFunding;
    mapping(address => uint256) public contributions;
    IERC20 public immutable token;
    bool public isGoalReached;

    event FundTransfer(
        address from,
        address to,
        uint256 value
    );

    constructor (
        address _token,
        address _manager,
        uint256 _goal
    ) {
        manager = _manager;
        goal = _goal;
        token = IERC20(_token);
        isGoalReached = false;
    }

    function contribute() public payable{
        require(msg.value > 0, "Contribution amount should be greater than 0");
        require(!isGoalReached, "Goal has already been reached");

        uint256 balanceBeforeTransfer = token.balanceOf(address(this));
        token.transferFrom(msg.sender, address(this), msg.value);
        uint256 balanceAfterTransfer = token.balanceOf(address(this));
        uint256 transferredAmount = balanceAfterTransfer - balanceBeforeTransfer;

        contributions[msg.sender] += transferredAmount;
        totalFunding += transferredAmount;

        emit FundTransfer(msg.sender, manager, transferredAmount);

        if (totalFunding >= goal) {
            isGoalReached = true;
        }
    }

    function withdraw() public {
        require(msg.sender == manager, "Only the manager can withdraw funds");
        require(isGoalReached, "Goal has not been reached yet");

        token.transfer(manager, totalFunding);
        totalFunding = 0;

        emit FundTransfer(address(this), manager, totalFunding);
    }

    function refund() public {
        require(isGoalReached == false, "Goal has been reached, refunds are not possible");
        require(contributions[msg.sender] > 0, "Sender has not contributed any funds");

        uint256 amountToRefund = contributions[msg.sender];
        contributions[msg.sender] = 0;
        totalFunding -= amountToRefund;

        token.transfer(msg.sender, amountToRefund);

        emit FundTransfer(address(this), msg.sender, amountToRefund);
    }
}
