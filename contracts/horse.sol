pragma solidity >=0.5.1 <0.6.0;
// pragma experimental ABIEncoderV2;

import "./ERC721.sol";
import "./Manager.sol";

library Horses {

    struct Horse{
        Ability ability;
        Base base;
        Record record;
        Status status;
        History history;
        Initial initial;
    }

    struct Initial{
        bool ability;
        bool base;
        bool record;
        bool status;
    }

    struct Ability{
        uint8 rank; //等級,會隨場次增加
        uint8 speed; //速度
        uint8 stamina; //耐力
        uint8 sprintForce; //衝刺力
    }

    struct Base{
        uint8 avatar; //馬外觀
        uint8 DNA1;
        uint8 DNA2;
        bool gender; //性別
    }

    struct Record{
        uint bloodlineA; //紀錄該馬的父馬編號(創世馬皆為0)
        uint bloodlineB; //紀錄該馬的母馬編號(創世馬皆為0)

        uint salePrice;  //出售價格 生成時有一個初始值公式,也可以透過命令自行修改
        bool isForSale;  //創世馬預設為True, true=可以直接購買 /false=不販售
        uint studFee; //公馬配種費用,玩家可以自行設定,0為不開放配種(預設),設定0以上費用,所有玩家都可以付費配種
    }

    struct Status{
        uint8 raceTimes; //可參與比賽次數,會隨每場比賽-1(initial:11~100)
        bool isRetire; //是否退役，初始值為false，選擇退役後則為true，退役後才能配種
        uint8 breedingTimes; //公馬、母馬可配種次數，歸零後便無法配種(initial:1~10)
        uint breedingCoolTime; //配種冷卻時間，母馬配種後需24小時冷卻(公馬沒有冷卻時間)
        uint exp;
    }

    struct History{
        uint16 G1_Win;  //初始值為0
        uint16 G2_Win;  //初始值為0
        uint16 G3_Win;  //初始值為0
        uint16 normal_Win;  //初始值為0
        uint16 race_Lose;  //初始值為0
    }

/////////////////////////////////_set////////////////////////////////////

    function set_ability(Horse storage h, Ability memory ability) internal{

        if(!h.initial.ability){
            h.initial.ability = true;
        }
        h.ability = ability;
    }

    function _set_base(Horse storage h, Base memory base) internal{

        if(!h.initial.base){
            h.initial.base = true;
        }
        h.base = base;
    }

    function set_record(Horse storage h, Record memory record) internal{

        if(!h.initial.record){
            h.initial.record = true;
        }
        h.record = record;
    }

    function set_status(Horse storage h, Status memory status) internal{
        if(!h.initial.status){
            h.initial.status = true;
        }
        h.status = status;
    }

}

/*====================================================================================
                                Horse Contract
====================================================================================*/

