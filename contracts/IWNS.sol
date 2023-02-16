// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

interface iWNS {
    error NoRevenue();

    event Switch(
        uint256 indexed timestamp,
        uint256 indexed meter_id,
        bool indexed state,
        address from
    );

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

    function _switch(uint256 meter_id, bool state) external;

    function setTariffOf(uint256 id, uint256 tariff) external;

    function revenueOf(address owner) external view returns (uint256);

    function stateOf(uint256 meter_id) external view returns (bool);

    function tariffOf(uint256 id) external view returns (uint256);

    function pay(uint256 id) external payable;

    function claim() external;
}
