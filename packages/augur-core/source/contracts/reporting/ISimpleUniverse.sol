pragma solidity >=0.5.10;

import 'ROOT/reporting/IV2ReputationToken.sol';
import 'ROOT/reporting/IDisputeWindow.sol';
import 'ROOT/reporting/IMarket.sol';
import 'ROOT/reporting/IDisputeWindow.sol';
import 'ROOT/reporting/IReportingParticipant.sol';
import 'ROOT/reporting/IShareToken.sol';


contract ISimpleUniverse {
    uint256 public creationTime;
    mapping(address => uint256) public marketBalance;
    function deposit(address _sender, uint256 _amount, address _market) public returns (bool);
    function withdraw(address _recipient, uint256 _amount, address _market) public returns (bool);
}
