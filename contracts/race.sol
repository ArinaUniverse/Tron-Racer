pragma solidity >=0.5.0 <0.6.0;

import "./race_base.sol";

library useDecimal{
    using uintTool for uint;

    function m278(uint n) internal pure returns(uint){
        return n.mul(278)/1000;
    }
}

library raceTime {

    struct horsesTime{ //Horses's timeA, timeB and timeB
        uint[] timeA;
        uint[] timeB;
        uint[] timeC;
        bool _timeA;
        bool _timeB;
        bool _timeC;
    }
    function init(horsesTime storage hT) internal{
        hT._timeA = false;
        hT._timeB = false;
        hT._timeC = false;
    }

    function set(horsesTime storage hT, uint index, uint[] memory newhT) internal{
        
        if(index == 1){
            hT.timeA = newhT;
            hT._timeA = true;
        }else if(index == 2){
            hT.timeB = newhT;
            hT._timeB = true;
        }else if(index == 3){
            hT.timeC = newhT;
            hT._timeC = true;
        }else{
            revert("Set error");
        }
    }

    function check(horsesTime storage hT, uint index) internal view returns(bool){
        if(index == 1){
            return hT._timeA;
        }else if(index == 2){
            return hT._timeB;
        }else if(index == 3){
            return hT._timeC;
        }else{
            revert("Check error");
        }
    }

    function inquire(horsesTime storage hT, uint index) internal view returns(uint[] memory){
        if(index == 1){
            require(hT._timeA, "TimeA is not exist");
            return hT.timeA;
        }else if(index == 2){
            require(hT._timeB, "TimeB is not exist");
            return hT.timeB;
        }else if(index == 3){
            require(hT._timeC, "TimeC is not exist");
            return hT.timeC;
        }else{
            revert("Inquire error");
        }
    }

}

