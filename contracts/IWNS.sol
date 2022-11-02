// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;


interface iWNS{
    event ItemListed(
        address indexed seller,
        uint256 indexed tokenId,
        uint256 indexed price,
        uint256 amount
    );

    event ItemDelisted(
        address indexed caller,
        uint256 indexed tokenId
    );

    event ItemBought(
        address indexed buyer,
        uint256 indexed tokenId,
        uint256 indexed price,
        uint256 amount
    );

    event Revenue(
        address from,
        uint256 indexed amount,
        uint256 indexed id,
        uint256 indexed timestamp
    );

    event Claim(
        address to,
        uint256 indexed amount,
        uint256 indexed id,
        uint256 indexed timestamp
    );

    struct Meta {
        uint256 fee;
        uint256 revenue;
        address developer;
        uint256 totalSupply;
    }

    struct MarketOrder {
        uint256 amount;
        uint256 price;
    }

    function setDeveloper(address to, uint256 id) external;

    function pay(uint256 id, uint256 amount) external;

    function claimFunds(uint256[] memory ids) external;
}