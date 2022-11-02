// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/token/ERC1155/ERC1155Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/extensions/ERC1155BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/extensions/ERC1155SupplyUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

import "./IWNS.sol";

uint8 constant currency = 0;

contract WNS is
    iWNS,
    Initializable,
    ERC1155Upgradeable,
    OwnableUpgradeable,
    ERC1155BurnableUpgradeable,
    ERC1155SupplyUpgradeable,
    UUPSUpgradeable
{
    // map id -> metadata
    mapping(uint256 => Meta) private _meta;
    mapping(address => uint256) private _fee;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function setDeveloper(address to, uint256 id) external onlyOwner {
        _meta[id].developer = to;
    }

    function developerOf(uint256 id) external view returns (address) {
        return _meta[id].developer;
    }

    function pay(uint256 id, uint256 amount) external {
        require(id != currency, "WNS: invalid token ID");

        _burn(msg.sender, currency, amount);
        emit Revenue(msg.sender, amount, id, block.timestamp);

        uint256 fee = (amount * 15) / 100;
        _meta[id].fee += fee;
        _meta[id].revenue += amount - fee;
    }

    function feeOf(uint256 id) external view returns (uint256) {
        return _meta[id].fee;
    }

    function revenueOf(uint256 id) external view returns (uint256) {
        return _meta[id].revenue;
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
        __Ownable_init();
        __ERC1155Burnable_init();
        __ERC1155Supply_init();
        __UUPSUpgradeable_init();
    }

    function setURI(string memory newuri) public onlyOwner {
        _setURI(newuri);
    }

    function mint(
        address account,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public onlyOwner {
        _mint(account, id, amount, data);
    }

    function mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public onlyOwner {
        _mintBatch(to, ids, amounts, data);
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        override
        onlyOwner
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
}
