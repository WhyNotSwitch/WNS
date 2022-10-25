// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

interface iMarketplace {
    struct MarketOrder {
        uint256 tokenId;
        uint256 amount;
        uint256 price;
        address payable seller;
    }

    event ItemListed(
        address indexed seller,
        uint256 indexed tokenId,
        uint256 indexed price,
        uint256 amount
    );

    event ItemDelisted(
        address indexed caller,
        uint256 indexed tokenId,
        uint256 amount
    );

    event ItemBought(
        address indexed buyer,
        uint256 indexed tokenId,
        uint256 indexed price,
        uint256 amount
    );

    function openOrder(
        uint256 tokenId,
        uint256 amount,
        uint256 price
    ) external;

    function updateOrder(
        uint256 orderId,
        uint256 tokenId,
        uint256 amount,
        uint256 price
    ) external;

    function cancelOrder(uint256 orderId) external;

    function fillOrder(uint256 orderId, uint256 amount) external;

    function withdrawProceeds() external;

    function adminWithdrawal() external;

    function getOrder(uint256 orderId)
        external
        view
        returns (MarketOrder memory);

    function getProceeds() external view returns (uint256);
}
