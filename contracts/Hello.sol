pragma solidity ^0.5.8;

contract Hello {
    string say_something;

    function say() pure public returns(string memory) {
        return "Hello World";
    }

    function sum(uint a, uint b) pure public returns(uint val) {
        val = a + b;
        return val;
    }
}