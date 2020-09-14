pragma solidity >=0.5.10;


import 'ROOT/reporting/ISimpleUniverse.sol';
import 'ROOT/libraries/math/SafeMathUint256.sol';
import 'ROOT/Augur.sol';
import 'ROOT/external/IDaiVat.sol';
import 'ROOT/external/IDaiPot.sol';
import 'ROOT/external/IDaiJoin.sol';
import 'ROOT/Cash.sol';


/**
 * @title Universe
 * @notice A Universe encapsulates a whole instance of Augur. In the event of a fork in a Universe it will split into child Universes which each represent a different version of the truth with respect to how the forking market should resolve.
 */
contract SigSimpleUniverse is ISimpleUniverse {
    using SafeMathUint256 for uint256;
    uint public DAILYBLOCKRATE;

    Augur public augur;

    uint256 public totalBalance;
    Cash public cash;
    IDaiVat public daiVat;
    IDaiPot public daiPot;
    IDaiJoin public daiJoin;

    uint256 constant public DAI_ONE = 10 ** 27;

// Original code: signal DailySignal();
bytes32 private DailySignal_key;
function set_DailySignal_key() private {
    DailySignal_key = keccak256("DailySignal()");
}
////////////////////

// Original code: handler Update;
bytes32 private Update_key;
function set_Update_key() private {
    Update_key = keccak256("Update()");
}
////////////////////

    function UpdateFunc() public {
        uint DBR = DAILYBLOCKRATE;
        sweepInterest();
// Original code: DailySignal.emit().delay(DBR);
assembly {
    mstore(
        0x00,
        sigemit(
            sload(DailySignal_key.slot), 
            0,
            0,
            DBR
        )
    )
}
////////////////////
    }

    function saveDaiInDSR(uint256 _amount) public returns (bool) {
        return true;
    }

    function withdrawDaiFromDSR(uint256 _amount) public returns (bool) {
        uint256 _chi = daiPot.chi();
        if (_sDaiAmount.mul(_chi) < _amount.mul(DAI_ONE)) {
            _sDaiAmount += 1;
        }
        withdrawSDaiFromDSR(_sDaiAmount);
        return true;
    }

    function withdrawSDaiFromDSR(uint256 _sDaiAmount) public returns (bool) {
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
        _extraCash = cash.balanceOf(address(this));
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
// Original code: DailySignal.emit().delay(DBR);
assembly {
    mstore(
        0x00,
        sigemit(
            sload(DailySignal_key.slot), 
            0,
            0,
            DBR
        )
    )
}
////////////////////
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

// Original code: DailySignal.create_signal();
set_DailySignal_key();
assembly {
    mstore(0x00, createsignal(sload(DailySignal_key.slot)))
}
////////////////////
// Original code: Update.create_handler("UpdateFunc()",100000,120);
set_Update_key();
bytes32 Update_method_hash = keccak256("UpdateFunc()");
uint Update_gas_limit = 100000;
uint Update_gas_ratio = 120;
assembly {
    mstore(
        0x00, 
        createhandler(
            sload(Update_key.slot), 
            Update_method_hash, 
            Update_gas_limit, 
            Update_gas_ratio
        )
    )
}
////////////////////

        address this_address = address(this);
// Original code: Update.bind(this_address,"DailySignal()");
bytes32 Update_signal_prototype_hash = keccak256("DailySignal()");
assembly {
    mstore(
        0x00,
        sigbind(
            sload(Update_key.slot),
            this_address,
            Update_signal_prototype_hash
        )
    )
}
////////////////////
    }

}
