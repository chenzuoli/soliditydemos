pragma solidity ^0.5.10;

// 委托投票
contract Ballot {

    // 用来表示一个选民
    struct Voter {
        uint weight; // 权重
        bool voted; // 是否已经投票
        address delegate; // 委托人
        uint vote; // 投票提案的索引
    }

    // 用来表示一个提案
    struct Proposal {
        bytes32 name; // 提案的简称（最长32个字节）
        uint vote_count; // 提案的得票数
    }

    // 用来表示投票人的地址
    address public chairman;

    // 声明一个状态变量，为每一个可能的地址存储一个Voter
    mapping(address => Voter) public voters;

    // 声明一组 议案， 一个Proposal结构类型的动态数组
    Proposal[] public proposals;


    // 初始化
    constructor (bytes32[] memory proposal_names) public {
        // 初始化投票人及权重
        chairman = msg.sender;
        voters[chairman].weight = 1;

        // 初始化议案：对于提供的每个议案的名称，创建一个新的Proposal对象，并把该对象放入数组的末尾
        for(uint i = 0; i < proposal_names.length; i++){
            // Proposal({......})  创建一个Proposal对象
            // proposals.push(Proposal({......})) 将一个Proposal对象放入数组proposals的末尾
            proposals.push(
                Proposal({
                    name: proposal_names[i],
                    vote_count: 0
                })
            );
        }
    }

    // 授权voter有投票的权利
    // 只有chairman有权利调用该函数
    function giveRightToVote(address voter) public {
        // 若require函数的第一个参数执行结果为false，则终止执行，撤销所有对状态和以太坊余额的改动
        // 在旧版的EVM中会消耗所有gas，但现在不会了
        // 使用require来检查函数是否被正确调用，是一个好习惯
        // 你也可以在函数的第二个参数中对错误进行解释
        require(
            msg.sender == chairman,
            "Only chairman can give the right to vote."
        );
        require(
            !voters[voter].voted == true,
            "The voter has already voted."
        );
        require(
            voters[voter].weight == 0,
            "The voter's weight is not zero."
        );
        voters[voter].weight = 1;
    }

    // 把你的投票权委托给 `to` 投票
    function delegate(address to) public {
        // 传递引用
        Voter storage sender = voters[msg.sender];
        require(
            !sender.voted == true,
            "You have already voted."
        );
        require(
            msg.sender != to,
            "Self-delegation is not allowed."
        );

        // 委托是可以传递的，只要被委托者 `to` 也设置了委托
        // 一般来说，这种循环委托是很危险的，因为如果委托链条太长，则有可能需消耗的gas要多于区块中剩余的（大于区块设置的gasLimit）
        // 这种情况下，委托不会被执行
        // 而在另一种情况下，如果形成闭环委托，则会让合约卡住
        address final_to = to;
        while(voters[to].delegate != address(0)){
            final_to = voters[to].delegate;

            // 不允许闭环委托
            require(
                final_to != msg.sender,
                "Found loop in delegation."
            );
        }

        // sender 是一个引用，相当于对voters[msg.sender].voted进行修改
        sender.voted = true;
        sender.delegate = final_to;

        // 被委托者
        Voter storage delegate_ = voters[final_to];
        if(delegate_.voted){
            // 如果被委托者已经投票，则在被委托者投给的那个提案的票数上加上委托者的投票权重
            proposals[delegate_.vote].vote_count += sender.weight;
        } else {
            // 如果被委托者没有投票，则在被委托者的投票权重上加上委托者的投票权重
            delegate_.weight += sender.weight;
        }
    }

    // 投票，包括被委托人的投票
    function vote(uint proposal_name) public {
        Voter storage sender = voters[msg.sender];
        // 如果你已经投过票，或者委托给其他人了，那么你没有权利再投票
        require(
            sender.voted != true,
            "You have already voted."
        );
        sender.voted = true;
        sender.vote = proposal_name;
        // 将投票的权重给到被投票人，如果议案索引超出了议案数组，则会自动抛出异常，对投票人和被投票人状态的修改会被回滚，投票失败。
        proposals[proposal_name].vote_count = sender.weight;
    }

    // 计算最终胜出的提案的索引
    function winning_proposal() public view returns(uint proposal_index) {
        uint winning_count = 0;
        for(uint i = 0; i < proposals.length; i++){
            if(proposals[i].vote_count > winning_count) {
                winning_count = proposals[i].vote_count;
                proposal_index = i;
            }
        }
    }

    // 取出议案数组中的议案名称
    function winning_proposal_name() public view returns(bytes32 proposal_name){
        return proposals[winning_proposal()].name;
    }


}