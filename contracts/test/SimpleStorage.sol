pragma solidity ^0.5.10;

//简单的存取合约，你的记录可以被别人存取，历史记录会永久记录在区块链上
contract SimpleStorage {
    uint storageData;

    function set(uint _data) public {
        storageData = _data;
    }

    function get() public view returns(uint){
        return storageData;
    }

}