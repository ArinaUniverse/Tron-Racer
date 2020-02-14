pragma solidity >=0.5.0 <0.6.0;

import "./math.sol";
import "./Manager.sol";

library Address {
    
    function isContract(address account) internal view returns (bool) {
        
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        
        assembly { codehash := extcodehash(account) }
        return (codehash != 0x0 && codehash != accountHash);
    }

    
    function toPayable(address account) internal pure returns (address payable) {
        return address(uint160(account));
    }
}

interface IHorse{
    function inqHorseBase(uint horseId) external view returns
    (uint8 avatar, uint8 DNA1, uint8 DNA2, bool gender);

    function inqHorseAbility(uint horseId) external view returns
    (uint8 rank, uint8 speed, uint8 stamina, uint8 sprintForce);

    function inqHorseStatus(uint horseId) external view returns
    (uint8 RaceTimes, bool IsRetire, uint8 BreedingTimes, uint8 BreedingCoolTime);

    function horseResult(uint horseId, uint8 typ, bool win) external;

    function levelup(uint horseId) external;

}

contract cHorse is Manager{
    address _horseAddr;

    function horesAddr() public view returns(address){
        require(_horseAddr != address(0), "It's a null address");
        return _horseAddr;
    }

    function setHorse(address addr) public onlyManager{
        _horseAddr = addr;
    }

    function inqHorseBase(uint horseId) public view returns
    (uint8 avatar, uint8 DNA1, uint8 DNA2, bool gender){
        return IHorse(horesAddr()).inqHorseBase(horseId);
    }

    function inqHorseAbility(uint horseId) public view returns
    (uint8 rank, uint8 speed, uint8 stamina, uint8 sprintForce){
        return (IHorse(horesAddr()).inqHorseAbility(horseId));
    }
}

contract race_base is cHorse, math{

    using Address for address;
    using Sort for uint[];

    mapping(address => game) games;

    function() external payable{}

    struct game{
        uint raceDistance;
        uint typ;
        uint[] horses; //Horses's No
        uint[] odds; //Horses's odds
        uint value; //Bet value
        uint8 betNo; //Bet No
        uint randSeed; //Random seed of the race
        uint blockNumber; //The block when start
    }

    function clear(game storage g) internal{
        g.raceDistance = 0;
        delete g.horses;
        g.value = 0;
        g.betNo = 0;
        g.randSeed = 0;
        g.blockNumber = 0;
    }
    
    function randomHorse() internal view returns(uint){
        return range(rand(), 0, 1000000);
    }

    function Odds(uint[] memory h) internal view returns(uint[] memory){
        uint n = h.length;
        uint[] memory RaceAbility = new uint[](n);
        for (uint i = 0; i < n; i++){
            (, uint8 speed, uint8 stamina, uint8 sprintForce) = inqHorseAbility(h[i]);
            RaceAbility[i] = uint(speed) * 5 + uint(stamina) * 2 + uint(sprintForce) * 5;
        }

        uint[] memory rank = RaceAbility.ranking();
        uint[] memory odds = new uint[](n);

        for (uint i = 0; i < rank.length; i++){
            if(i == 0){
                odds[rank[i]] = Random(110, 150);
            }else if(i == 1){
                odds[rank[i]] = Random(160, 200);
            }else if(i == 2){
                odds[rank[i]] = Random(210, 350);
            }else if(i == 3){
                odds[rank[i]] = Random(260, 450);
            }else if(i == 4){
                odds[rank[i]] = Random(310, 550);
            }else if(i == 5){
                odds[rank[i]] = Random(410, 750);
            }else if(i == 6){
                odds[rank[i]] = Random(610, 1000);
            }else if(i == 7){
                odds[rank[i]] = Random(810, 1500);
            }else{
                revert("Odd error");
            }
        }

        return odds;

    }

    // function _gameInfo(address player) internal view returns(
    //     uint16 raceDistance, uint value, uint8 horsesAmount, uint8 betNo){
    //     uint8 _horsesAmount = uint8(games[player].horses.length);
    //     return (games[player].raceDistance, games[player].value, _horsesAmount, games[player].betNo);
    // }

    function _endRace(uint horseId, bool win, uint8 typ) internal{
        IHorse(horesAddr()).horseResult(horseId, typ, win);
    }

    event EndGame(address indexed player, bool result);

    ////////////////////////////////////inquire function////////////////////////////////

    function inqGameInfo(address player) public view returns(
        uint raceDistance, uint value, uint8 horsesAmount, uint8 betNo){
        uint8 _horsesAmount = uint8(games[player].horses.length);
        return (games[player].raceDistance, games[player].value, _horsesAmount, games[player].betNo);
    }

    function inqOdds(address player, uint NO) public view returns(uint){
        uint horseAmount = games[player].horses.length;
        require(NO <= horseAmount || NO != 0, "No number error");
        return games[player].odds[NO.sub(1)];
    }

    function inqRaceHorsesId(address player, uint8 NO) public view returns(uint){
        uint horseAmount = games[player].horses.length;
        require(NO <= horseAmount || NO != 0, "No number error");
        return games[player].horses[NO.sub(1)];
    }

}