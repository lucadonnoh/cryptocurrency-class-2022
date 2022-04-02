// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

contract DepositAndRefund {
    mapping(address => uint256) public balances;
    mapping(address => uint256) public timers;
    uint256 public constant lockupPeriod = 1 days;

    receive() external payable {}

    function getBalance(address _party) public view returns (uint256) {
        return balances[_party];
    }

    function deposit() public payable {
        require(msg.value > 0, "zero value sent");
        balances[msg.sender] += msg.value;
        timers[msg.sender] = block.timestamp;
    }

    function withdraw(uint256 _amount) public {
        require(_amount <= balances[msg.sender], "insufficient balance");
        require(
            block.timestamp >= timers[msg.sender] + lockupPeriod,
            "still locked up"
        );
        balances[msg.sender] -= _amount;
        payable(msg.sender).transfer(_amount);
    }
}
