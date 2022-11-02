// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/token/ERC1155/ERC1155Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/extensions/ERC1155BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/extensions/ERC1155SupplyUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

import "./IWNS.sol";

uint8 constant currency = 0;

contract WNS is
    iWNS,
    Initializable,
    ERC1155Upgradeable,
    ERC1155BurnableUpgradeable,
    AccessControlUpgradeable,
    ERC1155SupplyUpgradeable,
    UUPSUpgradeable
{
    // map id -> metadata
    mapping(uint256 => uint256) private _revenue;
    mapping(uint256 => address) private _developer;
    mapping(address => uint256) private _fee;

    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function setDeveloper(address to, uint256 id) external onlyRole(MANAGER_ROLE) {
        _developer[id] = to;
    }

    function pay(uint256 id, uint256 amount) external {
        require(id != currency, "WNS: invalid token ID");

        _burn(msg.sender, currency, amount);
        emit Revenue(msg.sender, amount, id, block.timestamp);

        uint256 fee = (amount * 15) / 100;
        _fee[_developer[id]] += fee;
        _revenue[id] += amount - fee;
    }

    function revenueOf(uint256 id) external view returns (uint256) {
        return _revenue[id];
    }

    function claimFunds(uint256[] memory ids) external {
        uint256 _claim = _fee[msg.sender];
        if (_claim > 0) {
            _fee[msg.sender] = 0;
        }

        for (uint256 x = 0; x < ids.length; x++) {
            uint256 _id = ids[x];
            if (balanceOf(msg.sender, _id) == totalSupply(_id)) {
                uint256 tokens = _revenue[_id];
                emit Claim(msg.sender, tokens, _id, block.timestamp);

                _claim += tokens;
                _revenue[_id] = 0;
            }
        }

        if (_claim > 0) {
            _mint(msg.sender, currency, _claim, bytes("Minted on Claim"));
        }
    }

    function initialize() public initializer {
        __ERC1155_init("https://whynotswitch.com");
        __ERC1155Burnable_init();
        __AccessControl_init();
        __ERC1155Supply_init();
        __UUPSUpgradeable_init();

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MANAGER_ROLE, msg.sender);
    }

    function mint(
        address account,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public onlyRole(MANAGER_ROLE) {
        _mint(account, id, amount, data);
    }

    function mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public onlyRole(MANAGER_ROLE) {
        _mintBatch(to, ids, amounts, data);
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        override
        onlyRole(DEFAULT_ADMIN_ROLE)
    {}

    // The following functions are overrides required by Solidity.

    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal override(ERC1155Upgradeable, ERC1155SupplyUpgradeable) {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC1155Upgradeable, AccessControlUpgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
