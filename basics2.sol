//----------------- FOUNDRY PATHWAYS AND REMAPPING
//foundry will not recognize this pathway like remix
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";
//we need to use/install the github repository https://github.com/smartcontractkit/chainlink-brownie-contracts
//on the terminal first run 
forge install smartcontractkit/chainlink-brownie-contracts --no-commit 
//can run also with latest version
forge install smartcontractkit/chainlink-brownie-contracts@1.3.0 --no-commit 

//then after installed need to redirect pathways from @chainlink to local repository installed
//means when @chainlink/contracts/ replace with lib/chainlink-brownie-contracts/contracts/src/x
remappings = [
  '@chainlink/contracts/=lib/chainlink-brownie-contracts/contracts/src/',
]


//-------------------------------TESTS-----------------------
//4 types of tests
//What can we do to work with addresses outside of our system?
//1. UNIT
//- Testing an specific part of our code

//2.Integration
// -Testing how our code works with other parts of our code.

//3.Forked 
// - Testing our code on a simulated real enviroment.

//4.Staging
// - Testing our code in a real enviroment that is not production

forge test -m nameOfTheFunction -vvv
//then it will run the test only on the fucntion we have written

//checking which parts of our codes are covered by tests 
forge coverage --fork-url $SEPOLIA_RPC_URL