pragma solidity ^0.5.10;

// 公开拍卖
contract SimpleAuction {
    // 拍卖的参数
    address payable public beneficiary;

    // 时间是unix系统的绝对时间戳（自1970-01-01依赖的秒数）
    // 或以秒为单位的时间段
    uint public auctionEnd;


    // 当前合约拍卖的状态
    address public highestBidder;
    uint public highestBid;

    // 可以取出之前的出价
    mapping(address => uint) pendingReturns;

    // 拍卖结束后，设置为true，禁止所有状态的改动
    bool ended;


    // 变更触发的事件
    event HighestBidIncreased(address bidder, uint amount);
    event AuctionEnd(address winner, uint amount);


    // 以下是所谓的 `natspec` 注释，可以通过三个斜杠来识别；
    // 当用户被要求确认交易时显示

    /// 以受益者 `_beneficiary` 的名义，
    /// 创建一个简单的拍卖，拍卖时间为 `_biddingTime`
    constructor(
        uint _biddingTime,
        address payable _beneficiary
    ) public {
        beneficiary = _beneficiary;
        auctionEnd = block.timestamp + _biddingTime;
    }

    /// 对拍卖进行出价，具体的出价随交易一起发送
    /// 如果没有在拍卖中胜出，则返还出价
    function bid() public payable {
        /// 参数是不必要的，因为所有的信息已经包含在了交易中
        /// 对于能接受以太币的函数，关键字 `payable` 是必需的

        // 如果拍卖已结束，则撤销函数的调用
        require(
            now <= auctionEnd,
            "The auction is already ended."
        );
        
        // 如果出价不够高，函数返回
        require(
            msg.value > highestBid,
            "There is already a higher bid."
        );

        if(highestBid != 0) {
            // 返回出价时，简单地调用 `highestBidder.send(highestBid)` 是有安全风险的，因为他有可能执行一个非信任合约
            // 更为安全的做法是让接收方自己去提取金钱
            pendingReturns[highestBidder] += highestBid;
        }

        highestBidder = msg.sender;
        highestBid = msg.value;
        emit HighestBidIncreased(msg.sender, msg.value);
    }

    // 取回出价
    function withdraw() public returns(bool) {
        uint amount = pendingReturns[msg.sender];
        if(amount > 0) {
            // 这里很重要：首先要设置0值
            // 因为，作为接收调用的一部分，接受者可以在 `send` 返回之前，重新调用
            pendingReturns[msg.sender] = 0;

            // 如果支付失败，则重置为未付款
            if(!msg.sender.send(amount)){
                pendingReturns[msg.sender] = amount;
                return false;
            }
        }
        return true;
    }

    // 结束拍卖，并把最高的出价发送给受益人
    function end() public {
        // 对于可与其他合约交互的函数（意味着它会调用其他合约函数或者发送以太币），一个好的指导方针是将其结构分为三个阶段：
        // 1.检查条件；
        // 2.执行动作(可能会改变条件)；
        // 3.与其他合约交互
        // 如果这些阶段相混合，其他的合约可能回调这些函数并修改状态，或者导致某些效果（支付以太币）多次生效
        // 如果合约内的函数调用了外部合约的函数，则说明这个合约也是交互的

        // 1.check
        require(
            now >= auctionEnd,
            "Auction is not end."
        );
        require(
            !ended,
            "AuctionEnd has already been called."
        );

        // 2.action
        ended = true;
        emit AuctionEnd(highestBidder, highestBid);

        // 3.interaction
        beneficiary.transfer(highestBid);
    }

}