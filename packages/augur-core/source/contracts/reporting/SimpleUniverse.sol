pragma solidity >=0.5.10;


import 'ROOT/reporting/IUniverse.sol';
// import 'ROOT/factories/IReputationTokenFactory.sol';
// import 'ROOT/factories/IDisputeWindowFactory.sol';
// import 'ROOT/factories/IMarketFactory.sol';
// import 'ROOT/factories/IOICashFactory.sol';
// import 'ROOT/reporting/IMarket.sol';
// import 'ROOT/reporting/IV2ReputationToken.sol';
// import 'ROOT/reporting/IDisputeWindow.sol';
// import 'ROOT/reporting/Reporting.sol';
// import 'ROOT/reporting/IRepPriceOracle.sol';
import 'ROOT/libraries/math/SafeMathUint256.sol';
import 'ROOT/Cash.sol';
// import 'ROOT/reporting/IOICash.sol';
// import 'ROOT/external/IAffiliateValidator.sol';
import 'ROOT/TestNetDaiVat.sol';
import 'ROOT/TestNetDaiPot.sol';
import 'ROOT/TestNetDaiJoin.sol';
//import 'ROOT/utility/IFormulas.sol';
import 'ROOT/Augur.sol';


/**
 * @title Universe
 * @notice A Universe encapsulates a whole instance of Augur. In the event of a fork in a Universe it will split into child Universes which each represent a different version of the truth with respect to how the forking market should resolve.
 */
contract SimpleUniverse is IUniverse {
    using SafeMathUint256 for uint256;

    Augur public augur;
    mapping (address => uint256) private validityBondInAttoCash;
    mapping (address => uint256) private designatedReportStakeInAttoRep;
    mapping (address => uint256) private designatedReportNoShowBondInAttoRep;
    uint256 public previousValidityBondInAttoCash;
    uint256 public previousDesignatedReportStakeInAttoRep;
    uint256 public previousDesignatedReportNoShowBondInAttoRep;

    mapping (address => uint256) private shareSettlementFeeDivisor;
    uint256 public previousReportingFeeDivisor;

    uint256 constant public INITIAL_WINDOW_ID_BUFFER = 365 days * 10 ** 8;
    uint256 constant public DEFAULT_NUM_OUTCOMES = 2;
    uint256 constant public DEFAULT_NUM_TICKS = 100;

    // DAI / DSR specific
    uint256 public totalBalance;
    Cash public cash;
    TestNetDaiVat public daiVat;
    TestNetDaiPot public daiPot;
    TestNetDaiJoin public daiJoin;

    uint256 constant public DAI_ONE = 10 ** 27;

    constructor(Augur _augur) public {
        augur = _augur;
        cash = Cash(augur.lookup("Cash"));
        daiVat = TestNetDaiVat(augur.lookup("DaiVat"));
        daiPot = TestNetDaiPot(augur.lookup("DaiPot"));
        daiJoin = TestNetDaiJoin(augur.lookup("DaiJoin"));
        daiVat.hope(address(daiPot));
        daiVat.hope(address(daiJoin));
        cash.approve(address(daiJoin), 2 ** 256 - 1);
    }

    function saveDaiInDSR(uint256 _amount) private returns (bool) {
        daiJoin.join(address(this), _amount);
        daiPot.drip();
        uint256 _sDaiAmount = _amount.mul(DAI_ONE) / daiPot.chi(); // sDai may be lower than the full amount joined above. This means the VAT may have some dust and we'll be saving less than intended by a dust amount
        daiPot.join(_sDaiAmount);
        return true;
    }

    function withdrawDaiFromDSR(uint256 _amount) private returns (bool) {
        daiPot.drip();
        uint256 _chi = daiPot.chi();
        uint256 _sDaiAmount = _amount.mul(DAI_ONE) / _chi; // sDai may be lower than the amount needed to retrieve `amount` from the VAT. We cover for this rounding error below
        if (_sDaiAmount.mul(_chi) < _amount.mul(DAI_ONE)) {
            _sDaiAmount += 1;
        }
        _sDaiAmount = _sDaiAmount.min(daiPot.pie(address(this))); // Never try to draw more than the balance in the pot. If we have less than needed we _must_ have enough already in the VAT provided no negative interest was ever applied
        withdrawSDaiFromDSR(_sDaiAmount);
        return true;
    }

    function withdrawSDaiFromDSR(uint256 _sDaiAmount) private returns (bool) {
        daiPot.exit(_sDaiAmount);
        daiJoin.exit(address(this), daiVat.dai(address(this)).div(DAI_ONE));
        return true;
    }

    function deposit(address _sender, uint256 _amount, address _market) public returns (bool) {
        require(augur.isTrustedSender(msg.sender) || msg.sender == _sender);
        augur.trustedTransfer(cash, _sender, address(this), _amount);
        totalBalance = totalBalance.add(_amount);
        marketBalance[_market] = marketBalance[_market].add(_amount);
        saveDaiInDSR(_amount);
        return true;
    }

    function withdraw(address _recipient, uint256 _amount, address _market) public returns (bool) {
        if (_amount == 0) {
            return true;
        }
        require(augur.isTrustedSender(msg.sender) || augur.isKnownMarket(IMarket(msg.sender)));
        totalBalance = totalBalance.sub(_amount);
        marketBalance[_market] = marketBalance[_market].sub(_amount);
        withdrawDaiFromDSR(_amount);
        cash.transfer(_recipient, _amount);
        return true;
    }

    function sweepInterest() public returns (bool) {
        uint256 _extraCash = 0;
        daiPot.drip();
        withdrawSDaiFromDSR(daiPot.pie(address(this))); // Pull out all funds
        saveDaiInDSR(totalBalance); // Put the required funds back in savings
        _extraCash = cash.balanceOf(address(this));
        // The amount in the DSR pot and VAT must cover our totalBalance of Dai
        assert(daiPot.pie(address(this)).mul(daiPot.chi()).add(daiVat.dai(address(this))) >= totalBalance.mul(DAI_ONE));
        cash.transfer(address(getOrCreateNextDisputeWindow(false)), _extraCash);
        return true;
    }
}
