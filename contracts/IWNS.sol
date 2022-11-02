// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

interface iWNS {
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

    function setDeveloper(address to, uint256 id) external;

    function pay(uint256 id, uint256 amount) external;

    function revenueOf(uint256 id) external view returns (uint256);

    function claimFunds(uint256[] memory ids) external;
}
