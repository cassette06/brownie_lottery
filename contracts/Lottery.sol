// SPDX-License-Identifier: MIT

pragma solidity ^0.6.6;
import "@chainlink/contracts/src/v0.6/interfaces/AggregatorV3Interface.sol";
// import "OpenZeppelin/openzeppelin-contracts@4.6.0/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@chainlink/contracts/src/v0.6/VRFConsumerBase.sol";

contract Lottery is Ownable,VRFConsumerBase{
    address payable[] public players;
    address payable public recentWinner;
    uint256 public randomness;
    uint256 public usdEntryFee;
    AggregatorV3Interface internal ethUsdPriceFeed;
    bytes32 public keyHash; //a way to uniquely identify the chainlink vrf node to use
    uint256 public fee;
    enum LOTTERY_STATE {
        OPEN,
        CLOSED,
        CALCULATING_WINNER
    }  //记录lottery的状态，每个状态对应一个数字，数字从0开始 enum是USER_DEFINED type in solidity
    LOTTERY_STATE public lottery_state;
    event RequestedRandomness(bytes32 requestId);





    constructor(address _priceFeedAddress,address _vrfCoordinator,address _link,uint256 _fee,bytes32 _keyHash) public VRFConsumerBase(_vrfCoordinator,_link) {
        usdEntryFee = 0.01 *(10**18); //测试就少点eth
        ethUsdPriceFeed= AggregatorV3Interface(_priceFeedAddress);
        lottery_state = LOTTERY_STATE.CLOSED;
        fee = _fee;
        keyHash=_keyHash;
    }

    function enter() public payable {
        //$50 minimum
        require(lottery_state == LOTTERY_STATE.OPEN);
        require(msg.value>=getEntranceFee(),"not enough ETH!");
        players.push(msg.sender);

    }

    function getEntranceFee() public view returns (uint256) {
        (, int256 answer, , , ) = ethUsdPriceFeed.latestRoundData();
        uint256 adjustPrice = uint256(answer)*10**10; //18 decimals
        // $50,$2000/ETH
        // 50* 1000 /2000
        // solidity没有小数 所以得乘1000(一般为10的18次方)
        
        uint256 costToEnter = (usdEntryFee *10**18)/ adjustPrice;
        return costToEnter ;
    }

    function startLottery() public onlyOwner {
        require(lottery_state ==LOTTERY_STATE.CLOSED,"cant start a new lottery yet!");
        lottery_state=LOTTERY_STATE.OPEN;
    }

    function endLottery() public onlyOwner{
        // uint256(keccak256(  //keccak256 is a hash algorithm
        //     abi.encodePacked(
        //         nonce, // nonce is predictable (aka transaction number)
        //         msg.sender,  //msg.sender is predictable
        //         block.difficulty, //can actually manipulated by a miner!
        //         block.timestamp // timestamp is predictable
        //     )
        // )) % players.length;
        lottery_state=LOTTERY_STATE.CALCULATING_WINNER;
        bytes32 requestId = requestRandomness(keyHash, fee);
        emit RequestedRandomness(requestId);
    }

    function fulfillRandomness(bytes32 _requestId, uint256 _randomness) internal override{
        require(lottery_state==LOTTERY_STATE.CALCULATING_WINNER,"you aren't there yet!");
        require(_randomness>0,"random not found");
        uint256 indexOfWinner = _randomness % players.length;
        recentWinner=players[indexOfWinner];
        recentWinner.transfer(address(this).balance);
        //RESET 
        players = new address payable[](0);
        lottery_state=LOTTERY_STATE.CLOSED;
        randomness=_randomness;
        

    }
}