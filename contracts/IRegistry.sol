// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

interface iRegistry {
    event Register(
        uint256 indexed id,
        bytes32 indexed pkb,
        uint256 indexed tariff,
        address from,
        uint256 timestamp
    );

    event Switch(
        uint256 indexed timestamp,
        uint256 indexed id,
        bool indexed state,
        address from
    );

    function _register(uint256 id, bytes32 pbk, uint256 tariff) external;

    function _switch(uint256 id, bool state) external;

    function _tariff(uint256 id, uint256 tariff) external;

    function identify(uint256 id) external view returns (bytes32);

    function stateOf(uint256 meter_id) external view returns (bool);

    function tariffOf(uint256 id) external view returns (uint256);
}
