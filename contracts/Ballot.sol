pragma solidity >=0.4.22 <0.7.0;

// 委托投票
contract Ballot {
    // 这里声明了一个新的复合类型，用于稍后的变量
    // 它用来表示一个选民
    struct Voter {
        uint weight; // 权重，代表一个人投票的权重
        bool voted; // 这个人是否已经投过票
        address delegate; // 被委托人
        uint vote; // 投票提案的索引
    }

    // 这里声明提案类型，用来表示一个提案
    struct Proposal {
        bytes32 name; // 提案的简称
        uint votedCount; // 得票数
    }

    address public chairperson; // 合约调用者

    // 这里声明一个状态变量，为每一个可能的地址存储一个 `Voter`
    mapping(address => Voter) public voters;

    // 一个`Prososal`结构类型的动态数组
    Proposal[] public proposals;

    constructor(bytes32[] memory proposalNames) public {
        chairperson = msg.sender; // 作为提案的投票人，msg.sender是合约的调用者，每调用一次该合约，就将调用者的address作为投票人的地址
        voters[chairperson].weight = 1; // 每一位投票者投票的权重均为1

        // 对于提供的每一个提案名称，创建一个新的Proposal对象，并把它push到数组的末尾
        for(uint i = 0; i < proposalNames.length; i++) {
            // `Proposal({...})` 创建一个新的提案对象
            // `proposals.push(...)` 将其添加到proposals数组的末尾
            proposals.push(Proposal({
                name: proposalNames[i],
                votedCount: 0
            }));
        }
    }

    // 授权 `voter` 对这个投票（提案、表决）进行投票
    // 只有chairperson能够调用该函数，是通过require语句进行控制的
    function giveRightToVote(address voter) public {
        // 若 `reuqire` 函数的第一个条件返回 `false`，则终止执行，撤销所有对状态和以太币余额的改动。
        // 在旧版的EVM中，这会消耗所有的gas，但现在不会了
        // 使用 `require` 来检查函数是否被正确地调用，是一个好习惯
        // 你也可以在 `require` 函数的第二个参数中提供一个对错误情况的解释
        require(
            msg.sender == chairperson,
            "Only chairperson can give right to vote."
        );
        // 检查voter是否已经投过票
        require(
            !voters[voter].voted,
            "This voter is already voted."
        );
        // 检查voter投票的权重是否为0
        require(
            voters[voter].weight == 0,
            "This voter's vote weight is zero."
        );
        voters[voter].weight = 1;
    }

    // 将投票权委托给 `to` 用户
    function delegate(address to) public {
        address tempTo = to;
        // 传递引用
        Voter storage sender = voters[msg.sender];
        // 如果自己已经投过票，就不能委托给他人了
        require(
            !sender.voted,
            "You have voted."
        );
        // 设置 委托自己投票 不被允许
        require(
            tempTo != msg.sender,
            "Self-delegated is disallowed."
        );

        // 委托是可以传递的，只要被委托者 `to` 也设置了委托才行
        // 一般来说，这种循环委托是危险的，因为如果传递的链条太长，则可能需要消耗的gas要多于区块中所剩余的（大于区块设置的gasLimit）
        // 这种情况下，委托将不会被执行
        // 而在另一些情况下，如果形成闭环，则会让合约完全卡住
        while(voters[tempTo].delegate != address(0)){ // 判断被委托人是否也进行了委托
            tempTo = voters[tempTo].delegate; // 获取委托人的委托人，此时将msg.sender的委托人设置为了委托人的委托人
            require(
                tempTo != msg.sender,
                "Found loop in delegation." // 不允许闭环互相委托
            );
        }

        // `sender` 是一个引用，相当于对 voters[msg.sender].voted进行修改
        sender.voted = true;
        sender.delegate = tempTo;
        Voter storage delegate_ = voters[tempTo];
        if(delegate_.voted) {
            // 若委托人已经投过票了，则直接增加提案的得票数
            proposals[delegate_.vote].votedCount += sender.weight;
        } else {
            // 若委托人还未投票，则增加委托人的投票权重
            delegate_.weight += sender.weight;
        }
    }

    /// 把你的票（包括委托给你的票），投给提案 `proposals[proposal].name`
    function vote(uint proposal) public {
        Voter storage sender = voters[msg.sender];
        require(
            sender.voted,
            "Already voted."
        );
        sender.voted = true;
        sender.vote = proposal;
        // 如果 `proposal` 超过了 `proposals` 数组的长度，则表示投票人投票的提案不存在，合约自动抛出异常，并恢复所有改动
        proposals[proposal].votedCount += sender.weight;
    }

    // @dev 结合之前的所有投票，计算出最终胜出的提案
    function winningProposal() public view returns (uint proposalIndex) {
        uint winningVoteCount = 0;
        for (uint p = 0; p < proposals.length; p++) {
            if(proposals[p].votedCount > winningVoteCount) {
                winningVoteCount = proposals[p].votedCount;
                proposalIndex = p;
            }
        }
    }

    // 调用 winningProposal() 获取提案数组中获胜提案的索引，返回获胜提案的名称
    function winnerName() public view returns (bytes32 proposalName) {
        proposalName = proposals[winningProposal()].name;
    }

}