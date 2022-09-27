pragma solidity ^0.8.0;

interface IPool {
    function flashLoan(
        uint256 borrowAmount,
        address borrower,
        address target,
        bytes calldata data
    ) external;
}

contract attackTruster {
    IPool pool;

    constructor(address _pool) {
        pool = IPool(_pool);
    }

    function attack() external {
        pool.flashLoan(0, address(this), address(this), "");
    }

    fallback() external payable {}

    receive() external payable {}
}