contract newHorse is Manager, ERC721{

    using Horses for Horses.Horse;
    using Horses for Horses.Ability;
    using Horses for Horses.Base;
    using Horses for Horses.Record;
    using Horses for Horses.Status;
    using Horses for Horses.History;

    mapping (uint => Horses.Horse) horses;

    using Address for address;
    uint createId;
    uint initAmount = 1000000;

    address _race;

    constructor() public{
        createId = initAmount.add(1);
        _ownedTokensCount[address(this)].setBalance(1000000);
    }

    modifier onlyHorseOwner(uint horseId){
        require(ownerOf(horseId) == msg.sender, "You are not owner of the horse");
        _;
    }

    function setRace(address _address) public onlyManager{
        _race = _address;
    }

    function race() public view returns(address){
        require(_race != address(0), "Race contract address is null");
        return _race;
    }

    modifier onlyRace{
        require(msg.sender == race(), "yor are not race contract");
        _;
    }

    function linearTransfrom(uint oringinMax, uint nowMax, uint number) private pure returns(uint){
        return number.mul(nowMax).div(oringinMax);
    }
    
////////////////////////////////_init////////////////////////////////////

    function _initBase(uint horseId) private pure returns(Horses.Base memory){
        return Horses.Base(
            toUint8(rand(abi.encodePacked(horseId, "avatar"), 1, 20)), //avatar
            toUint8(rand(abi.encodePacked(horseId, "DNA1"), 0, 10)), //DNA1
            toUint8(rand(abi.encodePacked(horseId, "DNA2"), 0, 10)), //DNA2
            rand(abi.encodePacked(horseId, "gender"), 0, 9) > 4 //gender
            );
    }

    function _initAbility(uint horseId) private pure returns(Horses.Ability memory){

        uint _speed = rand(abi.encodePacked(horseId, "speed"), 50, 100);
        uint _stamina = rand(abi.encodePacked(horseId, "stamina"), 20, 100);
        uint _sprintForce = rand(abi.encodePacked(horseId, "sprint"), 0, 10);

        uint raceTimes = _init_raceTimes(horseId);

        if(11 <= raceTimes || raceTimes <= 20){
            _speed = _speed.add(9);
            _stamina = _stamina.add(9);
        }else if(21 <= raceTimes || raceTimes <= 30){
            _speed = _speed.add(8);
            _stamina = _stamina.add(8);
        }else if(31 <= raceTimes || raceTimes <= 40){
            _speed = _speed.add(7);
            _stamina = _stamina.add(7);
        }else if(41 <= raceTimes || raceTimes <= 50){
            _speed = _speed.add(6);
            _stamina = _stamina.add(6);
        }else if(51 <= raceTimes || raceTimes <= 60){
            _speed = _speed.add(5);
            _stamina = _stamina.add(5);
        }else if(61 <= raceTimes || raceTimes <= 70){
            _speed = _speed.add(4);
            _stamina = _stamina.add(4);
        }else if(71 <= raceTimes || raceTimes <= 80){
            _speed = _speed.add(3);
            _stamina = _stamina.add(3);
        }else if(81 <= raceTimes || raceTimes <= 90){
            _speed = _speed.add(2);
            _stamina = _stamina.add(2);
        }else if(91 <= raceTimes || raceTimes <= 100){
            _speed = _speed.add(1);
            _stamina = _stamina.add(1);
        }
        
        uint sum = _speed.add(_stamina).add(_sprintForce);

        if(_speed > 70){
            uint speed = linearTransfrom(sum, 110, uint(_speed));
            uint stamina = linearTransfrom(sum, 110, uint(_stamina));
            uint sprintForce = linearTransfrom(sum, 110, uint(_sprintForce));
            return Horses.Ability(0, toUint8(speed), toUint8(stamina),
                toUint8(sprintForce));

        }else if(sum > 120){
            uint speed = linearTransfrom(sum, 120, uint(_speed));
            uint stamina = linearTransfrom(sum, 120, uint(_stamina));
            uint sprintForce = linearTransfrom(sum, 120, uint(_sprintForce));

            return Horses.Ability(0, toUint8(speed), toUint8(stamina), toUint8(sprintForce));
        }
        else{
            return Horses.Ability(0, toUint8(_speed), toUint8(_stamina), toUint8(_sprintForce));
        }
    }

    function _initRecord(uint horseId) private view returns(Horses.Record memory){
        uint salePrice;
        Horses.Ability memory a = horseAbility(horseId);
        uint rateA = (uint(a.speed).mul(5)).add(uint(a.stamina).mul(2)).add(uint(a.sprintForce).mul(5)/10);
        bool isForSale = true;

        if(a.speed >= 80){
            salePrice = rateA.mul(6);
            isForSale = false;
        }else if(a.speed >= 70 && a.speed < 80){
            salePrice = rateA.mul(5);
            isForSale = false;
        }else if(a.speed >= 60 && a.speed < 70){
            salePrice = rateA.mul(4);
        }else if(a.speed >= 50 && a.speed < 60){
            salePrice = rateA.mul(3);
        }else{
            salePrice = rateA.mul(2);
        }
        
        return Horses.Record(0, 0, salePrice, isForSale, 0);
    }

    function _initStatus(uint horseId) private view returns(Horses.Status memory){
        uint8 breedingTimes;
        if(_initBase(horseId).gender){
            breedingTimes = uint8(rand(20, 100));
        }else{
            breedingTimes = uint8(rand(1, 10));
        }
        return Horses.Status(_init_raceTimes(horseId), false, breedingTimes, 0, 0);
    }

    function _init_raceTimes(uint horseId) private pure returns(uint8){
            bytes memory seed = abi.encodePacked(horseId);
            uint raceTime = rand(seed, 11, 100);
            return toUint8(raceTime);
    }

    
////////////////////////////////inquire//////////////////////////////////
    
    function horseAbility(uint horseId) private view returns(Horses.Ability memory){
        //require(exist(horseId), "Horse is not exist");
        if(!horses[horseId].initial.ability && horseId <= initAmount){
            return _initAbility(horseId);
        }else{
            return horses[horseId].ability;
        }
    }

    function horseBase(uint horseId) private view returns(Horses.Base memory){
        //require(exist(horseId), "Horse is not exist");
        if(!horses[horseId].initial.base && horseId <= initAmount){
            return _initBase(horseId);
        }else{
            return horses[horseId].base;
        }
    }

    function horseRecord(uint horseId) private view returns(Horses.Record memory){
        //require(exist(horseId), "Horse is not exist");
        if(!horses[horseId].initial.record && horseId <= initAmount){
            return _initRecord(horseId);
        }else{
            return horses[horseId].record;
        }
    }

    function horseStatus(uint horseId) private view returns(Horses.Status memory){
        //require(exist(horseId), "Horse is not exist");
        if(!horses[horseId].initial.status && horseId <= initAmount){
            return _initStatus(horseId);
        }else{
            return horses[horseId].status;
        }
    }

    function horseHistory(uint horseId) private view returns(Horses.History memory){
        //require(exist(horseId), "Horse is not exist");
        return horses[horseId].history;
    }

    ////////////////////external inquire/////////////////////

    function inqHorseAbility(uint horseId) external view returns
    (uint8 rank, uint8 speed, uint8 stamina, uint8 sprintForce){
        Horses.Ability memory a = horseAbility(horseId);
        return (a.rank, a.speed, a.stamina, a.sprintForce);
    }

    function inqHorseBase(uint horseId) external view returns
    (uint8 avatar, uint8 DNA1, uint8 DNA2, bool gender){
        Horses.Base memory b = horseBase(horseId);
        return(b.avatar, b.DNA1, b.DNA2, b.gender);
    }

    function inqHorseRecord(uint horseId) external view returns
    (uint studFee, uint bloodlineA, uint bloodlineB, uint salePrice, bool isForSale){
        Horses.Record memory r = horseRecord(horseId);
        return(r.studFee, r.bloodlineA, r.bloodlineB, r.salePrice, r.isForSale);
    }

    function inqHorseStatus(uint horseId) external view returns
    (uint8 raceTimes, bool isRetire, uint8 breedingTimes, uint breedingCoolTime, uint exp){
        Horses.Status memory s = horseStatus(horseId);
        return(s.raceTimes, s.isRetire, s.breedingTimes, s.breedingCoolTime, s.exp);
    }

    function inqHorseHistory(uint horseId) external view returns
    (uint16 G1_Win, uint16 G2_Win, uint16 G3_Win, uint16 normal_Win, uint16 race_Lose){
        Horses.History memory h = horseHistory(horseId);
        return(h.G1_Win, h.G2_Win, h.G3_Win, h.normal_Win, h.race_Lose);
    }

    function exist(uint horseId) public view returns(bool){
        return ownerOf(horseId) != address(0);
    }

////////////////////////////only Race////////////////////////////////////

    function horseResult(uint horseId, uint8 typ, bool win) public onlyRace{

        Horses.Status memory hs = horseStatus(horseId);
        
        if(horseAbility(horseId).speed >= 70){
            if(hs.raceTimes > 2){
                hs.raceTimes = toUint8(uint(hs.raceTimes).sub(2));
            }else{
                hs.raceTimes = 0;
            }
        }else{
            if(hs.raceTimes > 1){
                hs.raceTimes = toUint8(uint(hs.raceTimes).sub(1));
            }else{
                hs.raceTimes = 0;
            }
        }//扣除RaceTimes

        horses[horseId].set_status(hs);

        Horses.History storage h = horses[horseId].history;

        if(win){
            horses[horseId].status.exp = horses[horseId].status.exp.add(100);
        }
        if(typ == 0){
            if(win){
                h.normal_Win = toUint16(uint(h.normal_Win).add(1));
            }else{
                h.race_Lose = toUint16(uint(h.race_Lose).add(1));
            }
        }else if(typ == 1){
            if(win){
                h.G1_Win = toUint16(uint(h.G1_Win).add(1));
            }
        }else if(typ == 2){
            if(win){
                h.G2_Win = toUint16(uint(h.G2_Win).add(1));
            }
        }else if(typ == 3){
            if(win){
                h.G3_Win = toUint16(uint(h.G3_Win).add(1));
            }
        }
    }


// ///////////////////////////other function///////////////////////////////

    function createHorse(uint mareId, uint stallionId) external onlyManager{
        _createHorse(mareId, stallionId);
    }

    function _generateHorse(Horses.Ability memory ability, Horses.Base memory base,
        Horses.Record memory record, Horses.Status memory status) private{

        _mint(msg.sender, createId);

        horses[createId].ability = ability;
        horses[createId].base = base;
        horses[createId].record = record;
        horses[createId].status = status;

        createId = createId.add(1);

    }

    function _createHorse(uint mareId, uint stallionId) private{

        uint N_DNA_Speed = ( _parent_speed(mareId).add(_parent_speed(stallionId)) )/2;

        uint N_DNA_Stamina = ( _parent_stamina(mareId).add(_parent_stamina(stallionId)) )/2;

        //一半機率來自公馬或母馬

        Horses.History memory h;
        if(rand(0, 99) > 49){
            h = horseHistory(mareId);
        }else{
            h = horseHistory(stallionId);
        }

        int _N_RDNA = int(h.G1_Win * 10 + h.G2_Win * 5 + h.G3_Win * 3 + h.normal_Win - h.race_Lose)/10;
        uint N_RDNA;
        if(_N_RDNA > 10){
            N_RDNA = 10;
        }else if(_N_RDNA < 0){
            N_RDNA = 0;
        }else{
            N_RDNA = uint(_N_RDNA);
        }

        uint8 raceTimes = uint8(rand(11, 100));  //最後也要依照生成的raceTimes值做能力修正
        uint8 breedingTimes;

        bool gender = rand(0, 9) > 4;

        if(gender){
            breedingTimes = uint8(rand(20, 100));
        }else{
            breedingTimes = uint8(rand(1, 10));
        }

        Horses.Ability memory a = Horses.Ability(
            0, //Rank
            toUint8(N_DNA_Speed.add(rand(0, N_RDNA))), //speed
            toUint8(N_DNA_Stamina.add(rand(0, N_RDNA))), //stamina
            toUint8(rand(N_RDNA, 10)) //sprintForce
            );

        Horses.Base memory b = Horses.Base(
            toUint8(rand(1, 20)), //avatar
            toUint8(rand(1, 10)), //DNA1
            toUint8(rand(1, 10)), //DNA2
            gender
            );

        Horses.Record memory r = Horses.Record(stallionId, mareId, 0, false, 0);
        Horses.Status memory s = Horses.Status(raceTimes, false, breedingTimes, 0, 0);

        _generateHorse(a, b, r, s);
    }

    function _parent_speed(uint horseId) private view returns(uint speed){
        
        uint speed_1 = (uint(10).sub(horseBase(horseId).DNA2))
            .mul(horseAbility(horseId).speed).div(10);

        uint speed_2 = rand(horseBase(horseId).DNA2, horseBase(horseId).DNA2 * 8);
        
        speed = speed_1.add(speed_2);
    }

    function _parent_stamina(uint horseId) private view returns(uint stamina){

        uint stamina_1 = uint(horseBase(horseId).DNA2)
        .mul(horseAbility(horseId).stamina).div(10);

        uint stamina_2 = rand(uint(10).sub(horseBase(horseId).DNA2),
            (uint(10).sub(horseBase(horseId).DNA2))*8);

        stamina = stamina_1.add(stamina_2);
    }

    function breeding(uint mareId, uint stallionId) public payable{
        require(ownerOf(mareId) == msg.sender, "You can't make they breed");
        require(horseBase(mareId).gender == false, "mareId is not female horse");
        require(horseBase(stallionId).gender == true, "stallionId is not male horse");

        Horses.Record memory r = horseRecord(stallionId);
        uint price = r.studFee*(1 trx);
        uint fee = 100 trx;
        require(msg.value == price.add(fee), "Value is not match");

        // require(ownerOf(mareId) != address(this) || ownerOf(mareId) != address(0),
        //     "owner of horse is not a player");

        require(horseStatus(mareId).isRetire &&
            horseStatus(stallionId).isRetire, "Not Both are retire");
        require(horseStatus(mareId).breedingTimes > 0 &&
            horseStatus(stallionId).breedingTimes > 0, "Not Both are breedable");
        require(horseStatus(mareId).breedingCoolTime <= now &&
            horseStatus(stallionId).breedingCoolTime <= now, "Not Both are cooled");

        _createHorse(mareId, stallionId);

        Horses.Status memory mare = horseStatus(mareId);
        mare.breedingTimes = toUint8(uint(mare.breedingTimes).sub(1));
        mare.breedingCoolTime = now.add(86400);
        horses[mareId].set_status(mare);

        Horses.Status memory stallion = horseStatus(stallionId);
        stallion.breedingTimes = toUint8(uint(stallion.breedingTimes).sub(1));
        stallion.breedingCoolTime = now.add(86400);
        horses[stallionId].set_status(stallion);
    }

    function buyHorse(uint horseId) public payable{
        address payable to = address(uint160(ownerOf(horseId)));
        Horses.Record memory r = horseRecord(horseId);

        uint price = r.salePrice*(1 trx);
        
        require(r.isForSale, "This horse is not for sale");

        require(msg.value == price, "Value is not match");
        require(horseId != 0, "You can't buy this horse");
        _transferFrom(address(this), msg.sender, horseId);

        r.isForSale = false;
        
        horses[horseId].set_record(r);
        if(to != address(this)){
            to.transfer(price);
        }
    }

    function setHorse(uint horseId, uint salePrice, uint studFee) external {
        Horses.Record memory r = horseRecord(horseId);

        if(msg.sender != manager){
            require(ownerOf(horseId) == msg.sender, "You are not owner of the horse");
        }

        if(salePrice == 0){
            r.isForSale = false;
        }else{
            r.isForSale = true;
        }
        r.salePrice = salePrice;
        r.studFee = studFee;
        horses[horseId].set_record(r);
    }

    function setRetire(uint horseId) external{

        if(msg.sender != manager){
            require(ownerOf(horseId) == msg.sender, "You are not owner of the horse");
        }

        Horses.Status memory s = horseStatus(horseId);
        s.isRetire = true;
        horses[horseId].set_status(s);
    }

    function training(uint horseId) external payable onlyHorseOwner(horseId){
        Horses.Status memory s = horseStatus(horseId);
        Horses.Ability memory a = horseAbility(horseId);

        uint ra = (uint(a.rank).add(1)).mul(100);

        require(s.exp >= ra, "Exp is not enough");
        s.exp = s.exp.sub(ra);

        require(msg.value == ra*(1 trx), "Value is not enough");

        horses[horseId].set_status(s);
        _levelup(horseId);
    }

    function _levelup(uint horseId) private{
        Horses.Ability memory a = horseAbility(horseId);

        if(a.rank < 50){
            uint r = rand(0, 2);
            a.rank = toUint8(uint(a.rank).add(1));

            if(r == 0){
                a.speed = toUint8(uint(a.speed).add(1));
            }else if(r == 1){
                a.stamina = toUint8(uint(a.stamina).add(1));
            }else if(r == 2){
                a.sprintForce = toUint8(uint(a.sprintForce).add(1));
            }else{
                revert("rand error");
            }

            horses[horseId].set_ability(a);
        }else{
            revert("Level of this horse is max");
        }
    }

}