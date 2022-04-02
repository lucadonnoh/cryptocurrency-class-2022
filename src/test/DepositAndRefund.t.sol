// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

import "ds-test/test.sol";
import "../DepositAndRefund.sol";

interface CheatCodes {
    function assume(bool) external;

    function prank(address) external;

    function deal(address who, uint256 newBalance) external;

    function expectRevert(bytes calldata) external;

    function warp(uint256) external;
}

contract DepositAndRefundTest is DSTest {
    DepositAndRefund dnr;
    CheatCodes cheats = CheatCodes(HEVM_ADDRESS);

    receive() external payable {}

    function setUp() public {
        dnr = new DepositAndRefund();
    }

    function testDeposit(address _party, uint256 _amount) public {
        cheats.assume(_amount > 0);
        cheats.deal(_party, _amount);
        cheats.prank(_party);
        dnr.deposit{value: _amount}();
        assert(dnr.getBalance(_party) == _amount);
    }

    function testInsufficientBalance(
        uint256 _amountToDeposit,
        uint256 _amountToWithdraw
    ) public {
        cheats.assume(_amountToDeposit > 0);
        cheats.assume(_amountToWithdraw > _amountToDeposit);
        cheats.deal(address(this), _amountToDeposit);
        dnr.deposit{value: _amountToDeposit}();
        cheats.expectRevert("insufficient balance");
        dnr.withdraw(_amountToWithdraw);
    }

    function testWithdrawPostLockup(
        uint256 _amountToDeposit,
        uint256 _amountToWithdraw,
        uint256 _elapsedTime
    ) public {
        cheats.assume(_amountToDeposit > 0);
        cheats.assume(_amountToWithdraw <= _amountToDeposit);
        cheats.assume(_elapsedTime >= dnr.lockupPeriod());
        cheats.deal(address(this), _amountToDeposit);
        dnr.deposit{value: _amountToDeposit}();
        cheats.warp(block.timestamp + _elapsedTime);
        dnr.withdraw(_amountToWithdraw);
    }

    function testWithdrawPreLockup(
        uint256 _amountToDeposit,
        uint256 _amountToWithdraw,
        uint256 _elapsedTime
    ) public {
        cheats.assume(_amountToDeposit > 0);
        cheats.assume(_amountToWithdraw <= _amountToDeposit);
        cheats.assume(_elapsedTime < dnr.lockupPeriod());
        cheats.deal(address(this), _amountToDeposit);
        dnr.deposit{value: _amountToDeposit}();
        cheats.warp(block.timestamp + _elapsedTime);
        cheats.expectRevert("still locked up");
        dnr.withdraw(_amountToWithdraw);
    }
}
