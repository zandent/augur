pragma solidity 0.4.24;

import 'reporting/IReportingParticipant.sol';
import 'reporting/IDisputeWindow.sol';
import 'reporting/IDisputeOverloadToken.sol';
import 'libraries/token/ERC20Token.sol';
import 'IAugur.sol';


contract IDisputeCrowdsourcer is IReportingParticipant, ERC20Token {
    function initialize(IAugur _augur, IMarket market, uint256 _size, bytes32 _payoutDistributionHash, uint256[] _payoutNumerators, IDisputeOverloadToken _disputeOverloadToken, address _erc820RegistryAddress) public returns (bool);
    function contribute(address _participant, uint256 _amount, bool _overload) public returns (uint256);
    function setSize(uint256 _size) public returns (bool);
    function getRemainingToFill() public view returns (uint256);
}
