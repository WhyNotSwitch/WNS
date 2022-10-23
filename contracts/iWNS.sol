// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;


interface iWNS{

    event Revenue(
        address from,
        uint256 indexed amount,
        uint256 indexed tokenId,
        uint256 indexed timestamp
    );

    event Claim(
        address to,
        uint256 indexed amount,
        uint256 indexed tokenId,
        uint256 indexed timestamp
    );

    function claimFee(uint256 tokenId) external;

    function claimRevenue(uint256 tokenId) external;

    function pay(uint256 tokenId, uint256 amount) external;

    function developerOf(uint256 tokenId) external view returns (address);
    
    function feeOf(uint256 tokenId) external view returns(uint256);

    function revenueOf(uint256 tokenId) external view returns(uint256);
}