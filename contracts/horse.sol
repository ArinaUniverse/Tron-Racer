pragma solidity >=0.5.1 <0.6.0;

import "./ERC721.sol";
import "./Manager.sol";

/*====================================================================================
                                Horse Contract
====================================================================================*/


contract horseContract is Manager, ERC721{

    using Address for address;
    uint createId;
    uint initAmount = 1000000;

    address _race;

    constructor() public{
        createId = initAmount.add(1);
        _ownedTokensCount[address(this)].setBalance(1000000);
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

    mapping (uint => horse) horses;

    struct horse{
        ability a;
        base b;
        record r;
        status s;
        history h;
        initial i;
    }

    struct initial{
        bool ability;
        bool base;
        bool record;
        bool status;
    }

    struct ability{
        uint8 rank; //等級,會隨場次增加
        uint8 speed; //速度
        uint8 stamina; //
        uint8 sprintForce; //
    }

    struct base{
        uint8 avatar; //馬外觀
        uint8 DNA1;
        uint8 DNA2;
        bool gender; //性別
    }

    struct record{
        uint StudFee; //公馬配種費用,玩家可以自行設定,0為不開放配種(預設),設定0以上費用,所有玩家都可以付費配種
        uint BloodlineA; //紀錄該馬的父馬編號(創世馬皆為0)
        uint BloodlineB; //紀錄該馬的母馬編號(創世馬皆為0)
        uint SalePrice;  //出售價格 生成時有一個初始值公式,也可以透過命令自行修改
        bool IsForSale;  //創世馬預設為True /true=可以直接購買 /false=不販售
    }

    struct status{
        uint8 RaceTimes; //可參與比賽次數,會隨每場比賽-1(initial:11~100)
        bool IsRetire; //是否退役，初始值為false，選擇退役後則為true，退役後才能配種
        uint8 BreedingTimes; //公馬/母馬可配種次數，歸零後便無法配種(initial:1~10)
        uint8 BreedingCoolTime; //配種冷卻時間，母馬配種後需24小時冷卻(公馬沒有冷卻時間)
    }

    struct history{
        uint16 G1_Win;  //初始值為0
        uint16 G2_Win;  //初始值為0
        uint16 G3_Win;  //初始值為0
        uint16 Normal_Win;  //初始值為0
        uint16 Race_Lose;  //初始值為0
    }

/////////////////////////////////_set////////////////////////////////////

    function _set_ability(horse storage h, ability memory a) internal{

        if(!h.i.ability){
            h.i.ability = true;
        }
        h.a = a;
    }

    function _set_base(horse storage h, base memory b) internal{

        if(!h.i.base){
            h.i.base = true;
        }
        h.b = b;
    }

    function _set_record(horse storage h, record memory r) internal{

        if(!h.i.record){
            h.i.record = true;
        }
        h.r = r;
    }

    function _set_status(horse storage h, status memory s) internal{
        if(!h.i.status){
            h.i.status = true;
        }
        h.s = s;
    }

    // function _set_history(horse storage h, history memory his) internal{
    //     if(!h.i.status){
    //         h.i.status = true;
    //     }
    //     h.h = his;
    // }

////////////////////////////////_init////////////////////////////////////

    function _init_horseBase(uint horseId) private pure returns(base memory){
        bytes32 seed = keccak256(abi.encodePacked(horseId, "horseBase"));
        uint8 avatar = range8(uint8(seed[1]), 1, 20);
        uint8 DNA1 = range8(uint8(seed[3]), 0, 10);
        uint8 DNA2 = range8(uint8(seed[5]), 0, 10);
        bool gender = range8(uint8(seed[7]), 0, 9) >= 5;

        return base(avatar, DNA1, DNA2, gender);
    }

    function _init_horseAbility(uint horseId) private pure returns(ability memory){
        bytes32 seed = keccak256(abi.encodePacked(horseId, "horseAbility"));

        uint8 _speed = range8(uint8(seed[2]), 50, 100);
        uint8 _stamina = range8(uint8(seed[4]), 20, 100);
        uint8 _sprintForce = range8(uint8(seed[6]), 0, 10);

        uint8 RaceTimes = _init_RaceTimes(horseId);

        if(11 <= RaceTimes || RaceTimes <= 20){
            _speed = _speed.add(9);
            _stamina = _stamina.add(9);
        }else if(21 <= RaceTimes || RaceTimes <= 30){
            _speed = _speed.add(8);
            _stamina = _stamina.add(8);
        }else if(31 <= RaceTimes || RaceTimes <= 40){
            _speed = _speed.add(7);
            _stamina = _stamina.add(7);
        }else if(41 <= RaceTimes || RaceTimes <= 50){
            _speed = _speed.add(6);
            _stamina = _stamina.add(6);
        }else if(51 <= RaceTimes || RaceTimes <= 60){
            _speed = _speed.add(5);
            _stamina = _stamina.add(5);
        }else if(61 <= RaceTimes || RaceTimes <= 70){
            _speed = _speed.add(4);
            _stamina = _stamina.add(4);
        }else if(71 <= RaceTimes || RaceTimes <= 80){
            _speed = _speed.add(3);
            _stamina = _stamina.add(3);
        }else if(81 <= RaceTimes || RaceTimes <= 90){
            _speed = _speed.add(2);
            _stamina = _stamina.add(2);
        }else if(91 <= RaceTimes || RaceTimes <= 100){
            _speed = _speed.add(1);
            _stamina = _stamina.add(1);
        }
        
        uint8 sum = _speed.add(_stamina).add(_sprintForce);
        uint8 rank = 0;

        if(_speed > 70){
            uint8 speed = uint8(linearTransfrom(sum, 110, uint(_speed)));
            uint8 stamina = uint8(linearTransfrom(sum, 110, uint(_stamina)));
            uint8 sprintForce = uint8(linearTransfrom(sum, 110, uint(_sprintForce)));
            return ability(rank, speed, stamina, sprintForce);
        }else if(sum > 120){
            uint8 speed = uint8(linearTransfrom(sum, 120, uint(_speed)));
            uint8 stamina = uint8(linearTransfrom(sum, 120, uint(_stamina)));
            uint8 sprintForce = uint8(linearTransfrom(sum, 120, uint(_sprintForce)));
            return ability(rank, speed, stamina, sprintForce);
        }
        else{
            return ability(rank, _speed, _stamina, _sprintForce);
        }
    }

    function _init_horseRecord(uint horseId) private view returns(record memory){
        uint SalePrice;
        ability memory a = _horseAbility(horseId);
        uint RateA = (uint(a.speed).mul(5)).add(uint(a.stamina).mul(2)).add(uint(a.sprintForce).mul(5)/10);
        bool isforsale = true;
        if(a.speed >= 80){
            SalePrice = RateA.mul(6);
            isforsale = false;
        }else if(a.speed >= 70 && a.speed < 80){
            SalePrice = RateA.mul(5);
        }else if(a.speed >= 60 && a.speed < 70){
            SalePrice = RateA.mul(4);
        }else if(a.speed >= 50 && a.speed < 60){
            SalePrice = RateA.mul(3);
        }else{
            SalePrice = RateA.mul(2);
        }
        return record(0, 0, 0, SalePrice, isforsale);
    }

    function _init_RaceTimes(uint horseId) private pure returns(uint8){
        bytes32 seed = keccak256(abi.encodePacked(horseId, "horseStatus"));
        return range8(uint8(seed[2]), 11, 100);
    }

    function _init_horseStatus(uint horseId) private view returns(status memory){
        uint8 BreedingTimes;
        if(_init_horseBase(horseId).gender){
            BreedingTimes = uint8(Random(20, 100));
        }else{
            BreedingTimes = uint8(Random(1, 10));
        }
        return status(_init_RaceTimes(horseId), false, BreedingTimes, 0);
    }
    
////////////////////////////////inquire//////////////////////////////////
    
    function _horseAbility(uint horseId) internal view returns(ability memory){
        require(_exist(horseId), "Horse is not exist");
        if(!horses[horseId].i.ability && horseId <= initAmount){
            return _init_horseAbility(horseId);
        }else{
            return horses[horseId].a;
        }
    }

    function _horseBase(uint horseId) internal view returns(base memory){
        require(_exist(horseId), "Horse is not exist");
        if(!horses[horseId].i.base && horseId <= initAmount){
            return _init_horseBase(horseId);
        }else{
            return horses[horseId].b;
        }
    }

    function _horseRecord(uint horseId) internal view returns(record memory){
        require(_exist(horseId), "Horse is not exist");
        if(!horses[horseId].i.record && horseId <= initAmount){
            return _init_horseRecord(horseId);
        }else{
            return horses[horseId].r;
        }
    }

    function _horseStatus(uint horseId) internal view returns(status memory){
        require(_exist(horseId), "Horse is not exist");
        if(!horses[horseId].i.status && horseId <= initAmount){
            return _init_horseStatus(horseId);
        }else{
            return horses[horseId].s;
        }
    }

    function _horseHistory(uint horseId) internal view returns(history memory){
        require(_exist(horseId), "Horse is not exist");
        return horses[horseId].h;
    }

    function inqHorseAbility(uint horseId) external view returns
    (uint8 rank, uint8 speed, uint8 stamina, uint8 sprintForce){
        ability memory a = _horseAbility(horseId);
        return (a.rank, a.speed, a.stamina, a.sprintForce);
    }

    function inqHorseBase(uint horseId) external view returns
    (uint8 avatar, uint8 DNA1, uint8 DNA2, bool gender){
        base memory b = _horseBase(horseId);
        return(b.avatar, b.DNA1, b.DNA2, b.gender);
    }

    function inqHorseRecord(uint horseId) external view returns
    (uint StudFee, uint BloodlineA, uint BloodlineB, uint SalePrice, bool IsForSale){
        record memory r = _horseRecord(horseId);
        return(r.StudFee, r.BloodlineA, r.BloodlineB, r.SalePrice, r.IsForSale);
    }

    function inqHorseStatus(uint horseId) external view returns
    (uint8 RaceTimes, bool IsRetire, uint8 BreedingTimes, uint8 BreedingCoolTime){
        status memory s = _horseStatus(horseId);
        return(s.RaceTimes, s.IsRetire, s.BreedingTimes, s.BreedingCoolTime);
    }

    function inqHorseHistory(uint horseId) external view returns
    (uint16 G1_Win, uint16 G2_Win, uint16 G3_Win, uint16 Normal_Win, uint16 Race_Lose){
        history memory h = _horseHistory(horseId);
        return(h.G1_Win, h.G2_Win, h.G3_Win, h.Normal_Win, h.Race_Lose);
    }

    function _exist(uint horseId) public view returns(bool){
        return createId >= horseId;
    }

////////////////////////////only Race////////////////////////////////////

    function horseResult(uint horseId, uint8 typ, bool win) public onlyRace{
        history storage h = horses[horseId].h;
        if(win){
            _levelup(horseId);
        }
        if(typ == 0){
            if(win){
                h.Normal_Win = h.Normal_Win.add(1);
            }else{
                h.Race_Lose = h.Race_Lose.add(1);
            }
        }else if(typ == 1){
            if(win){
                h.G1_Win = h.G1_Win.add(1);
            }
        }else if(typ == 2){
            if(win){
                h.G2_Win = h.G2_Win.add(1);
            }
        }else if(typ == 3){
            if(win){
                h.G3_Win = h.G3_Win.add(1);
            }
        }
    }

    function _levelup(uint horseId) private {
        //require(condition, message);
        ability memory a = _horseAbility(horseId);
        if(a.rank < 50){
            uint r = rand()%3;
            if(r == 0){
                _set_ability(horses[horseId], ability(
                    a.rank.add(1), a.speed.add(1), a.stamina, a.sprintForce));
            }else if(r == 1){
                _set_ability(horses[horseId], ability(
                    a.rank.add(1), a.speed, a.stamina.add(1), a.sprintForce));
            }else if(r == 2){
                _set_ability(horses[horseId], ability(
                    a.rank.add(1), a.speed, a.stamina, a.sprintForce.add(1)));
            }else{
                revert("rand error");
            }
        }
    }

///////////////////////////other function///////////////////////////////

    function createHorse(uint MareId, uint StallionId) external onlyManager{
        _CreateHorse(MareId, StallionId);
    }

    function _generateHorse(ability memory a, base memory b, record memory r, status memory s) private{

        _mint(msg.sender, createId);

        horses[createId].a = a;
        horses[createId].b = b;
        horses[createId].r = r;
        horses[createId].s = s;

        createId = createId.add(1);

    }

    function _CreateHorse(uint MareId, uint StallionId) private{

        uint8 N_DNA_Speed = uint8(_parent_speed(MareId)
            .add(_parent_speed(StallionId))).div(2);

        uint8 N_DNA_Stamina = uint8(_parent_stamina(MareId)
            .add(_parent_stamina(StallionId))).div(2);

        //一半機率來自公馬或母馬

        history memory h;
        if(rand()%100 >= 50){
            h = _horseHistory(MareId);
        }else{
            h = _horseHistory(StallionId);
        }

        int _N_RDNA = int(h.G1_Win * 10 + h.G2_Win * 5 + h.G3_Win * 3 + h.Normal_Win - h.Race_Lose)/10;
        uint N_RDNA;
        if(_N_RDNA > 10){
            N_RDNA = 10;
        }else if(_N_RDNA < 0){
            N_RDNA = 0;
        }else{
            N_RDNA = uint(_N_RDNA);
        }

        uint8 RaceTimes = uint8(Random(11, 100));  //最後也要依照生成的RaceTimes值做能力修正
        uint8 BreedingTimes;

        bool gender = Random(0, 9) > 4;

        if(gender){
            BreedingTimes = uint8(Random(20, 100));
        }else{
            BreedingTimes = uint8(Random(1, 10));
        }

        ability memory a = ability(
            0, //Rank
            uint8(N_DNA_Speed.add(uint8(Random(0, N_RDNA)))), //speed
            uint8(N_DNA_Stamina.add(uint8(Random(0, N_RDNA)))), //stamina
            uint8(Random(N_RDNA, 10)) //sprintForce
            );
            //check(N_DNA_Speed, N_DNA_Stamina);

        base memory b = base(
            uint8(Random(1, 20)), //avatar
            uint8(Random(1, 10)), //DNA1
            uint8(Random(1, 10)), //DNA2
            gender);

        record memory r = record(0, StallionId, MareId, 0, false);
        status memory s = status(RaceTimes, false, BreedingTimes, 0);

        _generateHorse(a, b, r, s);
    }

    function _parent_speed(uint horseId) private view returns(uint speed){ //為避免計算過程溢出,故用uint
        
        uint speed_1 = (uint(10).sub(_horseBase(horseId).DNA2))
            .mul(_horseAbility(horseId).speed).div(10);

        uint speed_2 = Random(_horseBase(horseId).DNA2, _horseBase(horseId).DNA2 * 8);
        
        speed = speed_1.add(speed_2);
    }

    function _parent_stamina(uint horseId) private view returns(uint stamina){ //為避免計算過程溢出,故用uint

        uint stamina_1 = uint(_horseBase(horseId).DNA2)
        .mul(_horseAbility(horseId).stamina).div(10);

        uint stamina_2 = Random(uint(10).sub(_horseBase(horseId).DNA2),
            (uint(10).sub(_horseBase(horseId).DNA2))*8);

        stamina = stamina_1.add(stamina_2);
    }

    function Breeding(uint MareId, uint StallionId) public{
        require(_horseBase(MareId).gender == false, "MareId is not female horse");
        require(_horseBase(StallionId).gender == true, "StallionId is not male horse");

        require(ownerOf(MareId) != address(this) || ownerOf(MareId) != address(0),
            "owner of horse is not a player");

        require(_horseStatus(MareId).IsRetire &&
            _horseStatus(StallionId).IsRetire, "Not Both are retire");
        require(_horseStatus(MareId).BreedingTimes > 0 &&
            _horseStatus(StallionId).BreedingTimes > 0, "Not Both are breedable");
        require(_horseStatus(MareId).BreedingCoolTime == 0 &&
            _horseStatus(StallionId).BreedingCoolTime == 0, "Not Both are cooled");

        _CreateHorse(MareId, StallionId);
        _set_status(horses[MareId], _horseStatus(MareId));
    }

    function BuyHorse(uint horseId) public payable{
        require(msg.value == _horseRecord(horseId).SalePrice*(10**6), "Value is not match");
        _transferFrom(address(this), msg.sender, horseId);
        record storage r = horses[horseId].r;
        r.IsForSale = false;
        r.SalePrice = _horseRecord(horseId).SalePrice.mul(3)/2;

    }

    function setSalePrice(uint horseId, uint SalePrice) external{
        require(ownerOf(horseId) == msg.sender, "You are not owner");
        record memory r = _horseRecord(horseId);
        r.SalePrice = SalePrice;
        _set_record(horses[horseId], r);
    }

    function setRetire(uint horseId) external{
        require(ownerOf(horseId) == msg.sender, "You are not owner");
        status memory s = _horseStatus(horseId);
        s.IsRetire = true;
        _set_status(horses[horseId], s);
    }

    function setForSale(uint horseId, bool isForSale) external{
        require(ownerOf(horseId) == msg.sender, "You are not owner");
        horses[horseId].r.IsForSale = isForSale;
    }
}