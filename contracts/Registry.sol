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
    mapping(uint256 => bool) private STATE;
    mapping(uint256 => uint256) private TARIFF;
    mapping(uint256 => bytes32) private REGISTRY;

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

    function _authorizeUpgrade(
        address newImplementation
    ) internal override onlyRole(UPGRADER_ROLE) {}

    function _register(
        uint256 id,
        bytes32 pbk,
        uint256 tariff
    ) external onlyRole(REGISTRAR_ROLE) {
        REGISTRY[id] = pbk;
        TARIFF[id] = tariff;
        emit Register(id, tariff, pbk, block.timestamp, msg.sender);
    }

    function _switch(uint256 id, bool state) external onlyRole(W3BSTREAM_ROLE) {
        STATE[id] = state;
        emit Switch(block.timestamp, id, state, msg.sender);
    }

    function _tariff(
        uint256 id,
        uint256 tariff
    ) external onlyRole(REGISTRAR_ROLE) {
        TARIFF[id] = tariff;
        emit Register(id, tariff, REGISTRY[id], block.timestamp, msg.sender);
    }

    function identify(uint256 id) external view returns (bytes32) {
        return REGISTRY[id];
    }

    function stateOf(uint256 id) external view returns (bool) {
        return STATE[id];
    }

    function tariffOf(uint256 id) external view returns (uint256) {
        return TARIFF[id];
    }
}
