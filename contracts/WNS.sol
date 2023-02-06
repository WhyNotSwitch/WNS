// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721URIStorageUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

import "./IWNS.sol";

contract WhyNotSwitch is
    iWNS,
    Initializable,
    ERC721Upgradeable,
    ERC721EnumerableUpgradeable,
    ERC721URIStorageUpgradeable,
    AccessControlUpgradeable,
    UUPSUpgradeable
{
    // map id -> metadata
    mapping(uint256 => bool) private _state;
    mapping(uint256 => uint256) private _tariff;
    mapping(address => uint256) private _revenue;

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");
    bytes32 public constant W3BSTREAM_ROLE = keccak256("W3BSTREAM_ROLE");

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function _switch(uint256 meter_id, bool state)
        external
        onlyRole(W3BSTREAM_ROLE)
    {
        emit Switch(block.timestamp, meter_id, state, msg.sender);
        _state[meter_id] = state;
    }

    function stateOf(uint256 meter_id) external view returns (bool) {
        return _state[meter_id];
    }

    function revenueOf(address owner) external view returns (uint256) {
        return _revenue[owner];
    }

    function pay(uint256 id) external payable {
        address owner = ownerOf(id);
        _revenue[owner] += msg.value;
        emit Revenue(msg.sender, msg.value, id, block.timestamp);
    }

    function claim() external {
        uint256 amount = _revenue[msg.sender];
        if (amount <= 0) {
            revert NoRevenue();
        }
        _revenue[msg.sender] = 0;
        (bool success, ) = payable(msg.sender).call{value: amount}("");
        require(success, "Transfer failed");
        emit Claim(msg.sender, amount, block.timestamp);
    }

    function initialize() public initializer {
        __ERC721_init("Why Not Switch", "WNS");
        __ERC721Enumerable_init();
        __ERC721URIStorage_init();
        __AccessControl_init();
        __UUPSUpgradeable_init();

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
        _grantRole(UPGRADER_ROLE, msg.sender);
    }

    function _baseURI() internal pure override returns (string memory) {
        return "https://nft.whynotswitch.com";
    }

    function safeMint(
        address to,
        uint256 id,
        string memory uri
    ) public onlyRole(MINTER_ROLE) {
        _safeMint(to, id);
        _setTokenURI(id, uri);
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        override
        onlyRole(UPGRADER_ROLE)
    {}

    // The following functions are overrides required by Solidity.

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    )
        internal
        virtual
        override(ERC721Upgradeable, ERC721EnumerableUpgradeable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function _beforeConsecutiveTokenTransfer(
        address from,
        address to,
        uint256, /*first*/
        uint96 size
    )
        internal
        virtual
        override(ERC721Upgradeable, ERC721EnumerableUpgradeable)
    {
        super._beforeTokenTransfer(from, to, size);
    }

    function _burn(uint256 id)
        internal
        override(ERC721Upgradeable, ERC721URIStorageUpgradeable)
    {
        super._burn(id);
    }

    function tokenURI(uint256 id)
        public
        view
        override(ERC721Upgradeable, ERC721URIStorageUpgradeable)
        returns (string memory)
    {
        return super.tokenURI(id);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(
            ERC721Upgradeable,
            ERC721EnumerableUpgradeable,
            AccessControlUpgradeable
        )
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
