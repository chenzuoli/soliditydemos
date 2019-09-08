pragma solidity ^0.5.10;

import "../util/Console.sol";

contract Example is Console {

    uint myUnsignedNumber = 100; // 这个无符号整数将会永久保存到区块链上，无法修改。

    struct Person { // 结构体
        uint age;
        string name;
    }

    Person[] public people; // 公共类型的Person数组，合约默认为public类型变量提供getter方法

    Person satoshi = Person(172, "Satoshi"); // 创建一个新的person

    function eatHamburger(string memory _name, uint _num) private pure returns(string memory) {
        // string memory rtn = _name.toSlice().concat(_num.toSlice);
        return _name;
    }
    // eatHamburger("vitalik", 100);

    uint[] numbers;
    function _addToArray(uint number) private { // 定义私有函数，默认为公共函数，其他合约也可以访问你的方法，所以比较危险，最好设置为私有
        numbers.push(number);
    }

    string greeting = "what's up dude?";
    function sayHello(string memory words) public pure returns(string memory){ // 函数设置返回值 returns
        return words;
    }

}
