pragma solidity ^0.5.8;
pragma experimental ABIEncoderV2;

contract Zombie {
    uint dnaDigits = 16;
    uint dnaMudulus = 10 ** dnaDigits;
    struct Zombie { // 结构体定义
        string name;
        uint dna;
    }
    Zombie[] public zombies; // 数组类型为结构体的数组

    event NewZombie(uint zombield, string name, uint dna);

    function createZombie(string memory _name, uint _dna) private { // 创建函数，将僵尸对象压入栈中
        // zombies.push(Zombie(_name, _dna));

        uint id = zombies.push(Zombie(_name, _dna)) -1;
        emit NewZombie(id, _name, _dna); // emit keyword to trigger the event.
    }

    function _generateRandomDNA(string memory _name) private view returns(uint) { // 生成随机数，生成僵尸DNA
        uint random = uint(keccak256(bytes(_name)));
        return random % dnaMudulus;
    }

    function createRandomZombie(string memory _name) public view returns(Zombie memory) {
        uint randomDNA = _generateRandomDNA(_name);
        return Zombie(_name, randomDNA);
    }


}