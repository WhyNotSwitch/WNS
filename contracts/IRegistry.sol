// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

interface iRegistry {
    error NoRevenue();

    event Register(
        uint256 indexed timestamp,
        uint256 indexed id,
        address indexed xid,
        address from
    );

    event Switch(
        uint256 indexed timestamp,
        uint256 indexed id,
        bool indexed state,
        address from
    );

    event Tariff(
        uint256 indexed timestamp,
        uint256 indexed id,
        uint256 indexed tariff,
        address from
    );

    function _switch(uint256 id, bool state) external;

    function setTariffOf(uint256 id, uint256 tariff) external;

    function stateOf(uint256 meter_id) external view returns (bool);

    function tariffOf(uint256 id) external view returns (uint256);

    function register(uint256 id, address xid, uint256 tariff) external;

    function identify(uint256 id) external view returns (address);
}
