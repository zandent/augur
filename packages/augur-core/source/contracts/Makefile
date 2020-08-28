remappings=ROOT/=./
opts=--abi --bin
files=$$(find . -type f -name '*.sol')

ls:
	echo ${files}

clean:
	rm -rf out/

build: clean
	mkdir -p out/
	echo solc --overwrite -o out ${remappings} ${opts} /=/ reporting/SimpleUniverse.sol reporting/SigSimpleUniverse_parsed.sol Augur.sol Cash.sol TestNetDaiVat.sol TestNetDaiPot.sol TestNetDaiJoin.sol
	solc --overwrite -o out ${remappings} ${opts} /=/ reporting/SimpleUniverse.sol TestNetDaiVat.sol TestNetDaiPot.sol TestNetDaiJoin.sol
