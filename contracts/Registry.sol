// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

import "./IRegistry.sol";

contract Registry is
    iRegistry,
    Initializable,
    AccessControlUpgradeable,
    UUPSUpgradeable
{
    // map id -> metadata
    mapping(uint256 => bool) private _state;
    mapping(uint256 => address) private _registry;
    mapping(uint256 => uint256) private _tariff;

    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");
    bytes32 public constant REGISTRAR_ROLE = keccak256("REGISTRAR_ROLE");
    bytes32 public constant W3BSTREAM_ROLE = keccak256("W3BSTREAM_ROLE");

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize() public initializer {
        __AccessControl_init();
        __UUPSUpgradeable_init();

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(UPGRADER_ROLE, msg.sender);
        _grantRole(REGISTRAR_ROLE, msg.sender);
        _grantRole(W3BSTREAM_ROLE, msg.sender);
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        override
        onlyRole(UPGRADER_ROLE)
    {}

    function _switch(uint256 id, bool state) external onlyRole(W3BSTREAM_ROLE) {
        _state[id] = state;
    }

    function stateOf(uint256 id) external view returns (bool) {
        return _state[id];
    }

    function tariffOf(uint256 id) external view returns (uint256) {
        return _tariff[id];
    }

    function setTariffOf(uint256 id, uint256 tariff)
        external
        onlyRole(REGISTRAR_ROLE)
    {
        emit Tariff(block.timestamp, id, tariff, msg.sender);
        _tariff[id] = tariff;
    }

    function register(
        uint256 id,
        address xid,
        uint256 tariff
    ) external onlyRole(REGISTRAR_ROLE) {
        emit Register(block.timestamp, id, xid, msg.sender);
        _registry[id] = xid;
        _tariff[id] = tariff;
    }

    function identify(uint256 id) external view returns (address) {
        return _registry[id];
    }
}
