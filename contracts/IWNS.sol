// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

interface iWNS {
    error NoRevenue();

    event Revenue(
        address from,
        uint256 indexed amount,
        uint256 indexed id,
        uint256 indexed timestamp
    );

    event Claim(
        address indexed to,
        uint256 indexed amount,
        uint256 indexed timestamp
    );

    function revenueOf(address owner) external view returns (uint256);

    function pay(uint256 id) external payable;

    function claim() external;
}
