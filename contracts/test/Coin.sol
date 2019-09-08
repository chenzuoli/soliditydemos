pragma solidity ^0.5.10;

contract Coin {
    // 创建一个能够外部合约访问的变量minter
    address public minter;
    mapping(address => uint) public balances;

    // 定义一个事件，该事件让轻客户端能够高效地对变化做出响应
    event Sent(address from, address to, uint amount);

    // 该构造函数只在创建该合约的时候调用一次
    constructor() public{
        minter = msg.sender;
    }

    // 挖矿，给矿工奖励
    function mint(address receiver, uint amount) public{
        if(msg.sender != receiver) {
            return;
        }
        balances[receiver] += amount;
    }

    // 转账，先检查发送者的余额是否足够
    function send(address receiver, uint amount) public{
        if (balances[msg.sender] < amount) return;
        balances[msg.sender] -= amount;
        balances[receiver] += amount;
        emit Sent(msg.sender, receiver, amount); // use "emit" key word to trigger event;
    }


}