contract race is race_base{
    using uintTool for uint;
    using useDecimal for uint;
    using raceTime for raceTime.horsesTime;

    mapping(address => raceTime.horsesTime) horsesTime;

//=========================Play game function======================

    function generateRace(uint trackLength, uint horseId) external{
        (, bool IsRetire, uint8 BreedingTimes,,) = inqHorseStatus(horseId);
        require(!IsRetire || BreedingTimes >= 0, "This horse can't join race");
        require((ownerOf(horseId) == msg.sender) || (horseId == 0), "You can't use this horse");
        uint distance;
        if(trackLength == 1){
            distance = 1200;
        }else if(trackLength == 2){
            distance = 1800;
        }else if(trackLength == 3){
            distance = 2400;
        }else if(trackLength == 4){
            distance = 3200;
        }else{
            revert("You choose a error type");
        }

        uint[] memory newHorses = new uint[](8);
        // horsesTime[msg.sender].set(1, newHorses);
        // horsesTime[msg.sender].set(2, newHorses);
        // horsesTime[msg.sender].set(3, newHorses);
        horsesTime[msg.sender].init;

        uint r = rand(0, 7);
        
        for (uint8 i = 0; i < 8; i++) {
            
            if(i == r && (horseId != 0)){
                newHorses[i] = horseId;
            }else{
                newHorses[i] = randomHorse();
            }
        }

        games[msg.sender].raceDistance = distance;
        games[msg.sender].horses = newHorses;
        games[msg.sender].odds = Odds(newHorses);
        

    }

    function startRace(uint8 NO) external payable{ //BetValue is decided by 'msg.value'.
        uint horseAmount = games[msg.sender].horses.length;
        require(NO <= horseAmount || NO != 0, "No number error");

        require(games[msg.sender].raceDistance != 0, "You need to call generateRace first");
        require(msg.value >= 50 trx && msg.value <= 1000 trx, "Value error");

        games[msg.sender].betNo = NO;
        games[msg.sender].value = msg.value;
        games[msg.sender].randSeed = rand(0, 1.15e77);
        games[msg.sender].blockNumber = block.number;
        horsesTime[msg.sender].set(1, _calculateTime(msg.sender, 1));
    }
 
    function endGame() external{ //需要重置避免重複調用
        // horsesTime[msg.sender].set(2, _calculateTime(msg.sender, 2));
        // horsesTime[msg.sender].set(3, _calculateTime(msg.sender, 3));
        
        uint winer = inqResult(msg.sender)[0];

        require(games[msg.sender].value != 0, "You can't use this function");
        require(winer != 0, "The champion has not yet decided");
        (,uint value,, uint8 betNO) = inqGameInfo(msg.sender);

        uint[] memory h = games[msg.sender].horses;

        uint id;
        for (uint8 i = 1; i <= h.length; i++) {
            id = inqRaceHorsesId(msg.sender, i);
            if(winer == i){
                _endRace(id, true, 0);
            }else{
                //_endRace(id, false, 0);
            }
        }

        if(betNO == winer){
            clear(games[msg.sender]);
            uint odds = inqOdds(msg.sender, winer);
            (msg.sender).transfer(value.percent(odds));  //Player win!!!
            emit EndGame(msg.sender, true);
        }else{
            clear(games[msg.sender]);
            emit EndGame(msg.sender, false); //Player lose!!!
        }
    }

//=================================================================

    function inqResult(address player) public view returns(uint[] memory){ //Inquire champion
        uint amount = games[player].horses.length;
        uint[] memory r = new uint[](amount);
        r = _raceRank(player);
        if(block.number > games[player].blockNumber + 1){
            for (uint i = 0; i < amount; i++) {
                r[i] = r[i] + 1;
            }
            return r;
        }
        else{
            revert("Result is not determined");
        }
    }

    function arrayAdd(uint[] memory a, uint[] memory b) public pure returns(uint[] memory){
        require(a.length == b.length, "Array length are not equal");
        for (uint i = 0; i < a.length; i++) {
            a[i] = a[i].add(b[i]);
        }
        return a;
    }

    function inqTime(address player, uint index) public view returns(uint[] memory){
        if(horsesTime[player].check(index)){
            return horsesTime[player].inquire(index);
        }else{
            return _calculateTime(player, index);
        }
    }

    // function ttt(address player) public view returns(uint[] memory){
    //     uint amount = games[player].horses.length;
    //     // uint trackLength = D2LT(games[player].raceDistance);
    //     // uint8 gameTyp = 0; //一般賽

    //     uint[] memory totHorseTime = new uint[](amount);
        
    //     for (uint i = 1; i <= 3; i++) {
    //         if(horsesTime[player].check(i)){
    //             totHorseTime = arrayAdd(totHorseTime, horsesTime[player].inquire(i));
    //         }else{
    //             totHorseTime = arrayAdd(totHorseTime, _calculateTime(player, i));
    //         }
            
    //     }
    //     return totHorseTime;
    // }

    function _raceRank(address player) private view returns(uint[] memory){
        uint amount = games[player].horses.length;
        // uint trackLength = D2LT(games[player].raceDistance);
        // uint8 gameTyp = 0; //一般賽

        uint[] memory totHorseTime = new uint[](amount);
        
        for (uint i = 1; i <= 3; i++) {
            if(horsesTime[player].check(i)){
                totHorseTime = arrayAdd(totHorseTime, horsesTime[player].inquire(i));
            }else{
                totHorseTime = arrayAdd(totHorseTime, _calculateTime(player, i));
            }
            
        }
        
        return totHorseTime.ranking_();
    }


//==========================Calculate time for runinng ======================

    function _calculateTime(address player, uint index) internal view returns(uint[] memory){

        uint amount = games[player].horses.length;
        uint trackLength = D2LT(uint(games[player].raceDistance));
        uint _block = games[player].blockNumber;
        require(_block != 0, "Block error");

        uint[] memory r = new uint[](amount);

        for (uint8 i = 0; i < amount; i++) {
            if(index == 1){
                r[i] = timeA(inqRaceHorsesId(player, i+1), _block, trackLength, 0);
            }else if(index == 2){
                r[i] = timeB(inqRaceHorsesId(player, i+1), _block, trackLength, 0);
            }else if(index == 3){
                r[i] = timeC(inqRaceHorsesId(player, i+1), _block, trackLength, 0);
            }else{
                revert("Calculate error");
            }
        }
        return r;
    }

    function timeA(uint horseId, uint _block, uint trackLength, uint8 gameTyp) private view returns(uint){

        (,uint Speed,, uint Sprint) = inqHorseAbility(horseId);

        (,uint DNA1,,) = inqHorseBase(horseId);

        uint distance = LT2D(trackLength);

        uint constD = (distance/3).div(Speed.m278()).mul(1000);

        require(constD != 0, "constD == 0");

        if (trackLength <= 2)  //1200M和1800M
        {
            if (DNA1 == 1)
            {
                return constD * (100 - _random(_block, 0, Sprint.percent(150))) / 100;
            }
            else if (DNA1 == 4)
            {
                return constD * (100 - _random(_block, 0, Sprint.percent(120))) / 100;
            }
            else
            {
                if ((DNA1 == 6 && gameTyp == 1) || (DNA1 == 7 && gameTyp == 2) )
                {
                    return (constD * (100 - _random(_block, 0, Sprint)) / 100).percent(95);
                }
                else if ((DNA1 == 8 && gameTyp == 3) || (DNA1 == 9 && gameTyp == 0))
                {
                    return (constD * (100 - _random(_block, 0, Sprint)) / 100).percent(95);
                }
                else if (DNA1 == 10)
                {
                    return (constD * (100 - _random(_block, 0, Sprint)) / 100).percent(98);
                }
                else
                {
                    return constD * (100 - _random(_block, 0, Sprint)) / 100;
                }

            }
        }
        else   //2400M和3200M
        {
            if (DNA1 == 1)
            {
                return constD * (100 - _random(_block, 0, Sprint.percent(130))) / 100;
            }
            else if (DNA1 == 4)
            {
                return constD * (100 - _random(_block, 0, Sprint.percent(110))) / 100;
            }
            else
            {
                if ((DNA1 == 6 && gameTyp == 1) || (DNA1 == 7 && gameTyp == 2))
                {
                    return (constD * (100 - _random(_block, 0, Sprint)) / 100).percent(95);
                }
                else if ((DNA1 == 8 && gameTyp == 3) || (DNA1 == 9 && gameTyp == 0))
                {
                    return (constD * (100 - _random(_block, 0, Sprint)) / 100).percent(95);
                }
                else if (DNA1 == 10)
                {
                    return (constD * (100 - _random(_block, 0, Sprint)) / 100).percent(98);
                }
                else
                {
                    return constD * (100 - _random(_block, 0, Sprint)) / 100;
                }
            }
        }
    }

    function timeB(uint horseId, uint _block, uint trackLength, uint8 gameTyp) private view returns(uint){

        (,uint Speed, uint stamina,) = inqHorseAbility(horseId);

        (,uint DNA1,,) = inqHorseBase(horseId);

        uint distance = LT2D(trackLength);

        uint constD = (distance/3).div(Speed.m278()).mul(1000);

        require(constD != 0, "constD == 0");

        if (trackLength == 1)  //1200M
        {
            if (DNA1 == 1)
            {
                return constD.percent(_random(_block, 95, 100));
            }
            else if (DNA1 == 4)
            {
                return constD.percent(_random(_block, 98, 100));
            }
            else{

                if ((DNA1 == 6 && gameTyp == 1) || (DNA1 == 7 && gameTyp == 2))
                {
                    return constD.percent(95);
                }
                else if((DNA1 == 8 && gameTyp == 3) || (DNA1 == 9 && gameTyp == 0))
                {
                    return constD.percent(95);
                }
                else if (DNA1 == 10)
                {
                    return constD.percent(98);
                }
                else
                {
                    return constD;
                }
            }
        }
        else if(trackLength == 2)  //1800M
        {
            if (DNA1 == 1 || DNA1 == 2 || DNA1 == 4)
            {
                return constD.percent(_random(_block, 98, 100));
            }
            else
            {
                if (DNA1 == 6 && gameTyp == 1)
                {
                    return constD.percent(95);
                }
                else if (DNA1 == 7 && gameTyp == 2)
                {
                    return constD.percent(95);
                }
                else if (DNA1 == 8 && gameTyp == 3)
                {
                    return constD.percent(95);
                }
                else if (DNA1 == 9 && gameTyp == 0)
                {
                    return constD.percent(95);
                }
                else if (DNA1 == 10)
                {
                    return constD.percent(98);
                }
                else
                {
                    return constD;
                }
            }
        }
        else if (trackLength == 3)  //2400M
        {
            if (stamina < 30)
            {
                if (DNA1 == 2 || DNA1 == 3 || DNA1 == 4)
                {
                    return constD.percent(_random(_block, 98, 100)) * (100 - (30 - stamina)) / 100;
                }
                else
                {
                    if ((DNA1 == 6 && gameTyp == 1) || (DNA1 == 7 && gameTyp == 2))
                    {
                        return constD.percent(95) * (100 - (30 - stamina)) / 100;
                    }
                    else if ((DNA1 == 8 && gameTyp == 3) || (DNA1 == 9 && gameTyp == 0))
                    {
                        return constD.percent(95) * (100 - (30 - stamina)) / 100;
                    }
                    else if (DNA1 == 10)
                    {
                        return constD.percent(98) * (100 - (30 - stamina)) / 100;
                    }
                    else
                    {
                        return constD * (100 - (30 - stamina)) / 100;
                    }
                }
            }
            else
            {
                if (DNA1 == 2 || DNA1 == 3 || DNA1 == 4)
                {
                    return constD.percent(_random(_block, 98, 100));
                }
                else
                {
                    if ((DNA1 == 6 && gameTyp == 1) || (DNA1 == 7 && gameTyp == 2))
                    {
                        return constD.percent(95);
                    }
                    else if ((DNA1 == 8 && gameTyp == 3 ) || (DNA1 == 9 && gameTyp == 0) )
                    {
                        return constD.percent(95);
                    }
                    else if (DNA1 == 10)
                    {
                        return constD.percent(98);
                    }
                    else
                    {
                        return constD;
                    }
                }
            }
        }
        else if (trackLength == 4)  //3200M
        {
            if (stamina < 40)
            {
                if (DNA1 == 3 || DNA1 == 4)
                {
                    return constD.percent(_random(_block, 98, 100)) * (100 - (40 - stamina)) / 100;
                }
                else
                {
                    if ((DNA1 == 6 && gameTyp == 1) || ((DNA1 == 7 && gameTyp == 2)))
                    {
                        return constD.percent(95) * (100 - (40 - stamina)) / 100;
                    }
                    else if ((DNA1 == 8 && gameTyp == 3) || (DNA1 == 9 && gameTyp == 0))
                    {
                        return constD.percent(95) * (100 - (40 - stamina)) / 100;
                    }
                    else if (DNA1 == 10)
                    {
                        return constD.percent(98) * (100 - (40 - stamina)) / 100;
                    }
                    else
                    {
                        return constD * (100 - (40 - stamina)) / 100;
                    }
                }
            }
            else
            {
                if (DNA1 == 3 || DNA1 == 4)
                {
                    return constD.percent(_random(_block, 98, 100));
                }
                else{

                    if ((DNA1 == 6 && gameTyp == 1) || (DNA1 == 7 && gameTyp == 2))
                    {
                        return constD.percent(95);
                    }
                    else if ((DNA1 == 8 && gameTyp == 3) || (DNA1 == 9 && gameTyp == 0))
                    {
                        return constD.percent(95);
                    }
                    else if (DNA1 == 10)
                    {
                        return constD.percent(98);
                    }
                    else
                    {
                        return constD;
                    }
                }
            }
        }
    }

    function timeC(uint horseId, uint _block, uint trackLength, uint8 gameTyp) private view returns(uint){
        
        (,uint Speed, uint stamina,) = inqHorseAbility(horseId);

        (,uint DNA1,,) = inqHorseBase(horseId);

        uint distance = LT2D(trackLength);

        uint constD = (distance/3).div(Speed.m278()).mul(1000);
        require(constD != 0, "constD == 0");

        if (trackLength == 1)  //1200M
        {
            if (stamina < 30)
            {
                if (DNA1 == 1)
                {
                    return constD.percent(_random(_block, 95, 100)) * (100 + (30 - stamina)) / 100;
                }
                else if (DNA1 == 4)
                {
                    return constD.percent(_random(_block, 98, 100)) * (100 + (30 - stamina)) / 100;
                }
                else if (DNA1 == 5)
                {
                    return constD.percent(_random(_block, 90, 110)) * (100 + (30 - stamina)) / 100;
                }
                else
                {
                    if ((DNA1 == 6 && gameTyp == 1) || (DNA1 == 7 && gameTyp == 2))
                    {
                        return constD.percent(95) * (100 + (30 - stamina)) / 100;
                    }
                    else if ((DNA1 == 8 && gameTyp == 3) || (DNA1 == 9 && gameTyp == 0))
                    {
                        return constD.percent(95) * (100 + (30 - stamina)) / 100;
                    }
                    else if (DNA1 == 10)
                    {
                        return constD.percent(98) * (100 + (30 - stamina)) / 100;
                    }
                    else
                    {
                        return constD * (100 + (30 - stamina)) / 100;
                    }
                }
            }
            else
            {
                if (DNA1 == 1)
                {
                    return constD.percent(_random(_block, 95, 100));
                }
                else if (DNA1 == 4)
                {
                    return constD.percent(_random(_block, 98, 100));
                }
                else if (DNA1 == 5)
                {
                    return constD.percent(_random(_block, 90, 110));
                }
                else
                {
                    if ((DNA1 == 6 && gameTyp == 1) || (DNA1 == 7 && gameTyp == 2))
                    {
                        return constD.percent(95);
                    }
                    else if ((DNA1 == 8 && gameTyp == 3) || (DNA1 == 9 && gameTyp == 0))
                    {
                        return constD.percent(95);
                    }
                    else if (DNA1 == 10)
                    {
                        return constD.percent(98);
                    }
                    else
                    {
                        return constD;
                    }
                }
            }
        }
        else if(trackLength == 2)  //1800M
        {
            if (stamina < 40)
            {
                if (DNA1 == 1 || DNA1 == 2 || DNA1 == 4)
                {
                    return constD.percent(_random(_block, 98, 100)) * (100 + (40 - stamina)) / 100;
                }
                else if (DNA1 == 5)
                {
                    return constD.percent(_random(_block, 90, 110)) * (100 + (40 - stamina)) / 100;
                }
                else
                {
                    if (DNA1 == 6 && gameTyp == 1)
                    {
                        return constD.percent(95) * (100 + (40 - stamina)) / 100;
                    }
                    else if (DNA1 == 7 && gameTyp == 2)
                    {
                        return constD.percent(95) * (100 + (40 - stamina)) / 100;
                    }
                    else if (DNA1 == 8 && gameTyp == 3)
                    {
                        return constD.percent(95) * (100 + (40 - stamina)) / 100;
                    }
                    else if (DNA1 == 9 && gameTyp == 0)
                    {
                        return constD.percent(95) * (100 + (40 - stamina)) / 100;
                    }
                    else if (DNA1 == 10)
                    {
                        return constD.percent(98) * (100 + (40 - stamina)) / 100;
                    }
                    else
                    {
                        return constD * (100 + (40 - stamina)) / 100;
                    }
                }
            }
            else{

                if (DNA1 == 1 || DNA1 == 2 || DNA1 == 4)
                {
                    return constD.percent(_random(_block, 98, 100));
                }
                else if (DNA1 == 5)
                {
                    return constD.percent(_random(_block, 90, 110));
                }
                else
                {
                    if ((DNA1 == 6 && gameTyp == 1) || (DNA1 == 7 && gameTyp == 2))
                    {
                        return constD.percent(95);
                    }
                    else if ((DNA1 == 8 && gameTyp == 3) || (DNA1 == 9 && gameTyp == 0))
                    {
                        return constD.percent(95);
                    }
                    else if (DNA1 == 10)
                    {
                        return constD.percent(98);
                    }
                    else
                    {
                        return constD;
                    }
                }
            }
        }
        else if (trackLength == 3)  //2400M
        {
            if (stamina < 50)
            {
                if (DNA1 == 2 || DNA1 == 3 || DNA1 == 4)
                {
                    return constD.percent(_random(_block, 98, 100)) * (100 + (50 - stamina)) / 100;
                }
                else if (DNA1 == 5)
                {
                    return constD.percent(_random(_block, 85, 110)) * (100 + (50 - stamina)) / 100;
                }
                else
                {
                    if ((DNA1 == 6 && gameTyp == 1) || (DNA1 == 7 && gameTyp == 2))
                    {
                        return constD.percent(95) * (100 + (50 - stamina)) / 100;
                    }
                    else if ((DNA1 == 8 && gameTyp == 3) || (DNA1 == 9 && gameTyp == 0) || DNA1 == 10)
                    {
                        return constD.percent(95) * (100 + (50 - stamina)) / 100;
                    }
                    else
                    {
                        return constD * (100 + (50 - stamina)) / 100;
                    }
                }
            }
            else
            {
                if (DNA1 == 2 || DNA1 == 3 || DNA1 == 4)
                {
                    return constD.percent(_random(_block, 98, 100));
                }
                else if (DNA1 == 5)
                {
                    return constD.percent(_random(_block, 85, 110));
                }
                else
                {
                    if ((DNA1 == 6 && gameTyp == 1) || (DNA1 == 7 && gameTyp == 2))
                    {
                        return constD.percent(95);
                    }
                    else if ((DNA1 == 8 && gameTyp == 3) || (DNA1 == 9 && gameTyp == 0))
                    {
                        return constD.percent(95);
                    }
                    else if (DNA1 == 10)
                    {
                        return constD.percent(98);
                    }
                    else
                    {
                        return constD;
                    }
                }
            }
        }
        else if (trackLength == 4)  //3200M
        {
            if (stamina < 60)
            {
                if (DNA1 == 3)
                {
                    return constD.percent(_random(_block, 95, 100)) * (100 + (60 - stamina)) / 100;
                }
                else if (DNA1 == 4)
                {
                    return constD.percent(_random(_block, 98, 100)) * (100 + (60 - stamina)) / 100;
                }
                else if (DNA1 == 5)
                {
                    return constD.percent(_random(_block, 80, 110)) * (100 + (60 - stamina)) / 100;
                }
                else
                {
                    if ((DNA1 == 6 && gameTyp == 1) || (DNA1 == 7 && gameTyp == 2))
                    {
                        return constD.percent(95) * (100 + (60 - stamina)) / 100;
                    }
                    else if ((DNA1 == 8 && gameTyp == 3) || (DNA1 == 9 && gameTyp == 0))
                    {
                        return constD.percent(95) * (100 + (60 - stamina)) / 100;
                    }
                    else if (DNA1 == 10)
                    {
                        return constD.percent(98) * (100 + (60 - stamina)) / 100;
                    }
                    else
                    {
                        return constD * (100 + (60 - stamina)) / 100;
                    }
                }
            }
            else
            {
                if (DNA1 == 3 || DNA1 == 4)
                {
                    return constD.percent(_random(_block, 98, 100)) * (500 - (stamina - 60)) / 500;
                }
                else if (DNA1 == 5)
                {
                    return constD.percent(_random(_block, 80, 110)) * (500 - (stamina - 60)) / 500;
                }
                else
                {
                    if ((DNA1 == 6 && gameTyp == 1) || (DNA1 == 7 && gameTyp == 2))
                    {
                        return constD.percent(95) * (500 - (stamina - 60)) / 500;
                    }
                    else if ((DNA1 == 8 && gameTyp == 3) || (DNA1 == 9 && gameTyp == 0))
                    {
                        return constD.percent(95) * (500 - (stamina - 60)) / 500;
                    }
                    else if (DNA1 == 10)
                    {
                        return constD.percent(98) * (500 - (stamina - 60)) / 500;
                    }
                    else
                    {
                        return constD * (500 - (stamina - 60)) / 500;
                    }
                }
            }
        }
    }

    function _random(uint _block, uint bottom, uint top) private view returns(uint){
        bytes32 _hash = blockhash(_block);
        bytes memory seed = abi.encodePacked(games[msg.sender].randSeed, _hash);
        return rand(seed, bottom, top);
    }

    function LT2D(uint trackLength) private pure returns(uint distance){
         if(trackLength == 1){
            distance = 1200;
        }else if(trackLength == 2){
            distance = 1800;
        }else if(trackLength == 3){
            distance = 2400;
        }else if(trackLength == 4){
            distance = 3200;
        }else{
            revert("TrackLength error type");
        }
    }

    function D2LT(uint raceDistance) private pure returns(uint trackLength){
        if(raceDistance == 1200){
            trackLength = 1;
        }else if(raceDistance == 1800){
            trackLength = 2;
        }else if(raceDistance == 2400){
            trackLength = 3;
        }else if(raceDistance == 3200){
            trackLength = 4;
        }else{
            revert("RaceDistance error type");
        }
    }
}