pragma solidity ^0.5.8;

import "../contracts/Hello.sol";

contract TestHello{
  function test_say() public returns(string memory){
      return "Hello World.";
  }

  function test_sum(uint a, uint b) public returns(uint) {
      Hello hello = new Hello();
      return Hello.sum(a, b);
  }
}