pragma solidity ^0.5.10;



contract Purchase{
    uint public value;
    address payable public seller;
    address payable public buyer;
    enum State{Created, Locked, Inactive}
    State public state;

    // 确保 `msg.value` 是个偶数，如果是个奇数，会被截断，合约终止执行
    // 通过乘法来判断它是个偶数
    constructor() public payable {
        seller = msg.sender;
        value = msg.value / 2;
        require(
            (2*value) == msg.value,
            "msg.value is not a even."
        );
    }

    // 函数修改器，保证条件 `_condition` 正确，下划线 `_` 代表调用修改器的函数体
    modifier condition(bool _condition){
        require(
            _condition,
            "Not satisfy the condition."
        );
        _;
    }
    modifier onlySeller(){
        require(
            msg.sender == seller,
            "Only seller can call this function."
        );
        _;
    }
    modifier onlyBuyer(){
        require(
            msg.sender == buyer,
            "Only buyer can call this function."
        );
        _;
    }
    modifier inState(State _state){
        require(
            state == _state,
            "Invalid state."
        );
        _;
    }

    // 事件定义，等待emit，实现js与智能合约的交互
    // 放弃购买
    event Aborted();
    // 购买确认
    event PurchaseConfirmed();
    // 接收购买的合约
    event ItemReceived();

    /// 终止购买并回收以太币
    /// 只能在合约被锁定之前由卖家调用，这里使用函数修改器来实现条件的判断，其实也可以使用require函数来实现对应的功能
    function abort()
        public
        onlySeller
        inState(State.Created)
    {
        // 提交放弃购买的事件
        emit Aborted();
        // 修改购买合约动作的状态
        state = State.Inactive;
        // 回收购买使用的以太币
        seller.transfer(address(this).balance);
    }

    // 买家确认购买
    // 交易必须包含 `2*value` 个以太币
    // 以太币被锁定，直到 `confirmReceived` 函数被调用
    function confirmPurchase()
        public
        inState(State.Created)
        condition(msg.value == (2*value))
        payable
    {
        emit PurchaseConfirmed();
        buyer = msg.sender;
        state = State.Locked;
    }

    // 确认你已经收到商品
    // 调用这个函数会释放被锁定的以太币给卖家
    function confirmReceived()
        public
        onlyBuyer
        inState(State.Locked)
    {
        emit ItemReceived();
        /// 首先修改状态很重要，否则的话，由 `transfer` 所调用的合约可以回调进这里（这样会重复接收以太币）
        state = State.Inactive;

        // 注意：这实际上允许买方和卖方阻止退款，应该使用取回模式
        buyer.transfer(value);
        seller.transfer(address(this).balance);
    }


}