pragma solidity >=0.5.10;

import 'ROOT/external/IDaiJoin.sol';
import 'ROOT/TestNetDaiVat.sol';
import 'ROOT/Cash.sol';


contract TestNetDaiJoin is IDaiJoin {
    TestNetDaiVat public vat;
    Cash public dai;

    uint constant ONE = 10 ** 27;

    constructor(address vat_, address dai_) public {
        vat = TestNetDaiVat(vat_);
        dai = Cash(dai_);
    }

    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x);
    }

    function join(address urn, uint wad) public {
        vat.move(address(this), urn, mul(ONE, wad));
        dai.joinBurn(msg.sender, wad);
    }

    function exit(address usr, uint wad) public {
        address urn = msg.sender;
        vat.move(urn, address(this), mul(ONE, wad));
        dai.joinMint(usr, wad);
    }
}