// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/token/ERC1155/ERC1155Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/extensions/ERC1155BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/extensions/ERC1155SupplyUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

import "./IWNS.sol";

uint8 constant currency = 0;

contract _WNS is
    iWNS,
    Initializable,
    ERC1155Upgradeable,
    AccessControlUpgradeable,
    ERC1155BurnableUpgradeable,
    ERC1155SupplyUpgradeable,
    UUPSUpgradeable
{
    // map id -> metadata
    mapping(uint256 => Meta) _meta;
    mapping(address => uint256) _fee;

    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function setDeveloper(address to, uint256 id) external onlyRole(MANAGER_ROLE) {
        _meta[id].developer = to;
    }

    function pay(uint256 id, uint256 amount) external {
        require(id != currency, "WNS: invalid token ID");

        _burn(msg.sender, currency, amount);
        emit Revenue(msg.sender, amount, id, block.timestamp);

        uint256 fee = (amount * 15) / 100;
        _meta[id].fee += fee;
        _meta[id].revenue += amount - fee;
    }

    function claimFunds(uint256[] memory ids) external {
        uint256 _claim = _fee[msg.sender];
        if (_claim > 0) {
            _fee[msg.sender] = 0; // reset earnings to 0
        }

        // claim monopoly
        for (uint256 x = 0; x < ids.length; x++) {
            if (balanceOf(msg.sender, ids[x]) == totalSupply(ids[x])) {
                uint256 tokens = _meta[ids[x]].revenue;
                _claim += tokens;
                _meta[ids[x]].revenue = 0; // reset revenue to 0 for id[x]
                emit Claim(msg.sender, tokens, ids[x], block.timestamp);
            }
        }

        if (_claim > 0) {
            // mint calimed tokens
            _mint(msg.sender, currency, _claim, bytes("Minted on Claim"));
        }
    }

    function initialize() public initializer {
        __ERC1155_init("https://whynotswitch.com");
        __AccessControl_init();
        __ERC1155Burnable_init();
        __ERC1155Supply_init();
        __UUPSUpgradeable_init();

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MANAGER_ROLE, msg.sender);
    }

    function setURI(string memory newuri) public onlyRole(MANAGER_ROLE) {
        _setURI(newuri);
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
