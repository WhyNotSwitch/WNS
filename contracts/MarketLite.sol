// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

// import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";

import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/utils/ERC1155HolderUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

contract MarketLite is
    Initializable,
    PausableUpgradeable,
    AccessControlUpgradeable,
    UUPSUpgradeable,
    ERC1155HolderUpgradeable,
    ReentrancyGuardUpgradeable
{
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");
    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");
    mapping(address => uint256) private proceeds;

    uint256 public listingFee = 1 ether;
    address public _nftAddress;
    IERC1155 private nftContract;
    
    // using Counters for Counters.Counter;
    // Counters.Counter private _orderIds;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address nftAddress) public initializer {
        __Pausable_init();
        __AccessControl_init();
        __UUPSUpgradeable_init();
        __ERC1155Holder_init();
        __ReentrancyGuard_init();

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(PAUSER_ROLE, msg.sender);
        _grantRole(MANAGER_ROLE, msg.sender);
        _grantRole(UPGRADER_ROLE, msg.sender);

        setNftContract(nftAddress);
    }

    //  Custom code:

    function _withdrawProceeds(address account) private {
        uint256 coins = proceeds[account];
        require(coins > 0, "No proceeds available");
        proceeds[account] = 0;
        nftContract.safeTransferFrom(address(this), msg.sender, 0, coins, "");
    }

    function withdrawProceeds() external {
        _withdrawProceeds(msg.sender);
    }

    function adminWithdrawal() external onlyRole(DEFAULT_ADMIN_ROLE) {
        _withdrawProceeds(address(this));
    }

    function getProceeds() external view returns (uint256) {
        return proceeds[msg.sender];
    }

    function setListingFee(uint fee) external onlyRole(MANAGER_ROLE) {
        listingFee = fee;
    }

    function setNftContract(address nftAddress)
        public
        onlyRole(MANAGER_ROLE)
    {
        require(nftAddress != address(0), "Can't be set to the zero address");
        _nftAddress = nftAddress;
        nftContract = IERC1155(_nftAddress);
    }



    // Wizard code.
    // Starts here

    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        override
        onlyRole(UPGRADER_ROLE)
    {}

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC1155ReceiverUpgradeable, AccessControlUpgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
