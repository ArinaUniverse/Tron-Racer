pragma solidity >= 0.4.25;

library Sort{


    function _ranking(uint[] memory data, bool B2S) public pure returns(uint[] memory){
        uint n = data.length;
        uint[] memory value = data;
        uint[] memory rank = new uint[](n);

        for(uint i = 0; i < n; i++) rank[i] = i;

        for(uint i = 1; i < value.length; i++) {
            uint j;
            uint key = value[i];
            uint index = rank[i];

            for(j = i; j > 0 && value[j-1] > key; j--){
                value[j] = value[j-1];
                rank[j] = rank[j-1];
            }

            value[j] = key;
            rank[j] = index;
        }

        
        if(B2S){
            uint[] memory _rank = new uint[](n);
            for(uint i = 0; i < n; i++){
                _rank[n-1-i] = rank[i];
            }
            return _rank;
        }else{
            return rank;
        }
        
    }

    function ranking(uint[] memory data) internal pure returns(uint[] memory){
        //傳入array, 回傳index對應值的排名(由大到小)
        return _ranking(data, true);
    }

    function ranking_(uint[] memory data) internal pure returns(uint[] memory){
        //傳入array, 回傳index對應值的排名(由小到大)
        return _ranking(data, false);
    }

}

library MathTool{
    using SafeMath for uint256;

    function percent(uint _number, uint _percent) internal pure returns(uint){
        return _number.mul(_percent).div(100);
    }
}

library SafeMath {
    function add(uint a, uint b) internal pure returns (uint c) {
        c = a + b;
        require(c >= a, "add error");
    }
    function sub(uint a, uint b) internal pure returns (uint c) {
        require(b <= a, "sub error");
        c = a - b;
    }
    function mul(uint a, uint b) internal pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b, "mul error");
    }
    function div(uint a, uint b) internal pure returns (uint c) {
        require(b > 0, "div error");
        c = a / b;
    }
    function mod(uint a, uint b) internal pure returns (uint c) {
        require(b != 0, "mod error");
        c = a % b;
    }
}

library SafeMath8{
    function add(uint8 a, uint8 b) internal pure returns (uint8 c) {
        c = a + b;
        require(c >= a, "add error");
    }
    function sub(uint8 a, uint8 b) internal pure returns (uint8 c) {
        require(b <= a, "sub error");
        c = a - b;
    }
    function mul(uint8 a, uint8 b) internal pure returns (uint8 c) {
        c = a * b;
        require(a == 0 || c / a == b, "mul error");
    }
    function div(uint8 a, uint8 b) internal pure returns (uint8 c) {
        require(b > 0, "div error");
        c = a / b;
    }
    function mod(uint8 a, uint8 b) internal pure returns (uint8 c) {
        require(b != 0, "mod error");
        c = a % b;
    }
}

library SafeMath16 {
    function add(uint16 a, uint16 b) internal pure returns (uint16 c) {
        c = a + b;
        require(c >= a, "add error");
    }
    function sub(uint16 a, uint16 b) internal pure returns (uint16 c) {
        require(b <= a, "sub error");
        c = a - b;
    }
    function mul(uint16 a, uint16 b) internal pure returns (uint16 c) {
        c = a * b;
        require(a == 0 || c / a == b, "mul error");
    }
    function div(uint16 a, uint16 b) internal pure returns (uint16 c) {
        require(b > 0, "div error");
        c = a / b;
    }
    function mod(uint16 a, uint16 b) internal pure returns (uint16 c) {
        require(b != 0, "mod error");
        c = a % b;
    }
}

contract math {
    
    using MathTool for uint;
    using SafeMath for uint;
    using SafeMath16 for uint16;
    using SafeMath8 for uint8;

    function Random(uint lowerLimit, uint upperLimet) internal view returns(uint){
        return range(rand(), lowerLimit, upperLimet);
    }

    function range(uint seed, uint lowerLimit, uint upperLimet) internal pure returns(uint){
        require(upperLimet >= lowerLimit, "lowerLimit > upperLimet");
        if(upperLimet == lowerLimit){
            return upperLimet;
        }
        uint difference = upperLimet.sub(lowerLimit);
        return seed.mod(difference).add(lowerLimit).add(1);
    }

    function range8(uint8 seed, uint8 lowerLimit, uint8 upperLimet) internal pure returns(uint8){
        require(upperLimet >= lowerLimit, "lowerLimit > upperLimet");
        if(upperLimet == lowerLimit){
            return upperLimet;
        }
        uint8 difference = upperLimet.sub(lowerLimit);
        return seed.mod(difference).add(lowerLimit).add(1);
    }

    function range16(uint16 seed, uint16 lowerLimit, uint16 upperLimet) internal pure returns(uint16){
        require(upperLimet >= lowerLimit, "lowerLimit > upperLimet");
        if(upperLimet == lowerLimit){
            return upperLimet;
        }
        uint16 difference = upperLimet.sub(lowerLimit);
        return seed.mod(difference).add(lowerLimit).add(1);
    }

    function rand() internal view returns(uint){
        return uint(keccak256(abi.encodePacked(now, gasleft())));
    }

    function linearTransfrom(uint oringinMax, uint nowMax, uint number) public pure returns(uint){
        return number.mul(nowMax).div(oringinMax);
    }

    bytes _seed;

    constructor() public{
        setSeed();
    }

    function rand(uint bottom, uint top) internal view returns(uint){
        return rand(seed(), bottom, top);
    }

    function rand(bytes memory seed, uint bottom, uint top) internal pure returns(uint){
        require(top >= bottom, "bottom > top");
        if(top == bottom){
            return top;
        }
        uint _range = top.sub(bottom);

        uint n = uint(keccak256(seed));
        return n.mod(_range).add(bottom).add(1);
    }

    function setSeed() internal{
        _seed = abi.encodePacked(keccak256(abi.encodePacked(now, _seed, seed(), msg.sender)));
    }

    function seed() internal view returns(bytes memory){

        return abi.encodePacked((keccak256(abi.encodePacked(_seed, now, gasleft()))));
    }
}