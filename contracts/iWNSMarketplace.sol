// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

interface iMarketplace {
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

    struct MarketOrder {
        uint256 amount;
        uint256 price;
    }

    function updateListing(
        uint256 tokenId,
        uint256 amount,
        uint256 price
    ) external;

    function cancelListing(uint256 tokenId) external;

    function buyFromListing(uint256 tokenId, address seller, uint256 amount) external;

    function withdrawProceeds() external;

    function adminWithdrawal() external;

    function getListing(uint256 tokenId, address seller)
        external
        view
        returns (MarketOrder memory);

    function getProceeds() external view returns (uint256);
}
