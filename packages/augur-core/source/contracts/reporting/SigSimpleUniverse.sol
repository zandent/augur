pragma solidity >=0.5.10;


import 'ROOT/reporting/ISimpleUniverse.sol';
import 'ROOT/libraries/math/SafeMathUint256.sol';
// import 'ROOT/Cash.sol';
// import 'ROOT/TestNetDaiVat.sol';
// import 'ROOT/TestNetDaiPot.sol';
// import 'ROOT/TestNetDaiJoin.sol';
import 'ROOT/Augur.sol';
import 'ROOT/external/IDaiVat.sol';
import 'ROOT/external/IDaiPot.sol';
import 'ROOT/external/IDaiJoin.sol';
//import 'ROOT/IAugur.sol';
import 'ROOT/Cash.sol';


/**
 * @title Universe
 * @notice A Universe encapsulates a whole instance of Augur. In the event of a fork in a Universe it will split into child Universes which each represent a different version of the truth with respect to how the forking market should resolve.
 */
contract SigSimpleUniverse is ISimpleUniverse {
    using SafeMathUint256 for uint256;
    // a constant that should be set to the daily block rate of the network
    uint public DAILYBLOCKRATE;

    Augur public augur;

    // DAI / DSR specific
    uint256 public totalBalance;
    Cash public cash;
    IDaiVat public daiVat;
    IDaiPot public daiPot;
    IDaiJoin public daiJoin;

    uint256 constant public DAI_ONE = 10 ** 27;

    // Signal emitted when a transaction needs to be executed
    signal DailySignal();

    // Slot that does the executing
    handler Update() public {
        uint DBR = DAILYBLOCKRATE;
        sweepInterest();
        emitsig DailySignal().delay(DBR);
    }

    function saveDaiInDSR(uint256 _amount) public returns (bool) {
        //daiJoin.join(address(this), _amount);
        //daiPot.drip();
        uint256 _sDaiAmount = _amount.mul(DAI_ONE) / daiPot.chi(); // sDai may be lower than the full amount joined above. This means the VAT may have some dust and we'll be saving less than intended by a dust amount
        //daiPot.join(_sDaiAmount);
        return true;
    }

    function withdrawDaiFromDSR(uint256 _amount) public returns (bool) {
        //daiPot.drip();
        uint256 _chi = daiPot.chi();
        uint256 _sDaiAmount = _amount.mul(DAI_ONE) / _chi; // sDai may be lower than the amount needed to retrieve `amount` from the VAT. We cover for this rounding error below
        if (_sDaiAmount.mul(_chi) < _amount.mul(DAI_ONE)) {
            _sDaiAmount += 1;
        }
        _sDaiAmount = _sDaiAmount.min(daiPot.pie(address(this))); // Never try to draw more than the balance in the pot. If we have less than needed we _must_ have enough already in the VAT provided no negative interest was ever applied
        withdrawSDaiFromDSR(_sDaiAmount);
        return true;
    }

    function withdrawSDaiFromDSR(uint256 _sDaiAmount) public returns (bool) {
        //daiPot.exit(_sDaiAmount);
        //daiJoin.exit(address(this), daiVat.dai(address(this)).div(DAI_ONE));
        return true;
    }

    function deposit(address _sender, uint256 _amount, address _market) public returns (bool) {
        require(augur.isTrustedSender(msg.sender) || msg.sender == _sender);
        bool success = augur.trustedTransfer(cash, _sender, address(this), _amount);
        require(success, "Transfer failed");
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
        //daiPot.drip();
        withdrawSDaiFromDSR(daiPot.pie(address(this))); // Pull out all funds
        saveDaiInDSR(totalBalance); // Put the required funds back in savings
        _extraCash = cash.balanceOf(address(this));
        // The amount in the DSR pot and VAT must cover our totalBalance of Dai
        require(daiPot.pie(address(this)).mul(daiPot.chi()).add(daiVat.dai(address(this))) >= totalBalance.mul(DAI_ONE));
        cash.transfer(msg.sender, _extraCash);
        return true;
    }
    
    function setdailyblockrate(uint dailyblockrate) public returns (bool) {
        require(dailyblockrate >= 200, "daily block rate must be exceed 200");
        DAILYBLOCKRATE = dailyblockrate;
    }

    function start_emit() public {
        uint DBR = DAILYBLOCKRATE;
        // Emit a signal for delayed execution of this transaction
        emitsig DailySignal().delay(DBR);
    }
    
    constructor(Augur _augur, uint dailyblockrate) public {
        DAILYBLOCKRATE = dailyblockrate;
        augur = _augur;
        cash = Cash(augur.lookup("Cash"));
        daiVat = IDaiVat(augur.lookup("DaiVat"));
        daiPot = IDaiPot(augur.lookup("DaiPot"));
        daiJoin = IDaiJoin(augur.lookup("DaiJoin"));
        daiVat.hope(address(daiPot));
        daiVat.hope(address(daiJoin));
        cash.approve(address(daiJoin), 2 ** 256 - 1);
        // bind slot to signal
        Update.bind(DailySignal);
    }

}
